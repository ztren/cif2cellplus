import pandas as pd
import matplotlib.pyplot as plt
import os

os.system('./castep_read.sh')
raw = pd.read_table("read.txt", sep='\s+', names = ['Species', 'Ion', 'siso', 'aniso', 'asym', 'Cq', 'Eta', '|'])
n = raw.shape[0] # Number of ion in the system
# elem = []
for i in range(1,n-1):
    if raw.isin(['--']).get("Species")[i]: # Break when reach one set of Data Aquisition
        L = i - 1
        break
#     if raw.get("Species")[i] not in elem:
#         elem.append(raw.get("Species")[i])

data = pd.DataFrame()

i = 1
count = 0
while i < n:
    temp = raw.iloc[i:i+L,0:3]
    temp.insert(3, "iso", temp.loc[:,"siso"].astype(float))
    avg = temp.groupby("Species")["iso"].mean()
    data.insert(count,count, avg) # x axis is just from 0 to count. Have no plan to update it because we have series of convergence
    count = count + 1
    i = i + L + 2

data = data.T
plt.figure()
data.plot()
plt.savefig('plot.png')
# print(data)


    