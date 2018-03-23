function valList = timeFold(Y, X, t, n)
%Select portions of data by time, starting at the earliest

%Number of points to validate on
n_val = floor(size(t,1)/n);

%Get ordered list based on datetime column
[~, ordert] = sort(t);

%Initialize list of outputs where the number = the fold to use that as validation
%(i.e. rows with valList=1 are validation for the 1st fold)valList = zeros(size(Y,1),1);

for i = 1:n
    %Starting point
    start = n_val*(i-1)+1;
    
    %Using the random list, select n_val points for validation
    valList(ordert(start:start+n_val)) = i;
end

end