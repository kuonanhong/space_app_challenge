# -*- coding: utf-8
from pyhdf.SD import SD, SDC

file_name = 'MISR_AM1_CGAS_DEC_2016_F15_0031.hdf'
file = SD(file_name, SDC.READ)

print file.info()

datasets_dic = file.datasets()

for idx,sds in enumerate(datasets_dic.keys()):
    print idx,sds

sds_obj = file.select('Optical depth standard deviation') # select sds

data = sds_obj.get() # get sds data
print data
