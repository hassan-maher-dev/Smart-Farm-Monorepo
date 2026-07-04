import os
import jwt
import bcrypt
from datetime import datetime, timedelta
from functools import wraps
from flask import Flask, request, jsonify, g
from database import SessionLocal, User, PlantData, DeviceStatus

app = Flask(__name__)

# مفتاح التشفير الخاص بالـ JWT (يفضل وضعه في متغيرات البيئة لاحقاً)
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "SuperSecretSmartFarmTokenKey2026!")

# ===================================================
# ============= DECORATOR: TOKEN REQUIRED ===========
# ===================================================
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # التحقق من وجود التوكن داخل الـ Authorization Header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith("Bearer "):
                token = auth_header.split(" ")[1]
        
        if not token:
            return jsonify({"status": "error", "message": "Token is missing! Access denied."}), 401
        
        try:
            # فك تشفير التوكن والتحقق من صلاحيته
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            # حفظ بيانات المستخدم في سياق الطلب الحالي (Flask Global Context)
            g.user_id = data["user_id"]
            g.email = data["email"]
        except jwt.ExpiredSignatureError:
            return jsonify({"status": "error", "message": "Token has expired. Please login again."}), 401
        except jwt.InvalidTokenError:
            return jsonify({"status": "error", "message": "Invalid token. Authentication failed."}), 401
            
        return f(*args, **kwargs)
    return decorated

# ===================================================
# ============= AUTH ENDPOINTS (NEW) ================
# ===================================================

@app.route('/api/register', methods=['POST'])
def register():
    """إنشاء حساب جديد لمزرعة جديدة"""
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"status": "error", "message": "Missing email or password"}), 400
        
    email = data.get('email').strip().lower()
    password = data.get('password')
    farm_name = data.get('farm_name', 'My Green Farm').strip()
    
    db = SessionLocal()
    try:
        # التأكد من عدم تكرار الحساب
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            return jsonify({"status": "error", "message": "Email already registered"}), 400
            
        # تشفير كلمة المرور بشكل صارم قبل الحفظ
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # إنشاء المستخدم الجديد
        new_user = User(email=email, password_hash=hashed_password, farm_name=farm_name)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        # تهيئة الأجهزة الافتراضية للمزرعة الجديدة مباشرة منعاً لحدوث Conflict أو أخطاء استدعاء
        default_pump = DeviceStatus(id="water_pump", user_id=new_user.id, is_on=False, mode="auto")
        default_light = DeviceStatus(id="lighting", user_id=new_user.id, is_on=False, mode="auto")
        db.add_all([default_pump, default_light])
        db.commit()
        
        return jsonify({
            "status": "success",
            "message": "User and Farm registered successfully",
            "user": {"id": new_user.id, "email": new_user.email, "farm_name": new_user.farm_name}
        }), 201
    except Exception as e:
        db.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        db.close()


@app.route('/api/login', methods=['POST'])
def login():
    """تسجيل الدخول والتحقق وتوليد الـ JWT Token"""
    data = request.get_json()
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({"status": "error", "message": "Missing email or password"}), 400
        
    email = data.get('email').strip().lower()
    password = data.get('password')
    
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        
        # مقارنة الباسورد المدخل مع الـ Hash المشفر في قاعدة البيانات
        if not user or not bcrypt.checkpw(password.encode('utf-8'), user.password_hash.encode('utf-8')):
            return jsonify({"status": "error", "message": "Invalid email or password"}), 401
            
        # توليد توكن JWT ينتهي بعد 24 ساعة
        token = jwt.encode({
            "user_id": user.id,
            "email": user.email,
            "exp": datetime.utcnow() + timedelta(hours=24)
        }, SECRET_KEY, algorithm="HS256")
        
        return jsonify({
            "status": "success",
            "token": token,
            "user": {
                "id": user.id,
                "email": user.email,
                "farm_name": user.farm_name
            }
        }), 200
    finally:
        db.close()

# ===================================================
# ============= IOT TELEMETRY & CONTROL =============
# ===================================================

