#!/usr/bin/env python

import glob


specific_system = ""
exclude=""


folders = glob.glob("../*"+specific_system+"/System/")
if exclude != "":
    for i in folders:
        if exclude in i:
            folders.remove(i)


for system in folders:
    all_file = glob.glob(system+"*.sh")
    job_name = all_file[0].split("/")[1]
    for file in all_file:
        with open('default/'+file.split("/")[-1]) as default_file:
            default_content=default_file.read()
        modified=default_content.replace("#DONT_MODIFY_THIS", job_name)
        with open(file, "w") as new_file:
            new_file.write(modified)

