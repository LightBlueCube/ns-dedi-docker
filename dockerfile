FROM archlinux:base

RUN pacman -Syu --noconfirm wine-staging xorg-server-xvfb && \
	rm -rf /var/cache/pacman/pkg/* && \
	useradd -m nsrunner

COPY --chown=nsrunner:nsrunner --chmod=755 entrypoint.sh run.sh /usr/local/bin/
COPY --chown=nsrunner:nsrunner R2N /home/r2ds

RUN mkdir /mnt/mods /mnt/plugins

ENV SRVPATH="/home/r2ds"
ENV ENTRY="NorthstarLauncher.exe"
ENV MODPATH="${SRVPATH}/R2Northstar/mods"
ENV PLUGINPATH="${SRVPATH}/R2Northstar/plugins"
ENV NS_WINE_PREFIX="/home/nsrunner/.wine"

ENV REQUIRED_STARTUP_ARGS="-dedicated"
ENV NS_STARTUP_ARGS=""

ENV PORT_TCP="8081"
ENV PORT_UDP="37015"
ENV SRV_NAME="hello world!"
ENV SRV_DESC="programming in c"

WORKDIR ${SRVPATH}
CMD ["sh", "-c", "entrypoint.sh"]
