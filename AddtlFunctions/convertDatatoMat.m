function convertDatatoMat(filesStruct)

%Loop through all files in the list, check if a mat file exists, and create
%one if there is none already

for i = 1:length(filesStruct.files.bytes)
    
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
    
    %Convert the file if it has not already been converted (the .mat file doesn't exist)
    if exist(matFilePath, 'file') ~= 2
        fprintf('No mat file, reading plain text file for %s ...\n',char(fileName));
        
        %Get import options object and modify to omit rows with errors
        opts = detectImportOptions(filePath);
        opts.ImportErrorRule = 'fill';
        if ~cellfun(@isempty,regexpi(fileName,'txt'))
            opts.Delimiter = ',';
        end
        
        %Get whether to try to read a header line for variable names
        hasHeaders = filesStruct.files.hasHeaders(i);
        
        %Read in the data
        rawData = readtable(filePath, opts, 'ReadVariableNames',logical(hasHeaders));
        
        %Save the file and then clear the variable for next loop
        save(matFilePath, 'rawData');
        clear rawData;
    end% if statement that checks whether to make a new mat file
end% for look that goes through each file
end% function

