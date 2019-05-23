#!/bin/sh
set -x
if [ -z $STREAM_FROM ]; then
        STREAM_FROM=rtmp://0.0.0.0:1935/stream/unamed-from
        echo "No target server uri defined in STREAM_FROM, defaulting to $STREAM_FROM in 5s"
fi
if [ -z $STREAM_TO ]; then
	STREAM_TO=rtmp://0.0.0.0:1935/stream/unamed-to
	echo "No target server uri defined in STREAM_TO, defaulting to $STREAM_TO in 5s"
    sleep 5
fi

ffmpeg -re -fflags +genpts -stream_loop -1 -i $STREAM_FROM -listen 1 -vcodec h264 -profile:v main -preset:v medium -r 30 -g 60 -keyint_min 60 -sc_threshold 0 -b:v 2500k -maxrate 2500k -bufsize 2500k  -sws_flags lanczos+accurate_rnd -acodec libfdk_aac -b:a 96k -ar 48000 -ac 2 -f flv $STREAM_TO
