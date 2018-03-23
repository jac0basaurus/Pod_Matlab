function [X,t] = rem30(X, t, settingsSet)

%Get two shifted timeseries
time1 = t(1:end-1);
time2 = t(2:end);
%Get delta time between one step to the next
deltat = time2 - time1;
%Get typical time step
typdelta = median(deltat,'omitnan');
%Find items where there was a skip in time greater than 5x the typical timing
missing = deltat>typdelta*5;
%Make list of rows to remove
remList = zeros(length(t),1);

%Only go through the rest if missing entries are detected
if any(missing)
    %Get index list for calculation
    index=1:length(t);
    index = index(missing)+1;
    
    %Remove thirty minutes after each entry
    for i = 1:length(index)
        
        %Get beginning of removal period (when data starts again after a gap)
        remstart = t(index(i));
        %Remove 30 minutes after that
        remend = remstart + minutes(30);
        
        %Remove rows within that period
        remList((t>=remstart) & (t<=remend),:)=1;
        
    end
end

%Actually remove values
X(remList==1,:) = [];
t(remList==1,:) = [];
        
end

