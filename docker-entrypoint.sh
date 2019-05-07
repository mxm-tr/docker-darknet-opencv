#!/usr/bin/env bash
echo "Running darknet with args $@"



export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH;

./darknet "$@"	

# case "$1" in
#   detect)
# 	mv /darknet/predictions* /darknet_data/
#     ;;
#   *)
# 	echo "done."
#     ;;
# esac