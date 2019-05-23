
import os, time

# import librtmp, numpy
from moviepy.video.io.ffmpeg_writer import FFMPEG_VideoWriter

from pydarknet import Detector, Image
import cv2

import subprocess as sp


# def new_rtmp_stream(url, writeable=False):
#   server = librtmp.RTMP(url, live=True)
#   server.connect()
#   return server.create_stream(writeable=writeable)

if __name__ == "__main__":
    # Optional statement to configure preferred GPU. Available only in GPU version.
    # pydarknet.set_cuda_device(0)

  net = Detector(bytes("/darknet/cfg/yolov3.cfg", encoding="utf-8"), bytes("/darknet/yolov3.weights", encoding="utf-8"), 0,
  bytes("/darknet/cfg/coco.data", encoding="utf-8"))


  video_source = os.getenv('VIDEO_SOURCE', 'rtmp://184.72.239.149/vod/BigBuckBunny_115k.mov')
  output_uri = os.getenv('OUTPUT_URI', 'rtmp://0.0.0.0:5000')

  print('Reading {} to {}'.format(video_source, output_uri))

  # Find OpenCV version
  (major_ver, minor_ver, subminor_ver) = (cv2.__version__).split('.')

  cap = cv2.VideoCapture(video_source)

  source_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH ))
  source_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT ))

  if int(major_ver) < 3:
      source_fps = cap.get(cv2.cv.CV_CAP_PROP_FPS)
      print("Frames per second using video.get(cv2.cv.CV_CAP_PROP_FPS): {0}".format(source_fps))
  else:
      source_fps = cap.get(cv2.CAP_PROP_FPS)
      print("Frames per second using video.get(cv2.CAP_PROP_FPS) : {0}".format(source_fps))

  fourcc = cv2.VideoWriter_fourcc('X','V','I','D')
  # out = cv2.VideoWriter(output_uri, fourcc, source_fps, (source_width, source_height))

  # stream_out = new_rtmp_stream(output_uri, writeable=True)
  stream_out = FFMPEG_VideoWriter(output_uri, (source_width, source_height), source_fps, ffmpeg_params=['-f' ,'flv'])
  
  while True:
    r, frame = cap.read()

    if not cap.isOpened():
      print('Video source unavailable')
      exit(1)

    if r:
        dark_frame = Image(frame)
        results = []
        results = net.detect(dark_frame)

        del dark_frame

        for cat, score, bounds in results:
          x, y, w, h = bounds
          cv2.rectangle(frame, (int(x-w/2),int(y-h/2)),(int(x+w/2),int(y+h/2)),(255,0,0))
          cv2.putText(frame, str(cat.decode("utf-8")), (int(x), int(y)), cv2.FONT_HERSHEY_COMPLEX, 1, (255, 255, 0))

        # cv2.imshow('image', frame)
        # print(results)
        # status_write_out, encoded_frame = cv2.imencode('.jpg', frame)
        try:
          # stream_out.write(frame.tobytes())
          stream_out.write_frame(frame)
        except Exception as e:
          print('Error when streaming out: {}', e)
          # stream_out = new_rtmp_stream(output_uri, writeable=True)


        k = cv2.waitKey(1)
        if k == 0xFF & ord("q"):
          break