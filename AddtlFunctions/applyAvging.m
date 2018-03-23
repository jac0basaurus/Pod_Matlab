function [X, t] = applyAvging(X, t, settingsSet)

%Use median or mean sensor values - 1=median, 0=mean
alignMethod = settingsSet.groupMethod;

%Creates function that calculates the median or mean value in a group, omitting NaN values
switch alignMethod
    case 0; alignFunc = @(x)(median(x,'omitnan'));  
    case 1; alignFunc = @(x)(mean(x,'omitnan'));
end

%Time in seconds to group data by for analysis
alignTime = settingsSet.timeAvg*60; 

%Create list of timestamps for aligning X
tAlign = posixtime(t);
tAlign = floor(tAlign/alignTime)*alignTime;

%Create a grouping based on those timestamps
G=findgroups(tAlign);

%Initialize a temporary matrix for values
tempMat = X(1:max(G),:);

%Use the align method function to avereage/median values in each column of X
for i=1:size(X,2)
    %Apply the averaging function selected to each column
    tempArray = splitapply(alignFunc,X(:,i),G);
    tempMat(:,i) = array2table(tempArray);
    clear tempArray
end


%Assign values to the beginning of the window (for aligning with pre-averaged data)
tempTime = splitapply(@min,tAlign,G);
tempTime = datetime(tempTime,'ConvertFrom','posixtime');        

%Reassign the values for output
X = tempMat;

%Return the timestamps at the beginning of each averaging period
t = tempTime;

end

