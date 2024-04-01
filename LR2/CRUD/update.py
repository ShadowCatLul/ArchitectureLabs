from sqlalchemy.orm import Session
from app.database import User
from app.schema import UserSchema
from CRUD.read import get_user_by_id
import hashlib


def update_user(db: Session, user_id: int,
                 first_name: str, second_name: str,
                   password: str, login: str,
                   email: str, is_active: bool,
                   is_superuser: bool, is_verified: bool):
    _user = get_user_by_id(db=db, user_id=user_id)

    _user.first_name = first_name
    _user.second_name = second_name
    _user.hashed_password = password
    _user.login = login
    _user.email = email
    _user.is_active = is_active
    _user.is_superuser = is_superuser
    _user.is_verified = is_verified
    
    db.commit()
    db.refresh(_user)
    return _user