#!/usr/bin/env python3

import os, time, argparse, logging, glob

from moviepy.video.io.ffmpeg_writer import FFMPEG_VideoWriter

from pydarknet import Detector, Image
import cv2

import subprocess as sp

# Optional statement to configure preferred GPU. Available only in GPU version.
# pydarknet.set_cuda_device(0)

def detect_video_stream(source_uri, output_uri, darknet_cfg_path, darknet_weigths_path, darknet_coco_data_path, threshold=0.5, show_output=False):

  logging.info('Run darknet on video streams')
  logging.info('Reading {} to {}'.format(source_uri, output_uri))

  if not show_output and not output_uri:
    logging.warning('Both show_output and output_uri are not used. No visible output is going to be produced.')

  net = Detector(bytes(darknet_cfg_path, encoding="utf-8"), bytes(darknet_weigths_path, encoding="utf-8"), 0,
                bytes(darknet_coco_data_path, encoding="utf-8"))

  # Find OpenCV version
  (major_ver, minor_ver, subminor_ver) = (cv2.__version__).split('.')

  cap = cv2.VideoCapture(source_uri)

  source_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
  source_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

  if int(major_ver) < 3:
      source_fps = cap.get(cv2.cv.CV_CAP_PROP_FPS)
      logging.info("Frames per second using video.get(cv2.cv.CV_CAP_PROP_FPS): {0}".format(source_fps))
  else:
      source_fps = cap.get(cv2.CAP_PROP_FPS)
      logging.info("Frames per second using video.get(cv2.CAP_PROP_FPS) : {0}".format(source_fps))

  if output_uri:
    stream_out = FFMPEG_VideoWriter(output_uri, (source_width, source_height), source_fps, ffmpeg_params=['-f' ,'flv'])
  
  while True:

    r, frame = cap.read()

    if not cap.isOpened():
      logging.error('Video source unavailable')
      exit(1)

    if r:
        dark_frame = Image(frame)
        results = []
        results = net.detect(dark_frame, thresh=threshold)

        del dark_frame

        for cat, score, bounds in results:
          x, y, w, h = bounds
          cv2.rectangle(frame, (int(x-w/2),int(y-h/2)),(int(x+w/2),int(y+h/2)),(255,0,0))
          cv2.putText(frame, str(cat.decode("utf-8")), (int(x), int(y)), cv2.FONT_HERSHEY_COMPLEX, 1, (255, 255, 0))

        # status_write_out, encoded_frame = cv2.imencode('.jpg', frame)
        print(show_output)
        if show_output:
          cv2.imshow('image', frame)

        try:
          # stream_out.write(frame.tobytes())
          if output_uri:
            stream_out.write_frame(frame)

        except Exception as e:
          print('Error when streaming out: {}', e)

        k = cv2.waitKey(1)
        if k == 0xFF & ord("q"):
          break

def detect_on_image(source_uri, output_uri, darknet_cfg_path, darknet_weigths_path, darknet_coco_data_path, threshold=.5, show_output=False):

  logging.info('Run darknet on images')

  net = Detector(bytes(darknet_cfg_path, encoding="utf-8"), bytes(darknet_weigths_path, encoding="utf-8"), 0,
  bytes(darknet_coco_data_path, encoding="utf-8"))

  print('Reading {} to {}'.format(source_uri, output_uri))
  frame = cv2.imread(source_uri)
  dark_frame = Image(frame)
  results = net.detect(dark_frame, thresh=threshold)

  del dark_frame

  for cat, score, bounds in results:
    x, y, w, h = bounds
    cv2.rectangle(frame, (int(x-w/2),int(y-h/2)),(int(x+w/2),int(y+h/2)),(255,0,0))
    cv2.putText(frame, str(cat.decode("utf-8")), (int(x), int(y)), cv2.FONT_HERSHEY_COMPLEX, 1, (255, 255, 0))

  if show_output:
    cv2.namedWindow("Imgshow", 0)
    cv2.resizeWindow("Imgshow", 2000,2000)
    cv2.imshow('Imgshow', frame)
    k = cv2.waitKey()
  if output_uri:
    cv2.imwrite(output_uri, frame)

def check_env(env_var_name, check_filepath=False):
  ''' Checks whether an environment variable exists.
  If check_filepath is True, checks whether the value
  of the environment variable points to an existing file.
  Raise an exception if one test fails.
  Returns the value of the enviroment variable.
  '''
  env_var_value = os.getenv(env_var_name)
  logging.info('Checking variable {}'.format(env_var_name))
  if env_var_value:
    if check_filepath:
      if os.path.exists(env_var_value):
        return env_var_value
      raise Exception('File {} doesn\'t exist.'.format(env_var_value))
    return env_var_value
  raise Exception('Environment variable {} not exported'.format(env_var_name))

if __name__ == "__main__":

  logging.getLogger().setLevel(logging.INFO)

  # Run using environment variables or not
  if os.getenv('USE_ENV'):
    source_uri = check_env('SOURCE_URI')
    output_uri = os.getenv('OUTPUT_URI', False)
    show_output = True if os.getenv('SHOW_OUTPUT') else False

    darknet_cfg_path = check_env('DARKNET_CFG_PATH', check_filepath=True)
    darknet_weigths_path = check_env('DARKNET_WEIGHTS_PATH', check_filepath=True)
    darknet_coco_data_path = check_env('DARKNET_COCO_DATA_PATH', check_filepath=True)

    stream_source = os.getenv('STREAM_SOURCE')

  if stream_source:
    detect_video_stream(source_uri=source_uri, output_uri=output_uri,
      darknet_weigths_path=darknet_weigths_path, darknet_cfg_path=darknet_cfg_path,
      darknet_coco_data_path=darknet_coco_data_path, show_output=show_output)
  else:
    for image_path in glob.glob(source_uri):
      detect_on_image(source_uri=image_path, output_uri=output_uri,
        darknet_weigths_path=darknet_weigths_path, darknet_cfg_path=darknet_cfg_path,
        darknet_coco_data_path=darknet_coco_data_path, show_output=show_output)
