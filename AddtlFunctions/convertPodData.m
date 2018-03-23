function convertPodData(fileList)

%Convert colocated pod files
if ~isempty(fileList.colocation.pods.files)
    disp('Loading colocated pod files...')
    convertData(fileList.colocation.pods);
end

%Convert field pod files
if ~isempty(fileList.field.pods.files)
    disp('Loading field pod files...')
    convertData(fileList.field.pods);
end

%Convert colocated reference files
if ~isempty(fileList.colocation.reference.files)
    disp('Loading colocated reference files...')
    convertData(fileList.colocation.reference);
end

end

function convertData(filesStruct)
for i = 1:length(filesStruct.files.bytes)
    
    %Indexing is weird if only one file
    if(length(filesStruct.files.bytes)==1)
        fileName = filesStruct.files.name;
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
    
    %Convert the file if it has not already been converted
    if exist(matFilePath, 'file') ~= 2
        fprintf('No mat file, reading plain text file for %s ...\n',fileName);
        
        %Get import options object and modify to omit rows with errors
        opts = detectImportOptions(filePath);
        opts.ImportErrorRule = 'omitrow';
        
        %Y-Pods and U-Pods have different formatting
        if contains(fileName,'YPOD') 
            rawData = readtable(filePath, opts, 'ReadVariableNames',false);
        else
            rawData = readtable(filePath, opts, 'ReadVariableNames',true);
        end
        
        %Save the file and then clear the variable for next loop
        save(matFilePath, 'rawData');
        clear rawData;
    end
end
end

