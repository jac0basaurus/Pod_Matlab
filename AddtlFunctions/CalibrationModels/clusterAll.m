function func = clusterAll(a)
%Warning: this function uses all columns of X to cluster - this can be
%extremely computationally expensive if X has many dimensions.  Try
%applying PCA or other dimensional reduction tools before applying this
%method to a large dataset
switch a
    case 1; func = @clusterAllGen;
    case 2; func = @clusterAllApply;
end

end

%----------------------------------------------------------------------------------

function [mdl, y_hat] = clusterAllGen(Y,X,~)

%Get a matrix for functions
clusterX = table2array(X);

%Maximum number of clusters to try
nmax = 10;
%Create matrix to hold within group sum of squares values
all_wss = zeros(nmax,1);

%Plot for analysis
nwide = ceil(nmax/4);
if nmax>=4;nhigh=4;else;nhigh=nmax;end
height = 250*nhigh;
width = 400*nwide;
figure('Position',[400 100 width height]);
xpoints = 1:size(clusterX,1);
for k = 1:nmax%Include one cluster (base case)
    [groups, ~, sumd] = kmeans(clusterX,k,'Replicates',5); %Tries 5 replicates for each k to account for random initialization of centers
    
    %Calculate within groups sum of squares
    all_wss(k) = sum(sumd);
    
    %Plot for visualization
    subplot(nhigh,nwide,k);
    gscatter(xpoints,table2array(Y),groups);
    title(['K = ' num2str(k) ' WSS = ' num2str(round(all_wss(k),2))]);
    
    clear sumd
end% loop that tries different # of centers

figure;
plot(1:nmax,all_wss,'-o');
title('Clusters WSS')
xlabel('Number of Clusters')
ylabel('Within Group Sum of Squares')

%Allow the user to determine how many clusters they would like to keep
keepK = input('How many clusters would you like to use?   ');
%mdl get the cluster centers, and y_hat gets the cluster assignments for
%each row of X.  Use 10 replicates to ensure good centering of clusters
[y_hat, mdl, ~] = kmeans(clusterX,keepK,'Replicates',10); 

end


%----------------------------------------------------------------------------------

function y_hat = clusterAllApply(X,mdl,~)

%"mdl" contains the locations of each cluster center
C=mdl;
%The size of this matrix is the number of clusters
k_centers = size(C,1);
%This will give a warning that it didn't converge, which is right (we don't
%want it to iterate and find new centers, we want to assign to existing centers
[y_hat] = kmeans(table2array(X),k_centers,'MaxIter',1,'Start',C);

end