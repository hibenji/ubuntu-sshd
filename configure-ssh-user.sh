#!/bin/bash

set -e

# Default to SSH_USERNAME if SSH_USERNAMES is not set, otherwise default to "ubuntu"
if [ -z "$SSH_USERNAMES" ]; then
    SSH_USERNAMES="${SSH_USERNAME:-ubuntu}"
fi

# Convert comma-separated or space-separated list to an array
IFS=' ,' read -r -a USERS <<< "$SSH_USERNAMES"

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

# Track if any user has SSH keys to decide on password authentication
ANY_KEYS_PROVIDED=false

# Create users
for USERNAME in "${USERS[@]}"; do
    USERNAME=$(echo "$USERNAME" | xargs) # trim whitespace
    [ -z "$USERNAME" ] && continue
    
    create_user "$USERNAME"
    
    # Check if this user had keys provided
    KEYS_VAR="${USERNAME^^}_AUTHORIZED_KEYS"
    if [ -n "${!KEYS_VAR}" ]; then
        ANY_KEYS_PROVIDED=true
    fi
done

# Also check the legacy AUTHORIZED_KEYS if SSH_USERNAME was used
if [ -n "$AUTHORIZED_KEYS" ]; then
    ANY_KEYS_PROVIDED=true
fi

# Disable password authentication if any SSH keys were provided for security
if [ "$ANY_KEYS_PROVIDED" = true ]; then
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "SSH keys detected: Password authentication disabled."
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
