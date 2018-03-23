function [podData] = loadFieldPodData(fileList, podName)

%% Loop through list of pod files and upload ones that match the pod name
%First, get the number of files in each
nfieldFiles = length(fileList.field.pods.bytes);
%Get the directory (folder) where field pod data are stored
fileDir = fileList.field.pods.dir;

for i = 1:nfieldFiles
    
    %If there's only one file, indexing is weird
    if nfieldFiles == 1
        filePodName = fileList.field.pods.files.podName;
    else
        filePodName = fileList.field.pods.files.podName(i);
    end
    
    %Create full file path for reading file
    filePath = fullfile(fileDir,filePodName);
    
    %Load the file if the name matches
    if strcmpi(filePodName,podName)
        %Get the equivalent mat file name
        matFilePath = strrep(filePath,'.txt','.mat');
        matFilePath = strrep(matFilePath,'.TXT','.mat');
        
        temp = load(matFilePath);
        temp = temp.rawData;
    end
    
    if i==1
        podData = temp;
    else
        podData = [podData;temp];
    end
    
end



