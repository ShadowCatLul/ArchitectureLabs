from typing import Union, List, Annotated
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from app.routers import router
from app.database import engine, Base
import uvicorn
from loguru import logger
from app.database import User


Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Users",
    description="users database",
    docs_url="/"
)

app.include_router(router, prefix='/user', tags=["user"])


