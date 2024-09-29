#!/usr/bin/env python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os
# from math import sqrt,ceil

while 1:
  try: 
    nu = int(input("The numbers of unit in the system: "))
    break
  except: pass
fi = input("Filename: (default: *.castep)")
if fi == '': 
  fi = '*.castep'
elif fi[-7:] != ".castep":
  fi = fi + ".castep"
try: os.mkdir('plots')
except: pass
os.system(f'grep "Cq(MHz)" {fi} -A {nu} | sed "s/|//" > plots/read.txt') # read the castep file
if (os.system('grep -q "Aniso" plots/read.txt') != 0): # read if it's EFG or NMR
  raw = pd.read_table("plots/read.txt", sep='\s+', names = ['Species', 'Ion', 'Cq', 'asym', '|'])
  pobject = ['Cq', 'asym']
else:
  raw = pd.read_table("plots/read.txt", sep='\s+', names = ['Species', 'Ion', 'iso', 'aniso', 'asym', 'Cq', 'Eta', '|'])
  pobject = ['iso', 'aniso', 'asym', 'Cq', 'Eta']

while 1: # Choose things to plot
  try:
    nloop = input(f'(1-{len(pobject)}) for {pobject}, 0 for everything, default: 1\nPlease input: ')
    if nloop == '': nloop = 0
    else:
      nloop = int(nloop)
      if nloop > len(pobject): raise
      else: nloop = nloop - 1
    if nloop != -1: pobject = [pobject[nloop]]
    break
  except: pass

n = raw.shape[0] # Number of ion in the whole calculation
species = []
for i in range(1,1+nu):
    if raw.get("Species")[i] not in species:
        species.append(raw.get("Species")[i])

while 1: # Choose Atom to plot (Man It's 4D already. But MAYBE, it's possible)
  try:
    nSpecies = input(f'Please choose among {species}) for Plotting (Default: Ti): ')
    if nSpecies == '': nSpecies = 'Ti'
    elif not nSpecies in species: raise
    break
  except: 
    print(f'{nSpecies} is not in Species list. Please input another one.')
    pass
fig = plt.figure()

for param in pobject:
  data = pd.DataFrame()
  i = 1
  count = 0
  while i < n:
      temp = raw.iloc[i:i+nu,0:-1]
      temp[param] = pd.to_numeric(temp[param], errors='coerce')
      temp.insert(0, "Spion", temp.loc[:,"Species"]+'-'+temp.loc[:,"Ion"])
      avg = temp.groupby("Spion")[param].mean()
      data.insert(count,count, avg) # x axis is just from 0 to count. Have no plan to update it because we have series of convergence
      count = count + 1
      i = i + nu + 2

  data = data.T
  # data.to_csv(f'plots/{param}.csv', index=False)

  j = 1

  # fig = plt.figure()
  # ax = fig.add_subplot(111, projection="3d")
  for i in [nSpecies]:
    # plt.subplot(ceil(sqrt(len(species))), ceil(sqrt(len(species))), j, projection="3d")
    for Index in range(nu):
        try:
            linDat = np.array(list(data[i + '-' + str(Index+1)]))
            DF = pd.DataFrame(linDat)
            DF.to_csv(f"plots/Data{Index}.csv", header=False)
            print('CSV generated. Please proceed to MATLAB to visualize the plot.')
            # # for tmp in range(16**3-2935):
            # #     linDat = np.append(linDat,0)
            # colors = (linDat - linDat.min()) / (linDat.max() - linDat.min())
            # linDat = np.reshape(linDat, (16,16,16))
            # colors = np.reshape(colors, (16,16,16))
            # X, Y, Z = np.mgrid[0:16:1, 0:16:1, 0:16:1]
            # scatter = ax.scatter(X, Y, Z, c=colors, cmap=plt.cm.cool, s=1)
            # fig.colorbar(scatter, label="?")
        except:
            pass
    # Legend = []
    # for t in range(1,Index):
    #     Legend.append(i + '-' + str(t))
    # plt.legend(Legend)
    j += 1

  # plt.show()
  # plt.savefig(f'plots/{param}plot.png')
  # plt.close()
# print(data)