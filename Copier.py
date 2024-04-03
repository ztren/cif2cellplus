import os
import shutil

ncount = 0
count = 0

for root, dirs, files in os.walk('source'): # Change the source as needed
    for file in files:
        if file[-4:].lower() == ".mpr":
            try:
                data = file[:-4].split('_')
                if data[0] == file[:-4]:
                    raise NameError
                else:
                    name = data[0]
                    if (len(name) > 7) | (len(name) < 6):
                        raise NameError
                int(data[-1])
            except:
                print(file + ": File name does not match the name standard.")
            finally:
                if os.stat(root + '/' + file).st_size > (1048576 * 25):
                    if os.path.exists('noisy_mpr/'+file):
                        print(file + ' exists in noisy_mpr folder. Not copying it.')
                    else:
                        shutil.copy(root+'/'+file, 'noisy_mpr/')
                        ncount = ncount + 1
                else:
                    if os.path.exists('mpr/'+file):
                        print(file + ' exists in mpr folder. Not copying it.')
                    else:
                        shutil.copy(root+'/'+file, 'mpr/')
                        count = count + 1

count = count + ncount
print("{} mpr files copied. {} noisy among them.".format(count, ncount))