try
    Rawdata = readtable("Data1.csv");
catch
    error("File not found. Did you put it in Data/Filename?")
end

Rawdata.Properties.VariableNames = ["Index" , "Data"];
Data = reshape(Rawdata{:, "Data"},[16 16 16]);

x = 0:1:15;
y = 0:1:15;
z = 0:1:15;

xslice = [7 15];                              
yslice = 15;
zslice = ([0 10]);

slice(x, y, z, abs(Data), xslice, yslice, zslice)
colorbar;