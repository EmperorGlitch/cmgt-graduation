from sqlalchemy.orm import Session
from . import dbmodels, dbschemas

def get_latest_version(db: Session, platform: str):
    return db.query(dbmodels.AppVersion)\
             .filter_by(platform=platform)\
             .order_by(dbmodels.AppVersion.id.desc())\
             .first()

def create_version(db: Session, version: dbschemas.AppVersionCreate):
    db_version = dbmodels.AppVersion(**version.model_dump())
    db.add(db_version)
    db.commit()
    db.refresh(db_version)
    return db_version

def create_video(db: Session, name: str, file_url: str):
    video = dbmodels.Video(name=name, file_url=file_url)
    db.add(video)
    db.commit()
    db.refresh(video)
    return video

def get_video_by_name(db: Session, name: str):
    return db.query(dbmodels.Video).filter(dbmodels.Video.name == name).first()

def get_videos_by_names(db: Session, names: list[str]):
    return db.query(dbmodels.Video).filter(dbmodels.Video.name.in_(names)).all()

def delete_video(db: Session, video: dbmodels.Video):
    db.delete(video)
    db.commit()