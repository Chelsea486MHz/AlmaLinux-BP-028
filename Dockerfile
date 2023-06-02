FROM almalinux:9.2

RUN dnf install -y epel-release
RUN dnf install -y xorriso syslinux createrepo dnf-plugins-core

WORKDIR /app
COPY build.sh /app/build.sh
RUN chmod +x /app/build.sh

CMD ["/app/build.sh"]
