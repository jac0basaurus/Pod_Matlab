function [X,t] = removeDST(X, t, settingsSet)
%{
This function removes an hour from timestamps that were recorded with an
instrument that observes  daylight savings time (DST) in order to allow 
matching with instruments that do not observe DST
%}

%Get the dates as a vector
assert(isdatetime(t),'Time vector is not in the datetime format!');

%Get start date of DST (second Sunday in March)
dstStart = nweekdate(2, 1, t.Year, 3,[],'datetime');

%Get end date of DST (first Sunday in November)
dstEnd = nweekdate(1, 1, t.Year, 11,[],'datetime');

%Get list of entries within daylight savings 
dlist =(t > dstStart) & (t < dstEnd);

%Check if date is during DST and then remove 1 hour if it is
t(dlist).Hour = t(dlist).Hour - 1;

end