#!/bin/bash

# Tested:
#	cron
#	PW Policy

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
            echo "$i:"'$1$FvmieeAj$cDmFLn5RvjYphj3iL1RJZ/' | chpasswd -e
            # chage password policy stuff
            chage -E 01/01/2016 -m 5 -M 90 -I 30 -W 14 $i
            echo "$i" >> ./final_users
            echo "[+] $i - Password changed and password policy set"
        else
            if [ "$i" != "root" ]; then
                echo "[!] Warning! $i is not in list of approved users."
                echo "[!] You should run '$ userdel $i' if this is a rogue user!"
            fi
        fi
    done

    # Disable root account
    echo "root:"'$1$FvmieeAj$cDmFLn5RvjYphj3iL1RJZ/' | chpasswd -e
    passwd -l root 2>&1>/dev/null
    echo "[+] Root account has been locked."

    # Disable guest account
    sed -i 's/allow-guest=true/allow-guest-false/g' /etc/lightdm/lightdm.conf 2>&1>/dev/null
    if grep -q "allow-guest=false" /etc/lightdm/lightdm.conf; then
        echo "[+] Guest account already disabled!"
    else
        echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
    fi
    echo "[+] Guest account disabled. (lightdm)"

    # Hide userlist from login screen
    sed -i 's/greeter-hide-users=false/greeter-hide-users=true/g' /etc/lightdm/lightdm.conf 2>&1>/dev/null
    if grep -q "greeter-hide-users=false" /etc/lightdm/lightdm.conf; then
        echo "[+] User list already hidden!"
    else
        echo "greeter-hide-users=true" >> /etc/lightdm/lightdm.conf
    fi
    echo "[+] User list hidden from login screen. (lightdm)"
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

    apt-get update && apt-get install libpam-cracklib
    if grep -q "ucredit=-1 lcredit=-2 dcredit=-1" /etc/pam.d/common-password; then
        echo "[+] /etc/pam.d/common-password already configured"
    else
        echo "password   requisite    pam_cracklib.so retry=3 minlen=10 difok=3 ucredit=-1 lcredit=-2 dcredit=-1" >> /etc/pam.d/common-password
	echo "[+] /etc/pam.d/common-password set."
    fi

    sed -i 's/PASS_MAX_DAYS	99999/PASS_MAX_DAYS	150/g' /etc/login.defs
    sed -i 's/PASS_MIN_DAYS	0/PASS_MAX_DAYS	7/g' /etc/login.defs
    echo "[+] Password Policy set in /etc/pam.d/common-password and /etc/login.defs"
}

ssh(){

    # This will look to see if "PermitRootLogin yes" is in /etc/ssh/sshd_config.
    # If it is, it will change to "PermitRootLogin no".
    cp /etc/ssh/sshd_config{,.bak} &>/dev/null

    if grep -Fxq "PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "[!] Root SSH login is enabled!"
        sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config 2>&1>/dev/null
        echo "[+] Root SSH login has been disabled."
        echo "[+] If nothing bad happens after a reboot, you can remove /etc/ssh/sshd_config.bak"
    fi

    if grep -Fxq "X11Forwarding yes" /etc/ssh/sshd_config; then
    echo "[!] X11 Forwarding is enabled!"
        sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config 2>&1>/dev/null
        echo "[+] X11 Forwarding has been disabled."
        echo "[+] If nothing bad happens after a reboot, you can remove /etc/ssh/sshd_config.bak"
    fi
}

firewall(){

    # Sets firewall based on allowed ports file

    echo "y" | ufw reset
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
        #printf "\tRunning from: $(ls -la /proc/$pid/exe | awk '{ print $11 }')\n"
        command="$(cat /proc/$pid/cmdline | sed 's/\x0/ /g' | sed 's/.$//')"
        #echo "$command"
        if [[ "$command" == *"nc -l"* ]]; then
            for i in $(grep -s -r --exclude-dir={proc,lib,tmp,usr,var,libproc,sys,run,dev} "$command" $(ls -l /proc/$pid/cwd | awk '{ print $11 }') | awk -F: '{ print $1 }'); do
                printf "   [!]  $i\n"
            done
        fi
    done < ./open_ports
}

cron(){

    # Check scheduled jobs
    echo "[+] Listing /etc/cron* directories"
    ls -la /etc/cron*
    echo "[+] Listing root crontab"
    crontab -l
}

updates(){

    # Updates the system

    # Makes sure sources are added
    if grep -q "deb http://security.ubuntu.com/ubuntu/ precise-security restricted main multiverse universe" /etc/apt/sources.list; then
        echo "[!] Security source already installed!"
    else
        echo "deb http://security.ubuntu.com/ubuntu/ precise-security restricted main multiverse universe" >> /etc/apt/sources.list
        echo "[+] Security source added"
    fi

    if grep -q "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates restricted main multiverse universe" /etc/apt/sources.list; then
        echo "[!] Updates source already installed!"
    else
        echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-updates restricted main multiverse universe" >> /etc/apt/sources.list
        echo "[+] Updates source added"
    fi

    if grep -q "deb http://us.archive.ubuntu.com/ubuntu/ precise-backports restricted main multiverse universe" /etc/apt/sources.list; then
        echo "[!] Backports source already installed!"
    else
        echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-backports restricted main multiverse universe" >> /etc/apt/sources.list
        echo "[+] Backports source added"
    fi

    # Check for updates daily
    if grep -q "APT::Periodic::Update-Package-Lists \"1\";" /etc/apt/apt.conf.d/10periodic; then
        echo "[!] Daily updates check already configured!"
    else
        sed -i 's/APT::Periodic::Update-Package-Lists "0";/APT::Periodic::Update-Package-Lists "1";/g' /etc/apt/apt.conf.d/10periodic
        echo "[+] Daily updates configured"
    fi

    #apt-get update &>/dev/null
    #apt-get dist-upgrade &>/dev/null
    echo "[+] System has been updated"
}

if [ -f ./allowed_users -a -f ./allowed_ports ]; then
    #users
    #groups
    #password_policy
    #ssh
    #firewall
    #ports
    #cron
    updates
else
    echo "[!] Missing ./allowed_users or ./allowed_ports!"
    exit
fi
