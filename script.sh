#!/bin/bash

# todo:
# 



# Create file called ./allowed_users that contains the allowed users
# one per line. Also, create file called ./allowed_ports with one port
# per line that is allowed.

echo "" > ./final_users

users(){

    # This will search through /etc/passwd searching for users
    # If the user is in the list of approved users, it will tell you
    # Otherwise, it will change the password to Cyb3rP4tr10t5, and
    # set the password policy with chage. Also, it will append the
    # legitimate users to a file called ./final_users.

    users="$(cat /etc/passwd | grep bash | awk -F: '{ print $1 }')"
    for i in $users; do
	if grep -Fxq "$i" ./allowed_users; then
            # This is if the user is in the list of allowed users
            echo "$i:Cyb3rP4tr10t5" | chpasswd
            # chage password policy stuff
            echo "$i" >> ./final_users
            echo "[+] $i - Password changed and password policy set"
        else
            if [ "$i" != "root" ]; then
                echo "[!] Warning! $i is not in list of approved users."
                echo "[!] You should run \'$ userdel $i\' if this is a rogue user!"
            fi
        fi
    done
    passwd -l root 2>&1>/dev/null
    echo "[+] Root account has been locked."
}

groups(){

    # This will list the groups that each user is a member of.

    users="$(cat ./final_users)"
    for i in $users; do
        echo "[+] Listing groups that '$i' is a member of:"
        echo "[+] From /etc/groups:"
        cat /etc/group | grep "$i" --color=auto
        echo "[+] From /etc/gshadow: (Should be the same as from /etc/group"
        cat /etc/gshadow | grep "$i" --color=auto
    done
}

password_policy(){

    # This will set the password policy in /etc/pam.d. This is different than
    # when we ran $ chage with each user.
    echo "[!] Password Policy function not done yet."
}

ssh_root_login(){

    # This will look to see if "PermitRootLogin yes" is in /etc/ssh/sshd_config.
    # If it is, it will change to "PermitRootLogin no".

    if grep -Fxq "PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "[!] Root SSH login is enabled!"
        cp /etc/ssh/sshd_config{,.bak} &>/dev/null
        sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config 2>&1>/dev/null
        echo "[+] Root SSH login has been disabled."
        echo "[+] If nothing bad happens after a reboot, you can remove /etc/ssh/sshd_config.bak"
    fi
}

firewall(){

    # Sets firewall based on allowed ports file

    while read l; do
        ufw allow $l &>/dev/null
        echo "[+] Port $l allowed"
    done < ./allowed_ports
    ufw default deny &>/dev/null
    ufw enable &>/dev/null
    echo "[+] UFW defaut deny, and UFW enabled."
}

ports(){

    # Shows all listening ports, as well as the services running on them. If
    # the service isn't required, you should remove it.
    rm ./open_ports 2>&1>/dev/null
    echo "[+] Open ports"
    netstat -tulpnwa | grep 'LISTEN\|ESTABLISHED' | grep -v "tcp6\|udp6" | awk '{ print $4 " - " $7 }' | awk -F: '{ print "IPV4 - " $2 }' >> ./open_ports
    netstat -tulpnwa | grep 'LISTEN\|ESTABLISHED' | grep "tcp6\|udp6" | awk '{ print $4 " - " $7 }' | awk -F: '{ print "IPV6 - " $4 }' >> ./open_ports

    while read l; do
	echo $l
	pid=$(echo $l | awk '{ print $5 }' | awk -F/ '{ print $1 }')
	printf "\tRunning from: $(ls -la /proc/$pid/exe | awk '{ print $11 }')\n"
	command="$(cat /proc/$pid/cmdline | sed 's/\x0/ /g' | sed 's/.$//')"
	if [[ $command =~ .*nc.* ]]; then
	    printf "\t$(grep -r "$command" $(ls -l /proc/$pid/cwd | awk '{ print $11 }') | awk -F: '{ print $1 }')\n"
	fi
    done < ./open_ports
}

updates(){

    # Updates the system

    apt-get update &>/dev/null
    apt-get dist-upgrade &>/dev/null
    echo "[+] System has been updated"
}

ports

