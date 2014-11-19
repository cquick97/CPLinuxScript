#!/bin/bash

users(){
  users="$(cat /etc/passwd | grep bash | awk -f: '{ print $1 }')"
  for i in $users; do
    if grep -Fxq "$i" ./allowed_users; then
      # This is if the user is in the list of allowed users
      echo "Cyb3rP4tr10t5:$i" | chpasswd
      # chage blah blah password policy stuff
      echo "[+] $i - Password changed and password policy set."
    else
      echo "[!] Warning! $i is not in list of approved users."
    fi
  done
}




