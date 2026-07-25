#!/bin/bash
set -euo pipefail

stty cols 500 rows 100 opost onlcr

exec xvfb-run -a -s '-screen 0 1024x768x24' wine "$SRVPATH/$ENTRY" $REQUIRED_STARTUP_ARGS $NS_STARTUP_ARGS
