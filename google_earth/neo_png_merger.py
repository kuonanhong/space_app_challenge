#!/usr/bin/python
"""

This tool reads in a folder containing PNG files whose file names indicating the time span.
Then, it generates a KML file using PNG files as the ground overlays with corresponding
time spans.
Finally, it packs all needed files into a KMZ file.

"""

# Typical KML file format.
"""

<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Document><LookAt id="lookat_id"><longitude>0.0</longitude><latitude>0.0</latitude><range>1.2770075427617017E7</range><tilt>0.0000</tilt><heading>0.0000</heading></LookAt>


<GroundOverlay><name>MYDAL2_E_AER_OD_2002-07-04</name>

<TimeSpan>
        <begin>2002-07-04</begin>
        <end>2002-07-12</end>
</TimeSpan>

<Icon><href>MYDAL2_E_AER_OD_2002-07-04.png</href></Icon>
<LatLonBox id="lookat_id"><north>90.0</north><east>180.0</east><south>-90.0</south><west>-180.0</west></LatLonBox></GroundOverlay>


<GroundOverlay><name>MYDAL2_E_AER_OD_2002-07-12</name>

<TimeSpan>
        <begin>2002-07-12</begin>
        <end>2002-07-20</end>
</TimeSpan>

<Icon><href>MYDAL2_E_AER_OD_2002-07-12.png</href></Icon>
<LatLonBox id="lookat_id"><north>90.0</north><east>180.0</east><south>-90.0</south><west>-180.0</west></LatLonBox></GroundOverlay>

</Document></kml>

"""

import argparse
import datetime
import glob
import logging
import os
import re
import subprocess

def get_date_from_file_name(name):
  find = re.findall(r'(?i)(\d{4}-\d{2}-\d{2}).png$', name)
  if find:
    date_string = find[0]
  else:
    raise ValueError('Name format not correct: %s', name)

  dt = datetime.datetime.strptime(date_string, '%Y-%m-%d')
  return dt


def get_date_string(date):
  return date.strftime('%Y-%m-%d')


class KML(object):
  HEADER = '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Document><LookAt id="lookat_id"><longitude>0.0</longitude><latitude>0.0</latitude><range>1.2770075427617017E7</range><tilt>0.0000</tilt><heading>0.0000</heading></LookAt>'
  END = '</Document></kml>'

  def __init__(self, png_files, args):
    self.args = args
    self.png_files = png_files
    self.ground_overlays = []
    self.get_ground_overlays()
    self.set_time_end_using_next_overlay()

  def get_ground_overlays(self):
    opacity = None
    if self.args.opacity:
      opacity = self.args.opacity

    for png_file in self.png_files:
      png_file_name = os.path.basename(png_file)
      ground_overlay = GroundOverlay(png_file_name, opacity)
      self.ground_overlays.append(ground_overlay)

  def set_time_end_using_next_overlay(self):
    for idx in xrange(len(self.ground_overlays) - 1):
      g = self.ground_overlays[idx]
      next_g = self.ground_overlays[idx + 1]
      g.time_end = next_g.time_start

  def print_kml(self):
    ret = ''
    ret += self.HEADER
    ret += '\n\n'

    for g in self.ground_overlays:
      ret += g.get_ground_overlay_element()

    ret += self.END

    return ret


class GroundOverlay(object):
  LATLONBOX = '<LatLonBox id="lookat_id"><north>90.0</north><east>180.0</east><south>-90.0</south><west>-180.0</west></LatLonBox>'

  def __init__(self, file_name, opacity):
    self.file_name = file_name
    self.time_start = get_date_from_file_name(file_name)
    self.time_end = None
    self.opacity = opacity

  def get_time_span_element(self):
    ret = '<TimeSpan>\n'
    ret += '<begin>%s</begin>\n' % get_date_string(self.time_start)
    # Omit end for the last overlay.
    if self.time_end:
      ret += '<end>%s</end>\n' % get_date_string(self.time_end)
    ret += '</TimeSpan>\n'
    return ret

  def get_opacity_element(self):
    if not self.opacity:
      return
    ret = '<color>'
    ret += '%sffffff' % self.opacity
    ret += '</color>\n'
    return ret

  def get_name_element(self):
    pattern = '<name>%s</name>'
    # Omit ".png".
    return pattern % self.file_name[:-4] + '\n'

  def get_icon_element(self):
    pattern = '<Icon><href>%s</href></Icon>'
    return pattern % self.file_name + '\n'

  def get_latlonbox_element(self):
    return self.LATLONBOX + '\n'

  def get_ground_overlay_element(self):
    ret = '<GroundOverlay>' + '\n'
    ret += self.get_name_element()
    ret += self.get_time_span_element()
    ret += self.get_opacity_element()
    ret += self.get_icon_element()
    ret += self.get_latlonbox_element()
    ret += '</GroundOverlay>'
    return ret + '\n\n'


def parse_args():
  parser = argparse.ArgumentParser(
      description='Merge png files in a folder into a KMZ file.')

  parser.add_argument('-d', '--debug', action='store_true',
                      help='Pring debug messages')
  # Args for input.
  parser.add_argument('-i', '--input_folder', required=True,
                      help='Folder containing png files.')
  # Args for opacity.
  parser.add_argument('-p', '--opacity', type=str,
                      help='Opacity, a string 00 to ff')
  # Args for result.
  parser.add_argument('-o', '--out_kml_name', required=True,
                      help='Name for output kml and kmz file.')

  return parser.parse_args()


def get_png_files_in_cwd():
  """Gets files in a directory."""
  files = glob.glob('*.png')
  files += glob.glob('*.PNG')
  return sorted(files)


def run_command(cmd):
  logging.info('Running cmd: %s', cmd)
  subprocess.check_call(cmd)


def run_app():
  args = parse_args()

  kml_file = '%s.kml' % args.out_kml_name
  kmz_file = '%s.kmz' % args.out_kml_name

  if os.path.exists(kml_file):
    os.remove(kml_file)
  if os.path.exists(kmz_file):
    os.remove(kmz_file)

  initial_directory = os.getcwd()

  # change directory to input folder
  os.chdir(args.input_folder)

  level = logging.DEBUG if args.debug else logging.INFO
  logging.basicConfig(level=level)

  png_files = get_png_files_in_cwd()
  logging.debug('Found files %s', png_files)

  kml = KML(png_files, args)

  kml_file = '%s.kml' % args.out_kml_name
  kmz_file = '%s.kmz' % args.out_kml_name

  with open(kml_file, 'w') as f:
    f.write(kml.print_kml())

  cmd = ['zip', kmz_file, kml_file] + png_files
  run_command(cmd)

  # Move output from input folder to initial directory.
  cmd = ['mv', kml_file, kmz_file, initial_directory]
  run_command(cmd)


if __name__ == '__main__':
  run_app()
