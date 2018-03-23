function [X,t] = makePCs(X, t, settingsSet)
%{
This function normalizes X and then changes your X matrix into principal
components for use in later regressions.  It does not modify the timeseries
vector, so this should be added to the X matrix before applying this
function if time should be included as a variable in the PCA
%}

%Check for existing PCA for this pod
filename = [settingsSet.currentPod 'PCAsave.mat'];
regPath = fullfile(settingsSet.outpath,filename);
    
%If PCA has already been computed for this pod, can skip the SVD, which can be computationally expensive
if exist(regPath,'file')==2
    %Load the previous analysis
    PCAIn = load(regPath);
    
    %Extract important values
    PCA = PCAIn.PCA;
    U = PCA.U;
    keepPCs = PCA.keep;
    
    %Convert X to matrix
    X = table2array(X);
    
    %Calculate the principal components
    pcs = (U' * X')';
    
else %If there is no PCA file in the current output folder
    %Get the variable names for reporting errors
    varNames = X.Properties.VariableNames;
    
    %Convert X to matrix
    X = table2array(X);
    
    %Create matrix to hold normalized values
    normX = X;
    varMeanMat = zeros(size(X,2),2);
    
    %Loop through each column in X and normalize it
    for i = 1:size(X,2)
        
        %Analyze each column separately
        tempX = X(:,i);
        fprintf('Normalizing column %s \n',varNames{i});
        
        try
            %Calculate the mean and std deviation
            meanx = mean(tempX,'omitnan');
            stdx = std(tempX,'omitnan');
            
            %Normalize that array
            tempX = (tempX-meanx)/stdx;
            
            %Store mean and standard deviation for use later
            varMeanMat(i,1) = meanx;
            varMeanMat(i,2) = stdx;
        catch err
            warning('Could not normalize column %s',varNames{i});
        end
        
        %Assign into the normalized X matrix
        normX(:,i) = tempX;
        
        clear tempX meanx stdx
    end %loop normalizing each column of X
    
    %Get the covariance matrix
    covX = cov(normX);
    
    %Perform singular value decomposition
    [U, S, ~] = svd(covX);
    
    %Get the eigen values
    lambdas = S / sum(S);
    
    %Plot lambdas to decide how many PCs to keep
    figure('Position',[100 100 400 300]);
    labs = 1:length(S);
    scatter(labs,lambdas);
    line(labs,lambdas);
    xlabel('PC #');
    ylabel('Variance explained');
    
    %Calculate the principal components
    pcs = (U' * X')';
    
    %Plot the PCs
    figure('Position',[400 100 400 200*size(pcs,2)]);
    xpoints = 1:size(pcs,1);
    for j = 1:size(pcs,2)
        subplot(size(pcs,2),1,j);
        plot(xpoints,pcs(:,j));
        title(['PC #' num2str(j)])
    end
        
    %Allow the user to determine how many PCs they would like to keep
    keepPCs = input('How many PCs would you like to use?   ');
    
    %Make structure with important PC info for applying to future data
    PCA.U = U;
    PCA.S = S;
    PCA.scale = varMeanMat;
    PCA.keep = keepPCs;
    
    %Save out PCA info for applying to future data
    save(char(regPath),'PCA');
    
end %If statement that tries to load the SVD from a previous run

%Assignment of X
X = pcs(:,1:keepPCs);
X = array2table(X);

end %Function





