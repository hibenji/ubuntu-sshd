# Use an official Ubuntu base image [cite: 1]
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV SSH_USERNAME="ubuntu"
ENV SSHD_CONFIG_ADDITIONAL=""

# Install OpenSSH server, curl (for node setup), clean up, and configure SSH
# ADDED: curl, nodejs, and @angular/cli installation
RUN apt-get update \
    && apt-get install -y iproute2 iputils-ping openssh-server telnet curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get install -y git \
    && npm install -g @angular/cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && if ! id -u "$SSH_USERNAME" > /dev/null 2>&1; then useradd -ms /bin/bash "$SSH_USERNAME"; fi \
    && chown -R "$SSH_USERNAME":"$SSH_USERNAME" /home/"$SSH_USERNAME" \
    && chmod 755 /home/"$SSH_USERNAME" \
    && mkdir -p /home/"$SSH_USERNAME"/.ssh \
    && chown "$SSH_USERNAME":"$SSH_USERNAME" /home/"$SSH_USERNAME"/.ssh \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copy the script to configure the user's password and authorized keys
COPY configure-ssh-user.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure-ssh-user.sh

# Expose SSH port
EXPOSE 22

# Start SSH server
CMD ["/usr/local/bin/configure-ssh-user.sh"]