#!/usr/bin/env python

import os
import shutil

path = "./cifs/"
files= os.listdir(path)

AutoCell = True # True if add k-points spacing and stuff to cell file
for f in files:
    filedir = f[:-4]
    filename = filedir+'/'+filedir
    if not os.path.isdir(filedir):
        os.mkdir('./'+filedir) #otherwise FileExistsError
    shutil.copyfile(path+f,filename+'.cif')
    shutil.copyfile('default/default.param',filename+'.param')
    shutil.copyfile('default/main_job.sh',filedir+'/main_job.sh')
    os.system('cif2cell -p castep -f '+filename+'.cif -o '+filename+'.cell')
    os.system('sed -i ''s/#DONT_MODIFY_THIS/'+filedir+'/'' '+filedir+'/main_job.sh')
    if AutoCell:
        os.rename(filename+'.cell',filename+'.temp')
        os.system('cat default/default.cell '+filename+'.temp > '+filename+'.cell') 
        os.remove(filename+'.temp')
