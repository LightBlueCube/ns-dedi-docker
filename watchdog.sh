#!/bin/bash
set -euo pipefail

readonly HANG_TIMEOUT="${WATCHDOG_TIMEOUT:-60}"

readonly HEARTBEAT_FILE="/tmp/watchdog-heartbeat"
readonly TITLE_RE=$'\033]0;[^\a]*\a'

log()
{
	printf 'watchdog.sh: %s\n' "$*"
}

if [[ ! "$HANG_TIMEOUT" =~ ^[0-9]+$ ]]; then
	log "WATCHDOG_TIMEOUT must be an integer, got \"$HANG_TIMEOUT\""
	exit 2
fi

readonly KILL_GRACE=5
kill_server()
{
	echo
	log "sending SIGTERM to server..."
	kill -TERM -- "$SERVER_PID" || true

	local waited=0
	while (( waited < KILL_GRACE )); do
		if ! kill -0 -- "$SERVER_PID" 2>/dev/null; then
			return
		fi

		sleep 1
		waited=$((waited + 1))
	done

	echo
	log "server did not exit within ${KILL_GRACE}s, sending SIGKILL..."
	kill -KILL -- "$SERVER_PID" || true
}

check_watchdog()
{
	local now last age
	printf -v now '%(%s)T' -1
	last="$(stat -c %Y -- "$HEARTBEAT_FILE")"
	age=$(( now - last ))

	if (( age >= HANG_TIMEOUT )); then
		echo
		log "did not receive a update in time: last tick was ${age}s ago"
		kill_server
		exit 1
	fi
}

record_heartbeat()
{
	while IFS= read -r _; do
		: > "$HEARTBEAT_FILE"
	done
}

: > "$HEARTBEAT_FILE"
/usr/local/bin/run.sh > >(tee >(grep --line-buffered -o -- "$TITLE_RE" | record_heartbeat)) &
SERVER_PID=$!

log "watching server (pid=$SERVER_PID)"

readonly POLL_INTERVAL=5
while :; do
	sleep $POLL_INTERVAL &
	set +e
	wait -n -p finished
	status=$?
	set -e

	if [[ "${finished-}" == "$SERVER_PID" ]]; then
		exit "$status"
	fi

	check_watchdog
done
