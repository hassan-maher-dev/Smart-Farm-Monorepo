from flask import Flask, request, jsonify
from flask_cors import CORS  # 
from database import SessionLocal, PlantData, DeviceStatus



app = Flask(__name__)
CORS(app)

# ===================================================
# ========= PREVENT BROWSER CACHING =================
# ===================================================
@app.after_request
def add_cache_control(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

# ===================================================
# ================= INIT DEVICES ====================
# ===================================================

def init_devices(user_id):

    db = SessionLocal()

    try:

        for device_id in ['water_pump', 'grow_lights']:

            exists = (
                db.query(DeviceStatus)
                .filter_by(
                    id=device_id,
                    user_id=user_id
                )
                .first()
            )

            if not exists:

                db.add(
                    DeviceStatus(
                        id=device_id,
                        user_id=user_id,
                        is_on=False,
                        mode="auto"
                    )
                )

        db.commit()

    finally:

        db.close()

# ===================================================
# ================= RECEIVE IOT DATA ================
# ===================================================

@app.route('/api/data', methods=['POST'])
def receive_iot_data():

    data = request.get_json()

    user_id = data.get(
        'user_id',
        'default_user'
    )

    init_devices(user_id)

    db = SessionLocal()

    try:

        # ================================================
        # ================ SAVE SENSOR DATA ==============
        # ================================================

        new_reading = PlantData(

            user_id=user_id,

            temperature=data.get(
                'temperature',
                0.0
            ),

            humidity=data.get(
                'humidity',
                0.0
            ),

            soil_moisture=data.get(
                'soil_moisture',
                0.0
            ),

            light_intensity=data.get(
                'light_intensity',
                0.0
            ),

            water_level=data.get(
                'water_level',
                0.0
            ),

            air_quality=data.get(
                'air_quality',
                0.0
            ),

            soil_ph=data.get(
                'soil_ph',
                0.0
            ),

            soil_ec=data.get(
                'soil_ec',
                0.0
            ),

            uv_index=data.get(
                'uv_index',
                0.0
            ),
        )

        db.add(new_reading)

        # ================================================
        # ================= DEVICES ======================
        # ================================================

        pump = (
            db.query(DeviceStatus)
            .filter_by(
                id='water_pump',
                user_id=user_id
            )
            .first()
        )

        lights = (
            db.query(DeviceStatus)
            .filter_by(
                id='grow_lights',
                user_id=user_id
            )
            .first()
        )

        soil_moisture = (
            new_reading.soil_moisture
        )

        light_intensity = (
            new_reading.light_intensity
        )

        # ================================================
        # ================= PUMP AUTO ====================
        # ================================================

        if pump.mode == "auto":

            if (
                soil_moisture < 30
                and not pump.is_on
            ):

                pump.is_on = True

            elif (
                soil_moisture >= 60
                and pump.is_on
            ):

                pump.is_on = False

        # ================================================
        # ================= LIGHTS AUTO ==================
        # ================================================

        if lights.mode == "auto":

            if (
                light_intensity == 0
                and not lights.is_on
            ):

                lights.is_on = True

            elif (
                light_intensity >= 100
                and lights.is_on
            ):

                lights.is_on = False

        db.commit()

        # ================================================
        # ================= ESP RESPONSE =================
        # ================================================

        return jsonify({

            "status": "success",

            "commands": {

                "water_pump":
                    pump.is_on,

                "grow_lights":
                    lights.is_on,
            }

        }), 201

    except Exception as e:

        db.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        db.close()

# ===================================================
# ================= GET LATEST DATA =================
# ===================================================

@app.route(
    '/api/latest-data/<user_id>',
    methods=['GET']
)
def get_latest_data(user_id):

    db = SessionLocal()

    try:

        latest = (

            db.query(PlantData)

            .filter_by(user_id=user_id)

            .order_by(
                PlantData.timestamp.desc()
            )

            .first()
        )

        if not latest:

            return jsonify({}), 200

        return jsonify({

            "temperature":
                latest.temperature,

            "humidity":
                latest.humidity,

            "soil_moisture":
                latest.soil_moisture,

            "light_intensity":
                latest.light_intensity,

            "water_level":
                latest.water_level,

            "air_quality":
                latest.air_quality,

            "soil_ph":
                latest.soil_ph,

            "soil_ec":
                latest.soil_ec,

            "uv_index":
                latest.uv_index,

            "timestamp":
                latest.timestamp.isoformat(),
        })

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        db.close()

# ===================================================
# ================= GET HISTORY =====================
# ===================================================

@app.route(
    '/api/history/<user_id>',
    methods=['GET']
)
def get_history(user_id):

    db = SessionLocal()

    try:

        history = (

            db.query(PlantData)

            .filter_by(user_id=user_id)

            .order_by(
                PlantData.timestamp.desc()
            )

            .limit(100)

            .all()
        )

        return jsonify([

            {

                "temperature":
                    item.temperature,

                "humidity":
                    item.humidity,

                "soil_moisture":
                    item.soil_moisture,

                "light_intensity":
                    item.light_intensity,

                "water_level":
                    item.water_level,

                "air_quality":
                    item.air_quality,

                "soil_ph":
                    item.soil_ph,

                "soil_ec":
                    item.soil_ec,

                "uv_index":
                    item.uv_index,

                "timestamp":
                    item.timestamp.isoformat(),
            }

            for item in history
        ])

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        db.close()

# ===================================================
# ================= CONTROL DEVICE ==================
# ===================================================

@app.route('/api/control', methods=['POST'])
def control_device():

    data = request.get_json()

    user_id = data.get('user_id')

    device_id = data.get('device_id')

    db = SessionLocal()

    try:

        device = (

            db.query(DeviceStatus)

            .filter_by(
                id=device_id,
                user_id=user_id
            )

            .first()
        )

        if not device:

            return jsonify({
                "error": "Device not found"
            }), 404

        # ================================================
        # ================= UPDATE STATE =================
        # ================================================

        if 'is_on' in data:

            device.is_on = data['is_on']

        if 'mode' in data:

            device.mode = data['mode']

        db.commit()

        return jsonify({

            "status": "success",

            "device": {

                "id": device.id,

                "is_on": device.is_on,

                "mode": device.mode,
            }

        })

    except Exception as e:

        db.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        db.close()

# ===================================================
# ================= GET DEVICES =====================
# ===================================================

@app.route(
    '/api/devices/<user_id>',
    methods=['GET']
)
def get_devices(user_id):

    db = SessionLocal()

    try:

        devices = (

            db.query(DeviceStatus)

            .filter_by(user_id=user_id)

            .all()
        )

        return jsonify([

            {

                "id": d.id,

                "is_on": d.is_on,

                "mode": d.mode,
            }

            for d in devices
        ])

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        db.close()

# ===================================================
# ================= HEALTH CHECK ====================
# ===================================================

@app.route('/health', methods=['GET'])
def health():

    return jsonify({
        "status": "healthy"
    }), 200

# ===================================================
# ================= MAIN ============================
# ===================================================
# ===================================================
# ================= LOGIN (MOCK) ====================
# ===================================================

@app.route('/api/login', methods=['POST'])
def login():
    # إحنا هنا بنعمل (Mock) يعني بنقبل أي إيميل وباسورد
    # وبنرد بـ user_id ثابت عشان التطبيق يفتح معاك فوراً
    
    data = request.get_json() or {}
    
    return jsonify({
        "status": "success",
        "user_id": "17b7dec9-b349-4a51-bf03-edb57fbf7793",
        "message": "Login successful"
    }), 200

if __name__ == '__main__':

    app.run(
        host='0.0.0.0',
        port=5002,
        debug=True
    )