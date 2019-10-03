#!/usr/bin/env bash

. /docker-environment.sh

python3 /python-test.py

# case "$1" in
#   detect)
# 	mv /darknet/predictions* /darknet_data/
#     ;;
#   *)
# 	echo "done."
#     ;;
# esac