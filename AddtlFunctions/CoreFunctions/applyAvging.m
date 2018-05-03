function [X, t] = applyAvging(X, t, settingsSet)
%{
This function uses the averaging method (median, mean, etc) to average the
input timeseries over some interval
%}

%% Use different smoothing methods
alignMethod = settingsSet.groupMethod;

%Creates function that calculates the median or mean value in a group, omitting NaN values
switch alignMethod
    %These are references to subfunctions below.  See "splitapply"
    %documentation for information about how functions should work
    case 0; smoothFunc = @podmedian;
    case 1; smoothFunc = @podmean;
    case 2; smoothFunc = @podinterp;
    case 3; smoothFunc = @podsmooth;
end

%% Separate discontinuous windows
%Time in seconds to group data for analysis
tav = settingsSet.timeAvg*60;
%Use typical time between measurements to ID large gaps
t1 = t(2:end);
t2 = t(1:end-1);
dt = t1-t2;
clear t1 t2
dt = median(dt);
tsegs = zeros(size(t,1),1,'uint8');
seg = 1;
for i = 2:size(t,1)
    delta = t(i)-t(i-1);
    if delta > dt*5
        seg = seg+1;
    end
    tsegs(i) = seg;
end
%% Apply smoothing to each segment
for i = 1:max(tsegs)
    [X_seg,t_seg] = smoothFunc(X(tsegs==i,:),t(tsegs==i,:));
    if i==1
        X_temp=X_seg;
        t_temp=t_seg;
    else
        X_temp=[X_temp;X_seg];
        t_temp=[t_temp;t_seg];
    end
end

%% Fix time vector
%Assign values to the beginning of the window (for aligning with other averaged data)
t_temp = datetime(t_temp,'ConvertFrom','posixtime');

%Return the timestamps at the beginning of each averaging period
t = t_temp;
X = X_temp;

%% SUBFUNCTIONS BELOW
%% ------------------Median------------------
    function [X,t] = podmedian(X,t)
        %Make groups based on the time window selected
        [G,t] = podGroup(t);
        
        %Initialize a temporary matrix for values
        tempMat = X(1:max(G),:);
        %Function for median
        splitfunc = @(x)(median(x,'omitnan'));
        %Apply to each column of X
        for j=1:size(X,2)
            %Apply the averaging function selected to each column
            tempArray = splitapply(splitfunc,X(:,j),G);
            tempMat(:,j) = array2table(tempArray);
            clear tempArray
        end
        
        %Return X
        X = tempMat;
        %Return t
        t = splitapply(@min,t,G);
    end
%% ------------------Mean------------------
    function [X,t] = podmean(X,t)
        %Make groups based on the time window selected
        [G,t] = podGroup(t);
        
        %Initialize a temporary matrix for values
        tempMat = X(1:max(G),:);
        %Function for median
        splitfunc = @(x)(mean(x,'omitnan'));
        for j=1:size(X,2)
            %Apply the averaging function selected to each column
            tempArray = splitapply(splitfunc,X(:,j),G);
            tempMat(:,j) = array2table(tempArray);
            clear tempArray
        end
        
        %Return X
        X = tempMat;
        %Return t
        t = splitapply(@min,t,G);
    end
%------------------Linear Interpolation------------------
    function [X,t] = podinterp(X,t)
        % linear interpolatation on equally-spaced intervals
        tt = linspace(min(t), max(t), numel(t));
        xx = interp1(t, X, tt, 'linear');
        X = xx;
    end
%------------------LOESS------------------
    function [X,t] = podsmooth(X,t)
        %% Calculate the window to smooth on (2x averaging time b/c of weighting)
        [G,t_aligned] = podGroup(t);
        k = minutes(settingsSet.timeAvg*2)/dt;
        k = k/size(X,1);
        if k>1; k=1;end
        %% Get windows to predict on
        t_windows = splitapply(@min,t_aligned,G);
        %% Make table to hold new values
        tempMat = X(1:max(G),:);
        %% Smooth each column
        for j = 1:size(tempMat,2)
            tempX = table2array(X(:,j));
            smoothfit = fit(posixtime(t),tempX,'smoothingspline','SmoothingParam',k);
            tempX = smoothfit(t_windows);
            tempMat(:,j) = table(tempX,'VariableNames',tempMat.Properties.VariableNames(j));
        end
        %% Overwrite X
        X = tempMat;
        t = t_windows;
    end

%------------------SEGMENT GROUPING------------------
    function [G, tAlign] = podGroup(t)
        %% List of timestamps for aligning X
        tAlign = posixtime(t);
        tAlign = floor(tAlign/tav)*tav;
        
        %% Create a grouping based on those timestamps
        G = findgroups(tAlign);
        G = cast(G,'uint16');
    end

end
