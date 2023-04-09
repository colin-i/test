
# necessary imports
import secrets
import string

# define the alphabet
letters = string.ascii_letters
digits = string.digits
#special_chars = string.punctuation
special_chars = "+=.,:;"

alphabet = letters + digits + special_chars

# fix password length
pwd_length = 12

# generate a password string
pwd = ''
for i in range(pwd_length):
  pwd += ''.join(secrets.choice(alphabet))

print(pwd)

# generate password meeting constraints
while True:
  pwd = ''
  for i in range(pwd_length):
    pwd += ''.join(secrets.choice(alphabet))

  if ((sum(char in special_chars for char in pwd)>=2) and
      sum(char in digits for char in pwd)>=2):
          break
print(pwd)
