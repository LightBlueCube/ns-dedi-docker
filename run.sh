#!/bin/bash
set -euo pipefail

if [[ ! -t 0 && "${NS_RUN_IN_PTY-}" != 1 ]]; then
	echo "run.sh: using PTY mode!"
	exec env NS_RUN_IN_PTY=1 script -qec /usr/local/bin/run.sh /dev/null
	exit 0
fi

stty cols 500 rows 100

exec xvfb-run -a -s '-screen 0 1024x768x24' wine "$SRVPATH/$ENTRY" ${REQUIRED_STARTUP_ARGS-}
