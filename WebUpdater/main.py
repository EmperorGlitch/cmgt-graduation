from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form, Body
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import os
from uuid import uuid4
from typing import List

from . import dbcontroller, dbmodels, dbschemas
from .dbconnection import SessionLocal, engine, Base

Base.metadata.create_all(bind=engine)

app = FastAPI()

UPLOAD_DIR = "videos"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/videos", StaticFiles(directory=UPLOAD_DIR), name="videos")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/version/{platform}", response_model=dbschemas.AppVersionOut)
def get_version(platform: str, db: Session = Depends(get_db)):
    version = dbcontroller.get_latest_version(db, platform)
    if not version:
        raise HTTPException(status_code=404, detail="Version not found")
    return version

@app.post("/version", response_model=dbschemas.AppVersionOut)
def create_version(version: dbschemas.AppVersionCreate, db: Session = Depends(get_db)):
    return dbcontroller.create_version(db, version)

@app.post("/videos/upload", response_model=dbschemas.VideoOut)
def upload_video(
    name: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    ext = os.path.splitext(file.filename)[1]
    filename = f"{uuid4().hex}{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    os.makedirs(UPLOAD_DIR, exist_ok=True)

    with open(filepath, "wb") as f:
        f.write(file.file.read())

    file_url = f"/videos/{filename}"
    return dbcontroller.create_video(db, name, file_url)

@app.post("/videos/find", response_model=List[dbschemas.VideoOut])
def resolve_video_names(names: List[str] = Body(...), db: Session = Depends(get_db)):
    found = dbcontroller.get_videos_by_names(db, names)
    if len(found) != len(names):
        missing = set(names) - set(v.name for v in found)
        raise HTTPException(status_code=404, detail=f"Missing: {list(missing)}")
    return found

@app.delete("/videos/remove/{video_name}", response_model=dbschemas.VideoOut)
def remove_video_by_name(video_name: str, db: Session = Depends(get_db)):
    video = dbcontroller.get_video_by_name(db, video_name)
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")

    filepath = os.path.join(UPLOAD_DIR, os.path.basename(video.file_url))

    if os.path.exists(filepath):
        try:
            os.remove(filepath)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error deleting file: {str(e)}")

    dbcontroller.delete_video(db, video)
    return video