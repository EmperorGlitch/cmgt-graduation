from pydantic import BaseModel

class AppVersionBase(BaseModel):
    platform: str
    version: str

class AppVersionCreate(AppVersionBase):
    file_url: str
    
class AppVersionOut(AppVersionBase):
    id: int
    file_url: str

    class Config:
        from_attributes = True

class VideoCreate(BaseModel):
    name: str

class VideoOut(BaseModel):
    id: int
    name: str
    file_url: str

    class Config:
        from_attributes = True