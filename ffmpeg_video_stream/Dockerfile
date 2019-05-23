FROM alfg/nginx-rtmp:latest

ADD ./stream_video_file.sh /stream_video_file.sh
RUN chmod 755 /stream_video_file.sh


ENTRYPOINT ["/stream_video_file.sh"]
