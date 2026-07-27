#!/bin/bash
set -euo pipefail

log()
{
	printf 'entrypoint.sh: %s\n' "$*"
}

printf "\n\n\n\nNorthstar Dedicated Server - Docker\n"

if [ ! -f "$SRVPATH/$ENTRY" ]; then
	log "missing northstar, copying files..."
	cp -rf /mnt/northstar/* $SRVPATH
	chown -R nsrunner:nsrunner $SRVPATH

	log "writing NS_STARTUP_ARGS to ns_startup_args_dedi.txt..."
	printf '%s' "${NS_STARTUP_ARGS-}" > "$SRVPATH/ns_startup_args_dedi.txt"

	log "linking plugins..."
	rm -rf -- "$PLUGINPATH"
	ln -s -- /mnt/plugins "$PLUGINPATH"
fi

declare -A CFG_ENV_ALIASES=(
	[ns_server_name]="SRV_NAME"
	[ns_server_desc]="SRV_DESC"
	[ns_player_auth_port]="PORT_TCP"
)

split_cfg_comment()
{
	local input="$1"
	local index character quoted=0 escaped=0

	CFG_CODE="$input"
	CFG_COMMENT=""

	for ((index = 0; index < ${#input}; index += 1)); do
		if ((quoted == 0)) && [[ "${input:index:2}" == "//" ]]; then
			CFG_CODE="${input:0:index}"
			CFG_COMMENT="${input:index}"
			return
		fi

		character="${input:index:1}"

		if [[ "$character" == '\' && $escaped -eq 0 ]]; then
			escaped=1
			continue
		fi

		if [[ "$character" == '"' && $escaped -eq 0 ]]; then
			quoted=$((1 - quoted))
		fi

		escaped=0
	done
}

generate_cfg_env()
{
	local source="$1"
	local destination="$2"
	local destination_dir destination_name marker tmp
	local line indent key separator old_value trailing
	local alias env_name env_value cfg_value

	destination_dir="$(dirname "$destination")"
	destination_name="$(basename "$destination")"
	marker="${destination_dir}/.${destination_name}.has-generated"
	if [[ -f "$marker" ]]; then
		log "already generated autoexec_ns_server.cfg, skipping!"
		return 0
	fi

	log "generating autoexec_ns_server.cfg..."
	mkdir -p -- "$destination_dir"
	tmp="$(mktemp "$destination_dir/.cfg-env.XXXXXX")" || return 1

	while IFS='' read -r line || [[ -n "$line" ]]; do
		split_cfg_comment "$line"

		if [[ "$CFG_CODE" =~ ^([[:space:]]*)([A-Za-z_][A-Za-z0-9_]*)([[:space:]]+)(.*)$ ]]; then
			indent="${BASH_REMATCH[1]}"
			key="${BASH_REMATCH[2]}"
			separator="${BASH_REMATCH[3]}"
			old_value="${BASH_REMATCH[4]}"

			env_name="$key"
			alias="${CFG_ENV_ALIASES[$key]-}"
			if [[ -n "$alias" && -v "$alias" ]]; then
				env_name="$alias"
			fi

			if [[ -v "$env_name" ]] && [[ "$old_value" =~ [^[:space:]] ]]; then
				env_value="${!env_name}"
				cfg_value="$env_value"

				if [[ ! "$cfg_value" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] &&
					[[ ! "$cfg_value" =~ ^\".*\"$ ]]; then
					cfg_value="${cfg_value//\\/\\\\}"
					cfg_value="${cfg_value//\"/\\\"}"
					cfg_value="\"$cfg_value\""
				fi

				if [[ "$old_value" =~ ^(.*[^[:space:]])([[:space:]]*)$ ]]; then
					trailing="${BASH_REMATCH[2]}"
					printf '%s%s%s%s%s%s\n' \
						"$indent" "$key" "$separator" \
						"$cfg_value" "$trailing" "$CFG_COMMENT" >> "$tmp"
					continue
				fi
			fi
		fi

		printf '%s\n' "$line" >> "$tmp"
	done < "$source"

	chmod --reference="$source" "$tmp" 2>/dev/null || true
	mv -f -- "$tmp" "$destination"

	touch "$marker"
}

generate_cfg_env \
	"/mnt/northstar/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg" \
	"$MODPATH/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"

create_mods_link()
{
	local source="$1"
	local path
	local name

	while IFS='' read -r -d '' path; do
		name="${path##*/}"
		ln -sfnT -- "$path" "$MODPATH/$name"
	done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
}

list_file_names()
{
	local dir="$1"

	find "$dir" -mindepth 1 -maxdepth 1 \
		! -name "Northstar.Client" \
		! -name "Northstar.Custom" \
		! -name "Northstar.CustomServers" \
		-printf '%f\0' |
		LC_ALL=C sort -z
}

if ! cmp -s <(list_file_names "$MODPATH") <(list_file_names "/mnt/mods"); then
	log "syncing mods..."
	find "$MODPATH" -mindepth 1 -maxdepth 1 \
		! -name "Northstar.Client" \
		! -name "Northstar.Custom" \
		! -name "Northstar.CustomServers" \
		-exec rm -rf -- {} +
	create_mods_link "/mnt/mods"
else
	log "mods are already up to date!"
fi

export WINEPREFIX="${WINEPREFIX:-$NS_WINE_PREFIX}"

if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
	log "wine prefix is missing; initializing it at $WINEPREFIX"
	runuser -u nsrunner -- env WINEPREFIX="$WINEPREFIX" wineboot
else
	log "preparing persistent wine session..."
	# keep wineboot's volatile CPU/TSC registry alive; without it, the game simulation runs slowly.
	runuser -u nsrunner -- env WINEPREFIX="$WINEPREFIX" bash -c 'wineserver -p && wineboot -u'
fi

if [[ -n "${PORT_UDP-}" ]]; then
	REQUIRED_STARTUP_ARGS="$REQUIRED_STARTUP_ARGS -port $PORT_UDP"
fi

# suppress bcrypt fixme message, otherwise it spams dozens of messages per second
export WINEDEBUG="${WINEDEBUG:-fixme-bcrypt}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winedbg.exe=}"

log "all done! starting the server..."
# wine writes window-title OSC sequences to stdout. docker's log see them as plain text, so filter them out with sed.
exec runuser -u nsrunner -- /usr/local/bin/run.sh > >(sed -u $'s/\033]0;[^\a]*\a//g')
