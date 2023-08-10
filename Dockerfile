# cf. https://github.com/Jamesits/docker-ripe-atlas/

FROM debian:bullseye as builder

WORKDIR /opt
RUN apt update ; apt install -y git tar fakeroot libssl-dev libcap2-bin autoconf automake libtool build-essential; \
    git clone --recursive https://github.com/RIPE-NCC/ripe-atlas-software-probe.git;
RUN ./ripe-atlas-software-probe/build-config/debian/bin/make-deb
     

FROM debian:bullseye

RUN apt update; \
    apt install -y libcap2-bin iproute2 openssh-client procps net-tools dnsutils screen

COPY --from=builder /opt/atlasswprobe-*.deb /opt

ARG uid=1000
ARG passwd=myatlas
RUN groupadd --force --system --gid ${uid} atlas ; adduser --system --uid ${uid} --gid ${uid} atlas; \
    echo "atlas:${passwd}" | chpasswd; \
    ln -s /bin/true /bin/systemctl; \
    apt install -y /opt/atlasswprobe-*.deb; \
    ln -s /usr/local/atlas/bin/ATLAS /usr/local/bin/atlas; \
    mkdir -p /var/atlasdata; chmod 755 /var/atlasdata; \
    chown -R atlas:atlas /var/atlas-probe /var/atlasdata || true

RUN echo "CHECK_ATLASDATA_TMPFS=no" > /var/atlas-probe/state/config.txt

# https://github.com/Jamesits/docker-ripe-atlas/blob/master/docker-compose.yaml
# docker run ...   --cap-add CHOWN --cap-add SETUID --cap-add SETGID --cap-add DAC_OVERRIDE --cap-add NET_RAW

USER atlas
WORKDIR /var/atlas-probe
ENV HOME=/var/atlas-probe

CMD /usr/local/atlas/bin/ATLAS