@app.route('/api/data', methods=['POST'])
@token_required
def receive_data():
    """استقبال قراءات الحساسات وحفظها للمستخدم الحالي فقط"""
    data = request.get_json()
    if not data:
        return jsonify({"status": "error", "message": "No data provided"}), 400
        
    db = SessionLocal()
    try:
        # يتم أخذ الـ user_id تلقائياً من التوكن لحماية البيانات
        plant_entry = PlantData(
            user_id=g.user_id,
            temperature=data.get('temperature'),
            humidity=data.get('humidity'),
            soil_moisture=data.get('soil_moisture'),
            light_intensity=data.get('light_intensity'),
            water_level=data.get('water_level'),
            air_quality=data.get('air_quality'),
            soil_ph=data.get('soil_ph'),
            soil_ec=data.get('soil_ec'),
            uv_index=data.get('uv_index')
        )
        db.add(plant_entry)
        db.commit()
        return jsonify({"status": "success", "message": "Telemetry data saved successfully"}), 201
    except Exception as e:
        db.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        db.close()


@app.route('/api/latest-data', methods=['GET'])
@token_required
def get_latest_data():
    """جلب آخر قراءة حساسات خاصة بمزرعة المستخدم الحالي"""
    db = SessionLocal()
    try:
        latest = db.query(PlantData).filter(PlantData.user_id == g.user_id).order_by(PlantData.timestamp.desc()).first()
        if not latest:
            return jsonify({"status": "success", "data": None, "message": "No telemetry data found for this farm"}), 200
            
        return jsonify({
            "status": "success",
            "data": {
                "temperature": latest.temperature,
                "humidity": latest.humidity,
                "soil_moisture": latest.soil_moisture,
                "light_intensity": latest.light_intensity,
                "water_level": latest.water_level,
                "air_quality": latest.air_quality,
                "soil_ph": latest.soil_ph,
                "soil_ec": latest.soil_ec,
                "uv_index": latest.uv_index,
                "timestamp": latest.timestamp.isoformat()
            }
        }), 200
    finally:
        db.close()


@app.route('/api/history', methods=['GET'])
@token_required
def get_history():
    """جلب السجل التاريخي لقراءات مزرعة المستخدم الحالي"""
    db = SessionLocal()
    try:
        history_records = db.query(PlantData).filter(PlantData.user_id == g.user_id).order_by(PlantData.timestamp.desc()).limit(50).all()
        data_list = []
        for r in history_records:
            data_list.append({
                "temperature": r.temperature,
                "humidity": r.humidity,
                "soil_moisture": r.soil_moisture,
                "light_intensity": r.light_intensity,
                "water_level": r.water_level,
                "air_quality": r.air_quality,
                "soil_ph": r.soil_ph,
                "soil_ec": r.soil_ec,
                "uv_index": r.uv_index,
                "timestamp": r.timestamp.isoformat()
            })
        return jsonify({"status": "success", "data": data_list}), 200
    finally:
        db.close()


@app.route('/api/devices', methods=['GET'])
@token_required
def get_devices():
    """جلب حالة أجهزة المزرعة التابعة للمستخدم الحالي فقط"""
    db = SessionLocal()
    try:
        devices = db.query(DeviceStatus).filter(DeviceStatus.user_id == g.user_id).all()
        devices_dict = {d.id: {"is_on": d.is_on, "mode": d.mode} for d in devices}
        
        return jsonify({"status": "success", "devices": devices_dict}), 200
    finally:
        db.close()


@app.route('/api/devices/control', methods=['POST'])
@token_required
def control_device():
    """التحكم في تشغيل/إيقاف أو وضع الأجهزة الخاصة بالمستخدم الحالي"""
    data = request.get_json()
    if not data or not data.get('device_id'):
        return jsonify({"status": "error", "message": "Missing device_id"}), 400
        
    device_id = data.get('device_id')
    is_on = data.get('is_on')
    mode = data.get('mode')
    
    db = SessionLocal()
    try:
        # البحث عن الجهاز بشرط تطابق الـ device_id والـ user_id معاً (Composite Key)
        device = db.query(DeviceStatus).filter(
            DeviceStatus.id == device_id, 
            DeviceStatus.user_id == g.user_id
        ).first()
        
        if not device:
            return jsonify({"status": "error", "message": "Device not found for this user"}), 404
            
        if is_on is not None:
            device.is_on = is_on
        if mode is not None:
            device.mode = mode
            
        db.commit()
        return jsonify({
            "status": "success", 
            "message": f"Device {device_id} updated successfully",
            "device": {"id": device.id, "is_on": device.is_on, "mode": device.mode}
        }), 200
    except Exception as e:
        db.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        db.close()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)