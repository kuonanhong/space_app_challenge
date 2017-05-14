# 2017 Nasa Space Challenge Hackathon

## Team
### [UpperEast](https://2017.spaceappschallenge.org/challenges/warning-danger-ahead/every-cloud/teams/uppereast/project)

## Challenge
### [Every Cloud](https://2017.spaceappschallenge.org/challenges/warning-danger-ahead/every-cloud/details)
Map severe weather conditions with the presence of local atmospheric aerosols to identify potential connections!

## Solution
We created a platform to display [NEO](https://neo.sci.gsfc.nasa.gov/about/ftp.php) data and events from other sources.

## Example
- Create a KML file with event. Mark the timestamp and location of the event with an icon.
- Download aerosol optical thickness data from NEO (https://neo.sci.gsfc.nasa.gov/view.php?datasetId=MYDAL2_M_AER_OD). Use data of 8 days. Put the PNG files into a folder named OpticalThickness8Days.
- Create a KML file with aerosol optical thickness data with opacity set to 0xbf.
  ./neo_png_merger.py -i ../data/OpticalThickness8Days -o out_2011_aerosol -p bf
- Download rainfall data from NEO (https://neo.sci.gsfc.nasa.gov/view.php?datasetId=TRMM_3B43M). Choose one day out of every 8 days. Put the PNG files into a folder named E_DAYS.
- Create a KML file with rainfall data with opacity set to 0x6f.
  ./neo_png_merger.py -i ../data/E_DAYS -o out_2011_rain_8d -p 6f
- Load event.kml, out_2011_aerosol.kml and out_2011_rain_8d.kml in Google Earth.
- Set the desired time to play in timeline toolbar.
- Observe the relation between event and aerosol data and rainfall data.

## Results

For example, we can display the aerosol data, rain data and volcano eruption events during 2011 all together. The results looks like the following video.

[![Youtube Link](http://img.youtube.com/vi/u5VqfrfwxfY/0.jpg)](https://www.youtube.com/watch?v=u5VqfrfwxfY "Demo Video")

