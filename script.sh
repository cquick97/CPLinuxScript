#!/bin/bash

rm ./final_users

users(){
  
# This will search through /etc/passwd searching for users
# If the user is in the list of approved users, it will tell you
# Otherwise, it will change the password to Cyb3rP4tr10t5, and
# set the password policy with chage. Also, it will append the 
# legitimate users to a file called ./final_users.

  users="$(cat /etc/passwd | grep bash | awk -f: '{ print $1 }')"
  for i in $users; do
    if grep -Fxq "$i" ./allowed_users; then
      # This is if the user is in the list of allowed users
      echo "Cyb3rP4tr10t5:$i" | chpasswd
      # chage password policy stuff
      echo "$i" >> ./final_users
      echo "[+] $i - Password changed and password policy set"
    else
      echo "[!] Warning! $i is not in list of approved users."
      echo "[!] You should run \'$ userdel $i\' if this is a rogue user!"
    fi
  done
  passwd -l root
  echo "[+] Root account has been locked."
}

groups(){
  
# This will list the groups that each user is a member of.

  users="$(cat ./final_users)"
  for i in $users; do
    echo "[+] Listing groups that '$i' is a member of:"
    echo "[+] From /etc/groups:"
    cat /etc/groups | grep "$i"
    echo "[+] From /etc/gshadow: (Should be the same as from /etc/group"
    cat /etc/gshadow | grep "$i"; echo; echo
  done
}

password_policy(){
  
# This will set the password policy in /etc/pam.d. This is different than
# when we ran $ chage with each user.
  
  
}


