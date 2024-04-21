from pydantic import BaseModel
from typing import Optional
import datetime
from sqlalchemy import TIMESTAMP


class UserSchema(BaseModel):
    first_name: Optional[str]
    last_name: Optional[str]
    date_joined: Optional[datetime.datetime]
    login: Optional[str]
    hashed_password: Optional[str]
    email: Optional[str]
    is_active: Optional[bool]
    is_superuser: Optional[bool]
    is_verified: Optional[bool]

    
