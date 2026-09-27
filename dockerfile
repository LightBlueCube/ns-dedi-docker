FROM archlinux:base

RUN pacman -Syu --noconfirm wine-staging && \
	rm -rf /var/cache/pacman/pkg/* && \
	useradd -m nsrunner

COPY --chown=nsrunner:nsrunner --chmod=755 entrypoint.sh run.sh watchdog.sh /usr/local/bin/

RUN mkdir -p /home/r2ds /mnt/mods /mnt/plugins

ENV SRV_NAME="hello world!"
ENV SRV_DESC="programming in c"
ENV PORT_TCP="8081"
ENV PORT_UDP="37015"
ENV STARTUP_ARGS=""

ENV WATCHDOG_ENABLE=1
ENV WATCHDOG_TIMEOUT=60

ENV REQUIRED_STARTUP_ARGS="-dedicated -noconsoleinput -noshaderapi -nowindow"
ENV SRVPATH="/home/r2ds"
ENV ENTRY="NorthstarLauncher.exe"
ENV MODPATH="${SRVPATH}/R2Northstar/mods"
ENV PLUGINPATH="${SRVPATH}/R2Northstar/plugins"
ENV NS_WINE_PREFIX="/home/nsrunner/.wine"


WORKDIR ${SRVPATH}
CMD ["sh", "-c", "entrypoint.sh"]
