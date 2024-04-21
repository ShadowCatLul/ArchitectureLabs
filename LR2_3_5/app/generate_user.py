from faker import Faker

from app.schema import UserSchema


def generate_user_db(count: int):
    fake = Faker()

    users = []

    for _ in range(count):
        user = {
            'first_name' : fake.first_name(),
            'last_name': fake.last_name(),
            'date_joined': fake.date_this_decade(),
            'hashed_password' : fake.password(),
            'login' : fake.profile().get('username'),
            'email' : fake.ascii_free_email(),
            'is_active': fake.boolean(),
            'is_superuser': fake.boolean(),
            'is_verified': fake.boolean()
        }
        users.append(UserSchema(**user))

    return users