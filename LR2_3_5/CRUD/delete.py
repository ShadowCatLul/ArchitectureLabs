from sqlalchemy.orm import Session
from app.database import User
from app.schema import UserSchema
from CRUD.read import get_user_by_id

def remove_user(db: Session, user_id: int):
    _user = get_user_by_id(db=db, user_id=user_id)
    db.delete(_user)
    db.commit()
