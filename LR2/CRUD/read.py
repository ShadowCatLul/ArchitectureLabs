from sqlalchemy.orm import Session
from app.database import User
from app.schema import UserSchema
import datetime

def get_user(db: Session, skip: int = 0, limit: int = 100):
    return db.query(User).offset(skip).limit(limit).all() #все юзеры

def get_user_by_id(db: Session, user_id: int): #по id
    return db.query(User).filter(User.id == user_id)

# def get_user_by_first_name(db: Session, first_name: str):
#     return db.query(User).filter(User.first_name == first_name)

# def get_user_by_last_name(db: Session, last_name: str):
#     return db.query(User).filter(User.last_name == last_name)

# def get_user_by_date_joined(db: Session, date_joined: datetime.datetime.date):
#     return db.query(User).filter(User.date_joined == date_joined)


# def get_user_by_login(db: Session, login: str):
#     return db.query(User).filter(User.login == login)

# def get_user_by_email(db: Session, email: str):
#     return db.query(User).filter(User.email == email)
