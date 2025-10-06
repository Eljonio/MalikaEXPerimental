#!/usr/bin/env python3
import sys
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

if len(sys.argv) < 2:
    print("Usage: ./generate_password_hash.py <password>")
    sys.exit(1)

password = sys.argv[1]
hashed = pwd_context.hash(password)
print(f"Password: {password}")
print(f"Hash: {hashed}")
