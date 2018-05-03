function convertPodDatatoMat(settingsSet)
%{
Loop through all files in the list, check if a mat file exists, and create
one if there isn't one already 
%}
if ~isempty(settingsSet.fileList.colocation.pods.files)
    disp('-Converting colocated pod files...')
    readFiles(settingsSet.fileList.colocation.pods,settingsSet.podList);
end

%Convert field (not colocated) pod files to .mat
if ~isempty(settingsSet.fileList.field.pods.files)
    disp('-Converting field pod files...')
    readFiles(settingsSet.fileList.field.pods,settingsSet.podList);
end

end% function

function readFiles(filesStruct,podList)
%{
This sub function uses information from the Pod List to help convert raw
Pod files into mat files for easier analysis
%}
for i = 1:size(filesStruct.files.bytes,1)
    
    %Indexing is weird if only one file, so must handle separately
    if length(filesStruct.files.bytes)==1
        fileName = {filesStruct.files.name};
    else
        fileName = filesStruct.files.name(i);
    end
    
    %Get the file directory and then assemble with the name to get the path
    fileDir = filesStruct.dir;
    filePath = fullfile(fileDir,fileName);
    
    %See if an equivalent mat file exists
    matFilePath = strrep(filePath,'.txt','.mat');
    matFilePath = strrep(matFilePath,'.TXT','.mat');
    matFilePath = strrep(matFilePath,'.csv','.mat');
    matFilePath = strrep(matFilePath,'.CSV','.mat');
    
    %Convert to character array for functionality
    matFilePath = char(matFilePath);
    filePath = char(filePath);
    
    %% Convert the file if it has not already been converted (the .mat file doesn't exist)
    if exist(matFilePath, 'file') ~= 2
        fprintf('No mat file, reading plain text file for %s ...\n',char(fileName));
        
        %Get pod name for comparison with pod list
        podName = [filesStruct.files.podType{i} filesStruct.files.podName{i}];
        
        %Find the entry in the pod list corresponding to the current pod
        %file being imported
        for j = 1:size(podList,1)
            if all(podList.podName{j}==podName)
                VarNames = podList.VarNames{j};
                VarTypes = podList.VarTypes{j};
                %VarTypes = strjoin(VarTypes,'');
                numVars = length(VarNames);
            end%if
        end
        assert(exist('VarNames','var')==1,['No inventory entry was located for this pod: ' podName]);
        
        %Get whether to try to read a header line for variable names
        hasHeaders = filesStruct.files.hasHeaders(i);
        
        %Create appropriate import options
        opts = detectImportOptions(filePath,'NumHeaderLines',hasHeaders,...
            'NumVariables',numVars, 'Delimiter',',','FileType','text');
        opts.ImportErrorRule = 'omitrow';
        opts.ConsecutiveDelimitersRule = 'split';
        opts=setvartype(opts,VarTypes);
        
        %Read in the data
        %rawData = readtable(filePath,'ReadVariableNames',logical(hasHeaders),'Format',VarTypes,'Delimiter',',');
        rawData = readtable(filePath,opts);
        
        %Assign variable names from pod inventory sheet
        rawData.Properties.VariableNames = VarNames;
        
        %Save the file and then clear the variable for next loop
        save(matFilePath, 'rawData');
        clear rawData;
    end% if statement that checks whether to make a new mat file
end% for look that goes through each file
end