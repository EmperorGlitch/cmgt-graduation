from sqlalchemy import Column, Integer, String
from .dbconnection import Base

class AppVersion(Base):
    __tablename__ = "app_versions"
    id = Column(Integer, primary_key=True, index=True)
    platform = Column(String, index=True)
    version = Column(String)
    file_url = Column(String)

class Video(Base):
    __tablename__ = "videos"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    file_url = Column(String)