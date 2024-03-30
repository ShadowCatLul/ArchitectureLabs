
from fastapi import Depends
from fastapi import APIRouter
from app.schema import UserSchema
from typing import List, Annotated
import CRUD
from CRUD import create, read, update, delete
from app.database import engine, SessionLocal, Base, User
from sqlalchemy.orm import Session
from fastapi import Depends, Request
from typing import Optional

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]

router = APIRouter()

@router.post("/add")
async def create_user(request: UserSchema, db: Session = Depends(get_db)):
    create.add_new_user(db, user=request)

    return {
        "message"    : f"user {request.login} successfully added",
        "user"       : request,
        "status_code": "200"
    }

@router.get("/get_by_first_name")
async def get_user_by_first_name(request: str, db: Session = Depends(get_db)):
    key = f'get_by_first_name: {request}'
    _user = read.get_user_by_first_name(db, first_name=request)


    return {
        "message"    : f"user '{_user.first_name}' found in postgres",
        "user"       : _user,
        "status_code": "200"
    }

@router.get("/get_by_second_name")
async def get_by_second_name(request: str, db: Session = Depends(get_db)):

    _user = read.get_user_by_second_name(db, second_name=request)

    return {
        "message"    : f"user '{_user.second_name}' found in postgres",
        "user"       : _user,
        "status_code": "200"
    }


@router.get("/get_all")
async def get_all(start: int, end: int, db: Session = Depends(get_db)):

    _users = read.get_user(db, skip=start, limit=end)

    return {
        "message"    : f"users found",
        "users"      : _users,
        "status_code": "200"
    }


@router.get("/get_user_by_id")
async def get_all(user_id: int, db: Session = Depends(get_db)):
    _user = read.get_user_by_id(db, user_id)

    return _user


@router.patch("/update")
async def update_user(user_id: int, new_first_name: str, new_second_name: str,
                      new_password: str, new_login: str, db: Session = Depends(get_db),):

    _user = update.update_user(db, user_id=user_id, first_name=new_first_name, second_name=new_second_name,
                             password=new_password, login=new_login)
    return {
        "message"    : f"user {user_id} update",
        "users"      : _user,
        "status_code": "200"
    }


@router.delete("/delete")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    _user = delete.remove_user(db, user_id=user_id)

    return {
        "message"    : f"user {user_id} removed",
        "status_code": "200"
    }


