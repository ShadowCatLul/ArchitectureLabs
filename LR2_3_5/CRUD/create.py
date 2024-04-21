from sqlalchemy.orm import Session
from app.database import User
from app.schema import UserSchema
import hashlib

def add_new_user(db: Session, user: UserSchema):
    hashed_password = hashlib.sha256(user.hashed_password.encode()).hexdigest()
    _new_user = User(first_name=user.first_name,
                last_name=user.last_name,
                date_joined=user.date_joined,
                login=user.login,
                hashed_password=hashed_password,
                email=user.email,
                is_active=user.is_active,
                is_superuser=user.is_superuser,
                is_verified=user.is_verified
                )
    db.add(_new_user)
    db.commit()
    db.refresh(_new_user)
    return _new_user
