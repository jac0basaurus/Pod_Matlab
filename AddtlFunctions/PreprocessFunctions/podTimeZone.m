function [X,t] = podTimeZone(X, t, settingsSet)
%{
This function uses the pod inventory file to adjust for differences between
the timezone in which the pod is recording time and the reference is
reported in.  Note that this does not account for DST issues
%}

%Get the pod inventory
podInventory = settingsSet.podInventory;
%Get reference time zone
refTZ = hours(settingsSet.refTZ{1});
pName = settingsSet.currentPod;

%Loop through each line in the pod inventory
for i = 1:size(podInventory,2)
    %Get the name of the pod from the inventory file
    try
        invName = podInventory{1,i}{1,3};
    catch err
        warning('Issues reading pod inventory file issues, may indicate malformed lines in the csv file');
        invName = 'NA';
    end
    
    %Check if the pod name for this file matches the entry in the pod inventory file
    %NOTE: if there are multiple lines in the pod inventory for one pod, this will probably break or mess up your time stamps
    if strcmpi(pName,invName)
        %The second column of the pod inventory file has the timezone in which the pod was programmed
        podTZ = hours(podInventory{1,i}{1,2});
        
        %Adjust the timezone of the pod to match the reference file
        t = t + (refTZ - podTZ);
    end%comparison of pod name and inventory row
    clear invName
    
end%loop through pod inventory lines
end%function