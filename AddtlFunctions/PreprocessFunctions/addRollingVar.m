function [X,t] = addRollingVar(X, t, ~)
%Add a rolling variance measure spanning the past 5 minutes

%Minutes to lag by
t_lag = minutes(5);

%Start by finding where to begin (at least 5 minutes in)
index = 1:length(t);
shift = min(t)+t_lag;
index(t>shift)=[];
index = max(index);

%Make empty array to input values
varArray = zeros(length(t),size(X,2));

%Loop beginning at that point
for i=(index+1):length(t)
    %Get two shifted timeseries
    t_current = t(i);
    t_earlier = t_current - t_lag;
    X_roll = table2array(X((t<t_current & t>t_earlier),:));
    for j = 1:size(X,2)
        try
            varArray(i,j) = var(X_roll(:,j));
        catch
        end
    end
end

%Assign nice variable names
varArray = array2table(varArray);
for i = 1:size(X,2)
    varArray.Properties.VariableNames{i} = [X.Properties.VariableNames{i} '_var'];
end

%Join the two arrays
X = [X varArray];

end