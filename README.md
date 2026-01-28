[![Docker Image CI](https://github.com/aoudiamoncef/ubuntu-sshd/actions/workflows/ci.yml/badge.svg)](https://github.com/aoudiamoncef/ubuntu-sshd/actions/workflows/ci.yml)
[![Docker Image Deployment](https://github.com/aoudiamoncef/ubuntu-sshd/actions/workflows/cd.yml/badge.svg)](https://github.com/aoudiamoncef/ubuntu-sshd/actions/workflows/cd.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/aoudiamoncef/ubuntu-sshd.svg)](https://hub.docker.com/r/aoudiamoncef/ubuntu-sshd)
[![Maintenance](https://img.shields.io/badge/Maintained-Yes-green.svg)](https://github.com/aoudiamoncef/ubuntu-sshd)

This Docker image provides an Ubuntu 24.04 base with SSH server enabled. It allows you to easily create SSH-accessible containers via SSH keys or with a default username and password.

## Usage

### Cloning the Repository

To get started, clone the GitHub [repository](https://github.com/aoudiamoncef/ubuntu-sshd) containing the Dockerfile and
scripts:

```bash
git clone https://github.com/aoudiamoncef/ubuntu-sshd
cd ubuntu-sshd
```

### Building the Docker Image

Build the Docker image from within the cloned repository directory:

```bash
docker build -t my-ubuntu-sshd:latest .
```

### Running a Container

#### Single User (Compatibility Mode)
```bash
docker run -d \
  -p 2222:22 \
  -e SSH_USERNAME=myuser \
  -e SSH_PASSWORD=mysecretpassword \
  my-ubuntu-sshd:latest
```

#### Multi-User Setup
To run a container with three users:
```bash
docker run -d \
  -p 2222:22 \
  -e SSH_USERNAMES="alice bob charlie" \
  -e ALICE_PASSWORD="password1" \
  -e BOB_AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub)" \
  -e CHARLIE_PASSWORD="password3" \
  my-ubuntu-sshd:latest
```

- `-e SSH_USERNAMES="user1 user2 ..."`: A space or comma-separated list of usernames to create.
- `${USERNAME^^}_PASSWORD`: Sets the password for a specific user (e.g., `ALICE_PASSWORD`).
- `${USERNAME^^}_AUTHORIZED_KEYS`: Sets the authorized SSH keys for a specific user.
- If ANY user has authorized keys provided, password authentication is disabled globally for security.

#### Full Stack Example (Docker Compose)
Here is a comprehensive layout including PostgreSQL, pgAdmin, and the SSH server with three users (`benji`, `edi`, `steffi`):

```yaml
services:
  postgres:
    image: postgres:15
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: your_db_password
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
    volumes:
      - postgres_data:/var/lib/postgresql/data

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    restart: unless-stopped
    depends_on:
      - postgres
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: root
    ports:
      - "8090:80"

  sshd:
    image: my-ubuntu-sshd:latest
    container_name: sshd_multiuser
    restart: unless-stopped
    ports:
      - "2225:22"
      - "5500-5510:4500-4510"
    environment:
      - SSH_USERNAMES=benji,edi,steffi
      - BENJI_PASSWORD=Benji2020!
      - BENJI_AUTHORIZED_KEYS=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDpucFlVShs1KaAg5CI/6ErGmTEg70tHT8hMLPVO2bIVka4T/q4BQ1HV4217xCmM7O5J3EOq1IbjG4KZn+PKw6ICASuWv/pBQOUj6GNui6VwJBQzxh1J0f8VAyVzElOghn5WfRpJax3lVbB/89MLOEM3xnhp2l3N2FoqGNRam02L3R4WKLf1ag8PQQ+rn+prz8ROLiEJWLPMdwDw0MzPyPdJVtPd4oGIPuYodS9QDfMfTagEq9AE7lheKQ/I383QCoBsxSBfLRb74YKX83PJYtK9PYDTcceLKPXFrYInVKHse3/3pIg41xrCGSRzj8oBOzsgrS7Yaq3JRVwAu8WDuY2YuyQgvYywU0/eArmvg+80Gt+sAM3Z/clD5wn9luBtmqHuDgtUYZC3DFw/d9ne8Hoc44Ox0Am2rS0NjakyQcxtLHtUn6M4Y+vIlUMo9HeQhsS4n+Hfo4i1LQgPNIOlzJ9WbeCZitVqnpTCwCvASogHwr7a29Qa/AujC9dwQy8lewpEqMklt8vCV7a4/mUxYBbR+CSv2n59sWcr+JlqBVzmTm5vPthUm13Bfd+m5sZJzQ9Gd78+WJNaRNPw6qEvWf0KQUZo1TIYf6izWJJ7EieZw30rZsE/bLlgtOGc525ME2EXFx+KUsrri6AnmXgfHtwcBZkxwNkbB5AyKFV4t3Ogw==
      - EDI_PASSWORD=test
      - STEFFI_PASSWORD=test
    volumes:
      - /shared_data:/shared

volumes:
  postgres_data:
```

- `-d` runs the container in detached mode.
- `-p host-port:22` maps a host port to port 22 in the container. Replace `host-port` with your desired port.
- `-e SSH_USERNAME=myuser` sets the SSH username in the container. Replace `myuser` with your desired username.
- `-e SSH_PASSWORD=mysecretpassword` sets the SSH user's password in the container. **This environment variable is
  required**. Replace `mysecretpassword` with your desired password.
- `-e AUTHORIZED_KEYS="$(cat path/to/authorized_keys_file)"` sets authorized SSH keys in the container. Replace `path/to/authorized_keys_file` with the path to your authorized_keys file.
- `-e SSHD_CONFIG_ADDITIONAL="your_additional_config"` allows you to pass additional SSHD configuration. Replace
  `your_additional_config` with your desired configuration.
- `-e SSHD_CONFIG_FILE="/path/to/your/sshd_config_file"` allows you to specify a file containing additional SSHD
  configuration. Replace `/path/to/your/sshd_config_file` with the path to your configuration file.
- `my-ubuntu-sshd:latest` should be replaced with your Docker image's name and tag.

### SSH Access

Once the container is running, you can SSH into it using the following command:

```bash
ssh -p host-port myuser@localhost
```

- `host-port` should match the port you specified when running the container.
- Use the provided password or SSH key for authentication, depending on your configuration.

### Note

- If the `AUTHORIZED_KEYS` environment variable is empty when starting the container, it will still launch the SSH server, but no authorized keys will be configured. You have to mount your own authorized keys file or manually configure the keys in the container.
- If `AUTHORIZED_KEYS` is provided, password authentication will be disabled for enhanced security.

## License

This Docker image is provided under the [MIT License](LICENSE).
