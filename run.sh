#!/bin/bash
set -euo pipefail

# the game process does not print the logs without a PTY, no idea why
if [[ "${NS_RUN_IN_PTY-}" != 1 ]]; then
	exec env NS_RUN_IN_PTY=1 script -qec /usr/local/bin/run.sh /dev/null
	exit 0
fi

stty cols 500 rows 100

exec xvfb-run -a -s '-screen 0 1024x768x24' wine "$SRVPATH/$ENTRY" ${REQUIRED_STARTUP_ARGS-}
