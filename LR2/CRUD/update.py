from sqlalchemy.orm import Session
from app.database import User
from app.schema import UserSchema
from CRUD.read import get_user_by_id
import hashlib


def update_user(db: Session, user_id: int, first_name: str, second_name: str, password: str, login: str):
    _user = get_user_by_id(db=db, user_id=user_id)

    _user.first_name = first_name
    _user.second_name = second_name
    _user.password = password
    _user.login = login
    hashed_password: str

    db.commit()
    db.refresh(_user)
    return _user