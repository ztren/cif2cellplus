#!/usr/bin/env python

import os
import subprocess
import shutil

path = "./cifs/"
files = os.listdir(path)
filetype = 'a'
while not (filetype.lower() in ['y','n','']):
    filetype = input('Need cif2cell conversion? (y/n, default: y)')

AutoCell = True # True if add k-points spacing and stuff to cell file
Convergence = False # True if wish to do convergence test
MoveCell = False # (Central Metal) Moving experiment
# ra = open("runall.sh", "w") # WIP, moving the files automatically?
# ra.write("")
# ra.close()
for f in files:
    if f != 'Please_Put_Cifs_Here':
        if (filetype != 'n'):
            filedir = f[:-4]
        else: 
            filedir = f[:-5]
        filename = filedir+'/'+filedir
        if not os.path.isdir(filedir):
            os.mkdir('./'+filedir) #otherwise FileExistsError
        shutil.copyfile('default/default.param',filename+'.param')
        shutil.copyfile('default/main_job.sh',filedir+'/main_job.sh')
        shutil.copyfile('default/main_job_nmr.sh',filedir+'/main_job_nmr.sh')
        if Convergence:
            shutil.copyfile('default/main_job_energy.sh',filedir+'/main_job_energy.sh')
            shutil.copyfile('default/main_job_kpoint.sh',filedir+'/main_job_kpoint.sh')
        if MoveCell:
            shutil.copyfile('default/main_job_movecell.sh',filedir+'/main_job_movecell.sh')
        if (filetype != 'n'):
            shutil.copyfile(path+f,filename+'.cif')
            try:
                subprocess.run('cif2cell -p castep -f '+filename+'.cif -o '+filename+'.cell',shell=True,check=True)
                if AutoCell:
                    os.rename(filename+'.cell',filename+'.temp')
                    subprocess.run(['cat default/default.cell '+filename+'.temp > '+filename+'.cell'],shell=True) 
                    os.remove(filename+'.temp')
            except: 
                print('cif2cell error. Might be because the cif file is not supported by cif2cell.')
        else:
            shutil.copyfile(path+f,filename+'.cell')
        subprocess.run(["sed -i ''s/#DONT_MODIFY_THIS/"+filedir+"/'' "+filedir+"/main_job*.sh"],shell=True)
        runall = open("runall.sh", "a")
        runall.write('cd '+filedir+'\nsbatch main_job.sh\ncd ..\n')
        subprocess.run(["chmod 755 runall.sh"],shell=True)
