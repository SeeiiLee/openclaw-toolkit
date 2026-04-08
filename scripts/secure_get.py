#!/usr/bin/env python3
"""
Secure credential retrieval script
"""
import json
import sys
from pathlib import Path
from cryptography.fernet import Fernet

SECURE_DIR = Path(__file__).parent.parent / "secure"
KEY_FILE = SECURE_DIR / "key.txt"
SECRETS_FILE = SECURE_DIR / "secrets.encrypted.json"

def load_key():
    """Load encryption key from file"""
    with open(KEY_FILE, 'r') as f:
        return f.read().strip()

def decrypt_data(encrypted_data, key):
    """Decrypt data using Fernet"""
    f = Fernet(key)
    return f.decrypt(encrypted_data.encode()).decode()

def load_secrets():
    """Load and decrypt secrets"""
    key = load_key()
    with open(SECRETS_FILE, 'r') as f:
        encrypted_data = f.read()
    decrypted = decrypt_data(encrypted_data, key)
    return json.loads(decrypted)

def main():
    if len(sys.argv) < 2:
        print("Usage: python secure_get.py <key_name> | --list | --file")
        sys.exit(1)
    
    arg = sys.argv[1]
    secrets = load_secrets()
    
    if arg == "--list":
        for key in sorted(secrets.keys()):
            print(key)
    elif arg == "--file":
        print(json.dumps(secrets, indent=2, ensure_ascii=False))
    else:
        if arg in secrets:
            print(secrets[arg])
        else:
            print(f"Key '{arg}' not found", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
