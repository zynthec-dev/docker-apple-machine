FROM docker.io/library/fedora:latest AS base

LABEL org.opencontainers.image.title="Docker Apple Machine" \
      org.opencontainers.image.description="Docker Engine backend secured with SSH for Apple container machines" \
      org.opencontainers.image.source="https://github.com/zynthec-dev/docker-apple-machine"

RUN dnf -y upgrade --refresh \
    && dnf -y install dnf-plugins-core \
    && dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
    && dnf -y install \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        docker-ce-rootless-extras \
        fuse-overlayfs \
        iproute \
        openssh-server \
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

LABEL io.zynthec.docker.mode="rootful"

RUN install -d -m 0700 /root/.ssh \
    && systemctl enable docker.service

COPY config/10-docker-apple-rootful.conf /etc/ssh/sshd_config.d/10-docker-apple.conf

FROM base AS rootless

LABEL io.zynthec.docker.mode="rootless"

RUN groupmod --gid 1000 docker \
    && useradd --create-home --uid 1000 --gid docker --shell /bin/bash docker \
    && passwd -d docker \
    && chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap \
    && printf 'docker:100000:65536\n' > /etc/subuid \
    && printf 'docker:100000:65536\n' > /etc/subgid \
    && install -d -m 0700 -o docker -g docker /home/docker/.ssh \
    && printf 'DOCKER_HOST=unix:///run/user/1000/docker.sock\n' > /home/docker/.ssh/environment \
    && chown docker:docker /home/docker/.ssh/environment \
    && chmod 0600 /home/docker/.ssh/environment \
    && install -d -m 0755 /var/lib/systemd/linger \
    && touch /var/lib/systemd/linger/docker \
    && install -d -m 0755 -o docker -g docker /home/docker/.config/systemd/user/default.target.wants

COPY --chown=docker:docker config/docker-rootless.service /home/docker/.config/systemd/user/docker.service

RUN ln -s ../docker.service /home/docker/.config/systemd/user/default.target.wants/docker.service

COPY config/10-docker-apple-rootless.conf /etc/ssh/sshd_config.d/10-docker-apple.conf
