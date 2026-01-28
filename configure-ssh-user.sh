#!/bin/bash

set -e

: ${SSHD_CONFIG_ADDITIONAL:=""}

USERS=("benji" "steffi" "edi")

# Ensure sudo is installed (important for minimal images)
if ! command -v sudo >/dev/null 2>&1; then
    echo "Installing sudo..."
    apt-get update && apt-get install -y sudo
fi

create_user() {
    local USERNAME="$1"
    local PASSWORD_VAR="${USERNAME^^}_PASSWORD"
    local KEYS_VAR="${USERNAME^^}_AUTHORIZED_KEYS"

    local PASSWORD="${!PASSWORD_VAR}"
    local AUTHORIZED_KEYS="${!KEYS_VAR}"

    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists"
    else
        useradd -ms /bin/bash "$USERNAME"
        echo "User $USERNAME created"
    fi

    # Set password if provided
    if [ -n "$PASSWORD" ]; then
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "Password set for $USERNAME"
    fi

    # Add to sudo group
    usermod -aG sudo "$USERNAME"

    # Passwordless sudo
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
    chmod 440 /etc/sudoers.d/$USERNAME

    # SSH authorized keys
    if [ -n "$AUTHORIZED_KEYS" ]; then
        HOME_DIR="/home/$USERNAME"
        mkdir -p "$HOME_DIR/.ssh"
        echo "$AUTHORIZED_KEYS" > "$HOME_DIR/.ssh/authorized_keys"
        chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.ssh"
        chmod 700 "$HOME_DIR/.ssh"
        chmod 600 "$HOME_DIR/.ssh/authorized_keys"
        echo "Authorized keys set for $USERNAME"
    fi
}

# Create users
for USER in "${USERS[@]}"; do
    create_user "$USER"
done

# Disable password authentication if any SSH keys were provided
if [ -n "$BENJI_AUTHORIZED_KEYS" ] || [ -n "$ROMAN_AUTHORIZED_KEYS" ]; then
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Apply additional SSHD configuration if provided
if [ -n "$SSHD_CONFIG_ADDITIONAL" ]; then
    echo "$SSHD_CONFIG_ADDITIONAL" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration applied"
fi

# Apply additional SSHD configuration from a file if provided
if [ -n "$SSHD_CONFIG_FILE" ] && [ -f "$SSHD_CONFIG_FILE" ]; then
    cat "$SSHD_CONFIG_FILE" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration from file applied"
fi

# Start SSH server
echo "Starting SSH server..."
exec /usr/sbin/sshd -D
