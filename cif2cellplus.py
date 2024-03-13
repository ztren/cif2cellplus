#!/usr/bin/env python

import os
import subprocess
import shutil

path = "./cifs/"
files= os.listdir(path)

AutoCell = True # True if add k-points spacing and stuff to cell file
for f in files:
    if f != 'Please_Put_Cifs_Here':
        filedir = f[:-4]
        filename = filedir+'/'+filedir
        if not os.path.isdir(filedir):
            os.mkdir('./'+filedir) #otherwise FileExistsError
        shutil.copyfile(path+f,filename+'.cif')
        shutil.copyfile('default/default.param',filename+'.param')
        shutil.copyfile('default/main_job.sh',filedir+'/main_job.sh')
        try:
            subprocess.run('cif2cell -p castep -f '+filename+'.cif -o '+filename+'.cell',shell=True,check=True)
            if AutoCell:
                os.rename(filename+'.cell',filename+'.temp')
                subprocess.run(['cat default/default.cell '+filename+'.temp > '+filename+'.cell'],shell=True) 
                os.remove(filename+'.temp')
        except: 
            print('cif2cell error. Might be because the cif file is not supported by cif2cell.')
        subprocess.run(["sed -i ''s/#DONT_MODIFY_THIS/"+filedir+"/'' "+filedir+"/main_job.sh"],shell=True)
