# hardcoded_credentials_example.py

# Hardcoded username and password (security vulnerability)
USERNAME = "admin"
PASSWORD = "admin123"

def authenticate(user, pwd):
    if user == USERNAME and pwd == PASSWORD:
        return "Authentication successful"
    else:
        return "Authentication failed"

# Simple test of authentication function
print(authenticate("admin", "admin123"))  # Should return "Authentication successful"
print(authenticate("user", "pass"))       # Should return "Authentication failed"

