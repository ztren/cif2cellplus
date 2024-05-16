#!/usr/bin/env python

import os
import subprocess
import shutil

path = "./cifs/"
files= os.listdir(path)

AutoCell = True # True if add k-points spacing and stuff to cell file
Convergence = True # True if wish to do convergence test
MoveCell = False # (Central Metal) Moving experiment
for f in files:
    if f != 'Please_Put_Cifs_Here':
        filedir = f[:-4]
        filename = filedir+'/'+filedir
        if not os.path.isdir(filedir):
            os.mkdir('./'+filedir) #otherwise FileExistsError
        shutil.copyfile(path+f,filename+'.cif')
        shutil.copyfile('default/default.param',filename+'.param')
        shutil.copyfile('default/main_job_geoopt.sh',filedir+'/main_job_geoopt.sh')
        shutil.copyfile('default/main_job_nmr.sh',filedir+'/main_job_nmr.sh')
        if Convergence:
            shutil.copyfile('default/main_job_energy.sh',filedir+'/main_job_energy.sh')
            shutil.copyfile('default/main_job_kpoint.sh',filedir+'/main_job_kpoint.sh')
        if MoveCell:
            shutil.copyfile('default/main_job_movecell.sh',filedir+'/main_job_movecell.sh')
        try:
            subprocess.run('cif2cell -p castep -f '+filename+'.cif -o '+filename+'.cell',shell=True,check=True)
            if AutoCell:
                os.rename(filename+'.cell',filename+'.temp')
                subprocess.run(['cat default/default.cell '+filename+'.temp > '+filename+'.cell'],shell=True) 
                os.remove(filename+'.temp')
        except: 
            print('cif2cell error. Might be because the cif file is not supported by cif2cell.')
        subprocess.run(["sed -i ''s/#DONT_MODIFY_THIS/"+filedir+"/'' "+filedir+"/main_job*.sh"],shell=True)
