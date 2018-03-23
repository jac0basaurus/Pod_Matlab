function [refData] = loadRefData(settingsSet, reffileName)

%Get the file path to load
direct = settingsSet.fileList.colocation.reference.dir;
filePath = char(fullfile(direct,reffileName));

%See if an equivalent mat file exists
matFilePath = strrep(filePath,'.txt','.mat');
matFilePath = strrep(matFilePath,'.TXT','.mat');
matFilePath = strrep(matFilePath,'.csv','.mat');
matFilePath = strrep(matFilePath,'.CSV','.mat');


%Verify that there is a .mat file and throw error if it doesn't exist
assert(exist(matFilePath, 'file') == 2,'Reference .mat data file not found');

%Load the data
alldata = load(matFilePath);
loadData = whos('-file',matFilePath);
refData = alldata.(loadData.name);
clear alldata1

try  %For a dataset
    headers = refData.Properties.VariableNames;
catch err  %For a table
    headers = refData(1,:);
end
    
end