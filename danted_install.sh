#!/bin/bash
# Dependency: dante-server members
install() {
    res=$(which yum 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        res=$(which apt 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Unsupported Linux. yum or apt is required."
            exit 1
        fi
        apt update
        apt install -y dante-server members
    else
        yum install -y dante-server members
    fi

    if ! systemctl &> /dev/null; then
        echo "systemctl is not found, this system is not supported"
        exit 1
    fi

		# Get list of available network interfaces excluding lo
    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v "^lo$"))
    
    echo "Available Interfaces:"
    for i in "${!interfaces[@]}"; do
        echo "$((i+1)). ${interfaces[$i]}"
    done
    
    while true; do
        read -p 'Select an interface by number: ' choice
        if [[ "$choice" -ge 1 && "$choice" -le "${#interfaces[@]}" ]]; then
            INTERFACE="${interfaces[$((choice-1))]}"
            break
        else
            echo "Invalid choice. Please select a valid number."
        fi
    done

    cat >/etc/danted.conf <<-EOF
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

# The listening network interface or address.
internal: 0.0.0.0 port=1080

# The proxying network interface or address.
external: $INTERFACE

# socks-rules determine what is proxied through the external interface.
socksmethod: username

# client-rules determine who can connect to the internal interface.
clientmethod: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
EOF

    ufw allow 1080
    if [[ $? -eq 0 ]]; then
	    echo "UFW policy added successfully"
		else 
			echo "UFW policy added failed."
    fi
    systemctl restart danted.service
    systemctl status danted.service --no-pager

}

uninstall() {
    res=$(which yum 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        res=$(which apt 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Unsupported Linux. yum or apt is required."
            exit 1
        fi
        apt purge -y dante-server 
    else
        yum remove -y dante-server
    fi

    # Check and stop danted service if it is running
    if systemctl is-active --quiet danted.service; then
        systemctl stop danted.service
    fi

    # Remove danted service if it exists
    if [[ -e /etc/systemd/system/danted.service ]]; then
        rm /etc/systemd/system/danted.service
        systemctl daemon-reload
    fi

    # Remove the danted config file if it exists
    if [[ -e /etc/danted.conf ]]; then
        rm /etc/danted.conf
    fi

    # Remove UFW rule for port 1080
    ufw delete allow 1080

    echo "dante-server has been uninstalled and configurations have been cleaned up."

    # Check if socks_user group exists and prompt to delete its users and itself
    if members socks_user; then
        read -p "Do you want to remove all users of the 'socks_user' group and the group itself? (yes/no) " RESP
        if [[ $RESP == "yes" ]]; then
            # Iterate over users in the socks_user group and remove them
            for user in $(members socks_user); do
                userdel -r "$user"
            done
            # Remove the group
            groupdel socks_user
            echo "All users of the 'socks_user' group and the group itself have been removed."
        else
            echo "Skipped removing users and the 'socks_user' group."
        fi
    fi
}

add_user() {
    read -p 'Username: ' USERNAME
    # Sanitize the input to prevent injection
    USERNAME=$(echo "$USERNAME" | tr -d ';|&<>!')

    groupadd socks_user
    useradd -r -s /bin/false -g socks_user "$USERNAME"
    passwd "$USERNAME"
}

del_user() {
    if members socks_user; then
        read -p 'Username to delete: ' USERNAME
        # Sanitize the input to prevent injection
        USERNAME=$(echo "$USERNAME" | tr -d ';|&<>!')

        if members socks_user | grep -q "$USERNAME"; then
            killall -KILL -u "$USERNAME"
            userdel -r -f "$USERNAME"
        else
            echo "Invalid username. Please check the username you entered."
        fi
    else
        echo "Execution failed. Maybe no proxy user exists."
    fi
}

menu() {
    clear
    echo "#############################################################"
    echo "1. Install Service"
    echo "2. Add a User"
    echo "3. Delete a User"
    echo "5. Uninstall Service"
    echo "4. Exit"
		echo "#############################################################"
    read -p "Please Enter a Number to Select [1-4]: " ANSWER
    case $ANSWER in
        1)
            install
            ;;
        2)
            add_user
            ;;
        3)
            del_user
            ;;
        5)
            uninstall
            ;;
        *)
            echo "Goodbye"
            exit 0
            ;;
    esac
}

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

while true; do
    menu
    read -p "Press Enter to continue"
done