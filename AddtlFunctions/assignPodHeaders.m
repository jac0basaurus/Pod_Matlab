function filesStruct = assignPodHeaders(filesStruct,podInventory)
%{
This function uses the pod inventory to attempt to assign headers to mat
files that were generated from pod files
%}

files2remove = zeros(length(filesStruct.files.bytes),1);

%Loop through each file and compare the pod name to a name in the podInventory
for i = 1:length(filesStruct.files.bytes)
    %Get file information to check if the .mat file exists
    filePath = fullfile(filesStruct.files.folder{i}, filesStruct.files.name{i});
    filePath = strrep(filePath,'.txt','.mat');
    filePath = strrep(filePath,'.TXT','.mat');
    filePath = strrep(filePath,'.csv','.mat');
    filePath = strrep(filePath,'.CSV','.mat');
    
    if exist(strrep(filePath,'.txt','.mat'),'file')==2  %Check that the mat file exists
        
        % Get the full pod name for that file
        pName = [filesStruct.files.podType{i} filesStruct.files.podName{i}];
        
        %Loop through each line in the pod inventory
        for ii = 1:length(podInventory)
            %Get the name of the pod from the inventory file
            try
                invName = podInventory{1,ii}{1,3};
            catch err
                warning('Reading pod inventory issues, may indicate malformed lines in the csv file');
                invName = 'NA';
            end
            
            %Check if the pod name for this file matches the entry in the pod inventory file
            %NOTE: if there are multiple lines in the pod inventory for one pod, this will probably break or trim a lot of your data
            if strcmpi(pName,invName)
                %Load the file
                filePath = char(filePath);
                load(filePath,'rawData'); %Read the mat file
                
                %Get the variable names from the loaded file
                existingVarNames=strjoin(rawData.Properties.VariableNames);
                %And the variable names from the pod inventory
                newVarNames=strjoin(podInventory{1,ii}(1,4:end));
                
                %If the names of the pods match...
                if ~strcmp(existingVarNames,newVarNames)
                    try%catching errors assigning variable names
                        %Handle differences in # of columns by chopping off columns that don't match
                        if size(rawData,2)>length({podInventory{1,ii}{1,4:end}})
                            rawData=rawData(:,1:length({podInventory{1,ii}{1,4:end}}));
                            warning('Number of columns imported from %s was longer than number of variables in the pod inventory.\n Data was pruned and analysis will continue.',filesStruct.files.name{i});
                            rawData.Properties.VariableNames = {podInventory{1,ii}{1,4:end}}; %Assign the headers based on the pod inventory file
                            save(filePath,'rawData'); %Re-save the mat file
                        elseif size(rawData,2)<length({podInventory{1,ii}{1,4:end}})
                            warning('Number of columns imported from %s was shorter than number of variables in the pod inventory.\n Data was pruned and analysis will continue.',filesStruct.files.name{i});
                            rawData.Properties.VariableNames = {podInventory{1,ii}{1,4:size(rawData,2)+3}}; %Assign the headers based on the pod inventory file
                            save(filePath,'rawData'); %Re-save the mat file
                        else%If number of columns match
                            rawData.Properties.VariableNames = {podInventory{1,ii}{1,4:end}}; %Assign the headers based on the pod inventory file
                            save(filePath,'rawData'); %Re-save the mat file
                        end
                    catch err
                        files2remove(i)=1;
                        warning('Error assigning headers to %s. \n This file will be removed from analysis.',filesStruct.files.name{i});
                    end
                end%comparison of variable names (to save time by avoiding re-saving)
            end%comparison of pod name and inventory row
            clear invName
        end%loop through pod inventory lines
    end%if statement checking if mat file exists
    clear filePath
end%loop through all files

%Remove garbage files
if any(files2remove)
    filesStruct.files(files2remove,:)=[];
end

end%function

