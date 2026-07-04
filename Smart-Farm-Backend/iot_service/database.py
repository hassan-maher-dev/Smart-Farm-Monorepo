import os
import uuid
from sqlalchemy import create_engine, Column, Integer, Float, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Connection format: postgresql://username:password@host:port/dbname
DB_URL = os.getenv("DATABASE_URL", "postgresql://farmnetadmin:SuperSecretPassword123!@localhost:5432/farmnetdb")

# أوامر حماية الاتصال (Timeout & Ping)
engine = create_engine(
    DB_URL,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 10}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ===================================================
# ================= NEW: USER TABLE =================
# ===================================================
class User(Base):
    __tablename__ = "users"
    # استخدام UUID كمعرف فريد لكل مستخدم
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    farm_name = Column(String, default="My Green Farm")
    created_at = Column(DateTime, default=datetime.utcnow)

# ===================================================
# ================= PLANT DATA TABLE ================
# ===================================================
class PlantData(Base):
    __tablename__ = "plant_data"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    temperature = Column(Float)
    humidity = Column(Float)
    soil_moisture = Column(Float)
    light_intensity = Column(Float)
    water_level = Column(Float)
    air_quality = Column(Float)
    soil_ph = Column(Float)
    soil_ec = Column(Float)
    uv_index = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

# ===================================================
# ================= DEVICES TABLE ===================
# ===================================================
class DeviceStatus(Base):
    __tablename__ = "devices"
    # التعديل هنا: جعلنا الـ id والـ user_id معاً هما الـ Primary Key (Composite Key)
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, primary_key=True, index=True)
    is_on = Column(Boolean, default=False)
    mode = Column(String, default="auto") 

# إنشاء الجداول في قاعدة البيانات
Base.metadata.create_all(bind=engine)