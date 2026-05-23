import os
from sqlalchemy import create_engine, Column, Integer, Float, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime

# Connection format: postgresql://username:password@host:port/dbname
DB_URL = os.getenv("DATABASE_URL", "postgresql://farmnetadmin:SuperSecretPassword123!@localhost:5432/farmnetdb")

# التعديل هنا: إضافة أوامر حماية الاتصال (Timeout & Ping)
engine = create_engine(
    DB_URL,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 10}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

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

class DeviceStatus(Base):
    __tablename__ = "devices"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, index=True)
    is_on = Column(Boolean, default=False)
    mode = Column(String, default="auto") 

Base.metadata.create_all(bind=engine)