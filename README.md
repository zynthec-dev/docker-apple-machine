# Podman Apple Machine

These images turn Apple `container machine` instances into persistent Podman
backends. The macOS Homebrew Podman CLI connects through SSH; the Podman API is
never exposed as an unauthenticated TCP service.

Published variants:

- `ghcr.io/zynthec-dev/podman-apple-machine:rootful` and `:latest`: root user,
  system socket `/run/podman/podman.sock`.
- `ghcr.io/zynthec-dev/podman-apple-machine:rootless`: `podman` user, user
  socket `/run/user/1000/podman/podman.sock`, subordinate IDs starting at
  100000.

## Local layout

- Apple machine: `podman-apple-backend` (4 CPUs, 6 GiB RAM, no home-directory mount)
- Host connection: `apple-container` (the default Podman connection)
- Private key: `~/.config/containers/podman-apple/id_ed25519`
- Login startup: `com.zynthec.podman-apple-backend`

## Image updates

The images are based on Fedora Rawhide so the engine tracks current Podman
releases. The included GitHub Actions workflow rebuilds both ARM64 variants
every Monday and on relevant pushes.

Rebuilding an OCI image does not mutate an existing machine disk. Upgrade an
existing backend with Fedora's package manager, or deliberately recreate the
machine from a newly published image after backing up its Podman storage.

## Useful commands

```sh
podman system connection list
podman info
container machine list
container machine run -n podman-apple-backend --root podman --version
```
