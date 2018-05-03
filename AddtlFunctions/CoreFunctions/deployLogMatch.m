function [Y,X,t] = deployLogMatch(Y,X,t,settingsSet)
%Verify that data in Y and X match time ranges in the deployment log

%Get information about current pod and reference file
i = settingsSet.loops.i;
j = settingsSet.loops.j;
if ischar(settingsSet.fileList.colocation.reference.files.name)
    refFileName = settingsSet.fileList.colocation.reference.files.name;
else
    refFileName = settingsSet.fileList.colocation.reference.files.name{i};
end
podName = settingsSet.podList.podName{j};
deployLog = settingsSet.deployLog;

%Tracker in case no data is found
foundEntry = 0;

%Initialize vector for indicating whether to keep data
keep = zeros(size(X,1),1);

%Check each entry in the deployment log
for i = 1:size(deployLog,1)
    %Join the pod name and type for convenience
    deployPod = strcat(deployLog.Type{i}, deployLog.Name{i});
    
    %If the pod name and reference file name both match...
    if strcmp(deployPod,podName) && strcmp(deployLog.ReferenceFile{i}, refFileName)
        foundEntry = foundEntry+1;
        %Get T/F list of time entries within the time period indicated on this line
        withinTime = isbetween(t,deployLog.Start(i),deployLog.End(i));
        keep(withinTime) = 1;
    end
end

%Return only the values from when the pod was colocated with the specified reference file
t = t(keep==1);
Y = Y(keep==1,:);
X = X(keep==1,:);

%Throw an error for data with no matches
assert(foundEntry > 0, ['No entries in the deployment log found for ' refFileName ' and ' podName])

%Throw error if there is no overlap between data and entries in deployment log
assert(~isempty(t),['No overlap between data and entries in deployment log for ' refFileName ' and ' podName]);

end

