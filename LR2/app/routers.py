
from fastapi import APIRouter, Depends, HTTPException, Header
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from app.schema import UserSchema
from typing import List, Annotated
import CRUD
from CRUD import create, read, update, delete
from app.database import engine, SessionLocal, Base, User
from sqlalchemy.orm import Session
from fastapi import Depends, Request
from typing import Optional
import jwt
import hashlib
from datetime import timedelta, datetime


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

db_dependency = Annotated[Session, Depends(get_db)]

router = APIRouter()

def check_user_token(auth: str = Header(...)):
    print(f'auth: {auth}')
    print(f'test split: {auth.split(".")}')
    payload = jwt.decode(auth, "Well_Done", algorithms=["HS256"])
    user_id: str = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=402, detail="Invalid authentication credentials")

    return user_id


@router.post("/login")
async def login(creds: HTTPBasicCredentials = Depends(HTTPBasic()), db: Session = Depends(get_db)):
    _user = read.get_user_by_login(db, creds.username)


    if _user is None:
        raise HTTPException(status_code=401, detail="user not found")

    if _user.login != creds.username:
        raise HTTPException(status_code=401, detail="wrong login")

    hashed_password = hashlib.sha256(creds.password.encode()).hexdigest()
    
    if hashed_password != _user.hashed_password:
        raise HTTPException(status_code=401, detail="wrong password")

    exp_date = datetime.now() + timedelta(minutes=15)

    token_data = {"sub": _user.id, "exp": exp_date}
    token = jwt.encode(token_data, "Well_Done", algorithm="HS256")
    return {"access_token": token, "token_type": "bearer"}



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

@router.get("/get_by_last_name")
async def get_by_last_name(request: str, db: Session = Depends(get_db)):

    _user = read.get_user_by_last_name(db, last_name=request)

    return {
        "message"    : f"user '{_user.last_name}' found in postgres",
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
                      new_password: str, new_login: str, new_email: str, new_status_is_active: bool,
                      new_status_is_superuser: bool, new_status_is_verified: bool, db: Session = Depends(get_db)):

    _user = update.update_user(db, user_id=user_id, first_name=new_first_name, second_name=new_second_name,
                             password=new_password, login=new_login,email=new_email,is_active=new_status_is_active,
                             is_superuser=new_status_is_superuser, is_verified=new_status_is_verified)
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


