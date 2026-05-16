from flask import Flask, request, jsonify
from database import SessionLocal, PlantData, DeviceStatus

app = Flask(__name__)

# Initialize default devices if they don't exist
def init_devices(user_id):
    db = SessionLocal()
    for device_id in ['water_pump', 'grow_lights']:
        if not db.query(DeviceStatus).filter_by(id=device_id, user_id=user_id).first():
            db.add(DeviceStatus(id=device_id, user_id=user_id, is_on=False, mode="auto"))
    db.commit()
    db.close()

@app.route('/api/data', methods=['POST'])
def receive_iot_data():
    data = request.get_json()
    user_id = data.get('user_id', 'default_user')
    
    init_devices(user_id)
    db = SessionLocal()
    
    try:
        # 1. Save Sensor Data
        new_reading = PlantData(
            user_id=user_id,
            temperature=data.get('temperature', 0.0),
            humidity=data.get('humidity', 0.0),
            soil_moisture=data.get('soil_moisture', 0.0),
            light_intensity=data.get('light_intensity', 0.0),
            water_level=data.get('water_level', 0.0),
            air_quality=data.get('air_quality', 0.0),
            soil_ph=data.get('soil_ph', 0.0),
            soil_ec=data.get('soil_ec', 0.0),
            uv_index=data.get('uv_index', 0.0)
        )
        db.add(new_reading)
        
        # 2. Automation Logic
        pump = db.query(DeviceStatus).filter_by(id='water_pump', user_id=user_id).first()
        lights = db.query(DeviceStatus).filter_by(id='grow_lights', user_id=user_id).first()
        
        soil_moisture = new_reading.soil_moisture
        light_intensity = new_reading.light_intensity
        
        # Pump Automation
        if pump.mode == "auto":
            if soil_moisture < 30 and not pump.is_on:
                pump.is_on = True
            elif soil_moisture >= 60 and pump.is_on:
                pump.is_on = False
                
        # Lights Automation
        if lights.mode == "auto":
            if light_intensity == 0 and not lights.is_on:
                lights.is_on = True
            elif light_intensity >= 100 and lights.is_on:
                lights.is_on = False

        db.commit()
        
        # 3. Return Actionable Response for ESP32
        return jsonify({
            "status": "success",
            "commands": {
                "water_pump": pump.is_on,
                "grow_lights": lights.is_on
            }
        }), 201
        
    except Exception as e:
        db.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        db.close()

@app.route('/api/devices/<user_id>', methods=['GET'])
def get_devices(user_id):
    db = SessionLocal()
    devices = db.query(DeviceStatus).filter_by(user_id=user_id).all()
    db.close()
    return jsonify({d.id: {"is_on": d.is_on, "mode": d.mode} for d in devices})

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)