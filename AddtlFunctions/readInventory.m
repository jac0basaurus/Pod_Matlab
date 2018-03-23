function podInventory = readInventory(analyzeDir)
%This function reads the deployment log for this set of data

%Fix for Windows/Mac slash differences
if ispc == 1; slash = '\'; else; slash = '/'; end

%The inventory file should be stored in a folder titled "Logs"
inventoryDir = [analyzeDir slash 'Logs'];
assert(exist(inventoryDir,'dir')~=0,'Folder for deployment log and inventory does not exist!')

%Create the full file path
filePath = fullfile(inventoryDir,'Pod Inventory.csv');
assert(exist(filePath,'file')~=0,'Pod Inventory does not exist or the name is not correct!')

%Clean up the options associated with importing the file
opts = detectImportOptions(filePath);
opts.ImportErrorRule = 'omitrow';
opts = setvaropts(opts,{'Var1'},'InputFormat','MM/dd/yyyy');

%Import the inventory file
tempInventory = readtable(filePath, opts, 'ReadVariableNames',true);

%Read that into a cell array to be able to store headers of different length
for i=1:height(tempInventory)
    inventoryLine = table2cell(tempInventory(i,:));
    podInventory{i} = inventoryLine(~cellfun('isempty',inventoryLine));
end

end