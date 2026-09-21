FROM docker.io/library/fedora:rawhide AS base

LABEL org.opencontainers.image.title="Podman backend for Apple Container machines" \
      org.opencontainers.image.description="Podman API backend secured with SSH for Apple container machine" \
      org.opencontainers.image.source="https://github.com/zynthec-dev/podman-apple-container-machine"

RUN dnf -y upgrade --refresh \
    && dnf -y install \
        fuse-overlayfs \
        iproute \
        openssh-server \
        podman \
        procps-ng \
        shadow-utils \
        slirp4netns \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && ssh-keygen -A \
    && systemctl enable sshd.service

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

FROM base AS rootful

LABEL io.zynthec.podman.mode="rootful"

RUN install -d -m 0700 /root/.ssh \
    && systemctl enable podman.socket

COPY config/10-podman-apple-rootful.conf /etc/ssh/sshd_config.d/10-podman-apple.conf

FROM base AS rootless

LABEL io.zynthec.podman.mode="rootless"

RUN useradd --create-home --uid 1000 --shell /bin/bash podman \
    && passwd -d podman \
    && chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap \
    && printf 'podman:100000:65536\n' > /etc/subuid \
    && printf 'podman:100000:65536\n' > /etc/subgid \
    && install -d -m 0700 -o podman -g podman /home/podman/.ssh \
    && install -d -m 0755 /var/lib/systemd/linger \
    && touch /var/lib/systemd/linger/podman \
    && install -d -m 0755 /etc/systemd/user/sockets.target.wants \
    && ln -s /usr/lib/systemd/user/podman.socket /etc/systemd/user/sockets.target.wants/podman.socket

COPY config/10-podman-apple-rootless.conf /etc/ssh/sshd_config.d/10-podman-apple.conf
