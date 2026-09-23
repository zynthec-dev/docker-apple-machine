# Docker Apple Machine

Run Docker Engine inside an Apple `container machine` and control it with the
Homebrew Docker CLI on macOS. The daemon stays on a Unix socket inside the VM;
the host connects through SSH instead of an unauthenticated TCP port.

Published ARM64 variants:

- `ghcr.io/zynthec-dev/docker-apple-machine:rootful` and `:latest`: system
  Docker daemon on `/var/run/docker.sock`.
- `ghcr.io/zynthec-dev/docker-apple-machine:rootless`: Docker daemon owned by
  the unprivileged `docker` user on `/run/user/1000/docker.sock`.

## Requirements

- Apple silicon Mac with Apple Container installed and initialized
- Homebrew Docker CLI (`brew install docker docker-buildx docker-compose`)
- No Docker Desktop or separate vendor VM is required

## Create the backend

Choose exactly one mode for the machine named `docker-apple-machine`:

```sh
./bin/create-machine rootful
# or
./bin/create-machine rootless
```

The script pulls the published image, creates a 4-CPU/6-GiB Apple machine,
generates a dedicated SSH key, creates and selects the Docker context
`apple-machine`, installs login startup, and runs an Alpine acceptance test.
It refuses to overwrite an existing machine.

## Daily use

```sh
docker context ls
docker info
docker run --rm alpine echo hello
docker compose version
container machine list
```

Switch back to a different local Docker endpoint with `docker context use
default`. Return with `docker context use apple-machine`.

## Local layout

- Apple machine: `docker-apple-machine`
- Docker context: `apple-machine`
- SSH key: `~/.config/docker/apple-machine/id_ed25519`
- SSH host alias: `docker-apple-machine`
- Login startup: `com.zynthec.docker-apple-machine`

## Image updates

The image uses the current stable Fedora base and Docker's official Fedora RPM
repository. GitHub Actions rebuilds both ARM64 variants every Monday and on
relevant pushes.

Rebuilding an OCI image does not mutate an existing machine disk. Back up
Docker volumes and intentionally recreate the machine when adopting a newly
published base image.
