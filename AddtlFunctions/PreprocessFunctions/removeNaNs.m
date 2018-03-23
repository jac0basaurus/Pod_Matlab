function [X,t] = removeNaNs(X, t, settingsSet)

%Convert to table for boolean operators
tempX = table2array(X);

%Check if any values in each row are exactly -999
boolList = any(isnan(tempX),2);

%Remove those rows
X(boolList==1,:)=[];
t(boolList==1,:)=[];

end

