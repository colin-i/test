
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
pwd_length = 14

# generate a password string
#pwd = ''
#for i in range(pwd_length):
#  pwd += ''.join(secrets.choice(alphabet))
#print(pwd)

# generate password meeting constraints
while True:
  pwd = ''
  for i in range(pwd_length):
    pwd += ''.join(secrets.choice(alphabet))

  if (sum(char in digits for char in pwd)>=2 and
      sum(char in special_chars for char in pwd)>=1): # at least 2 digits and 1 special char
          break
#52 letters  10 digits  6 special_chars
#5.8*2=11.6 at 2 digits
#10.(3) at 1 special
print(pwd)
