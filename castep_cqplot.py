import pandas as pd
import matplotlib.pyplot as plt
import os

os.system('./castep_read.sh')
raw = pd.read_table("read.txt", sep='\s+', names = ['Species', 'Ion', 'sCq', 'sAsym', '|'])
n = raw.shape[0] # Number of ion in the system
# elem = []
for i in range(1,n-1):
    if raw.isin(['--']).get("Species")[i]: # Break when reach one set of Data Aquisition
        L = i - 1
        break
#     if raw.get("Species")[i] not in elem:
#         elem.append(raw.get("Species")[i])

data = pd.DataFrame()
dataAsym = pd.DataFrame()

i = 1
count = 0
while i < n:
    temp = raw.iloc[i:i+L,0:4] # index, Species, Ion, sCq, sAsym
    temp.insert(4, "Cq", temp.loc[:,"sCq"].astype(float))
    temp.insert(5, "Asym", temp.loc[:,"sAsym"].astype(float))
    avg = temp.groupby("Species")["Cq"].mean().abs()
    avgAsym = temp.groupby("Species")["Asym"].mean()
    data.insert(count,count, avg) # x axis is just from 0 to count. Have no plan to update it because we have series of convergence
    dataAsym.insert(count,count, avgAsym)
    count = count + 1
    i = i + L + 2

data = data.T
dataAsym = dataAsym.T
data.to_csv('Cq.csv', index=False) 
plt.figure()
data.plot()
plt.savefig('plotCq.png')
dataAsym.plot()
plt.savefig('plotAsym.png')
print(data)

