%% USAGE NOTES
%{
This code is based on Ricardo Piedraheta's Pod_calibration_generation
code, with attemps to make it more readable and more easily modified
%}
%% Changelog
%{
    Rev     Date        Revision Notes
    V2.0	12/1/2017   Creation
%}

%% Begin Body of Code
disp('-----------------------------------------------------')
disp('-----------------Pod Analysis Code-------------------')
disp('---------------Begin Code Version 2.0----------------')
disp('-----------------------------------------------------')

%% Perform some Matlab housekeeping, initial checks, and path additions
disp('Performing system checks and housekeeping...')

%Clear variables and close ALL open figures
clear; 
close all;

%Fix for cross compatibility between OSX and Windows
if ispc == 1; slash = '\'; else; slash = '/'; end

%Add the subfolder containing other functions
addpath(genpath('Addtl Matlab Functions'));

%Check Matlab version installed is recent enough
assert(~verLessThan('matlab','9.1'),'Version of Matlab must be R2016b or newer');

%Check that requisite toolboxes needed are installed
prod_inf = ver;
assert(any(strcmp(cellstr(char(prod_inf.Name)), 'Statistics and Machine Learning Toolbox')),'Statistics Toolbox Not Installed!');
assert(any(strcmp(cellstr(char(prod_inf.Name)), 'Econometrics Toolbox')),'Econometrics Toolbox Not Installed!');
%assert(~isempty(which('fsolve')),'Function fsolve does not exist!'); % Can also just check if specific functions exist like this
clear prod_inf;


%% ------------=========Settings for analysis=========------------
%Change these values to modify the analysis as required
settingsSet.convertOnly = 0;  %Only convert (unconverted) files into .mat files
settingsSet.generateCal = 1;  %Generate a calibration - if no, will only search for existing calibrations
settingsSet.applyCal = 1;  %Apply calibrations to the pod files in the "field" folder
settingsSet.timeAvg = 1;  %Time in minutes to average data by for analysis
settingsSet.groupMethod = 1;  %Use median or mean values when grouping by timestamp - 1=median, 0=mean
settingsSet.datetimestrs = {'yyyy.MM.dd H.m.s'}; %Datetime formats to use when trying to convert non-standard import datetime strings
settingsSet.datestrings = {'yyyy.MM.dd','MM-dd-yyyy'}; %Date formats to use when trying to convert non-standard import dates
settingsSet.timestrings = {'H.m.s'}; %Date formats to use when trying to convert non-standard import times
settingsSet.outFolder=['Outputs_' datestr(now,'yymmddHHMMSS')]; %Create a unique name for the save folder

%Note: for these lists, enter function names in the order in which you'd like them to be performed (if it matters)
%Please also note that these increase multiplicatively, so selecting too many options will significantly increase analysis time
settingsSet.refGas = {'CH4'}; %Currently only partially works with one pollutant, but entered as cell array in case multiple pollutant functionality is added
settingsSet.refTZ = {-7}; %Time zone in which the reference data is reported.  Cell structure is used to allow possible extension to multiple files later
settingsSet.refPreProcess = {'removeNaNs','remove999'}; %Preprocessing functions for reference data

settingsSet.podSensors = {'Fig2600'}; %Sensors for use in calibration equations
settingsSet.envSensors = {'temperature','humidity'}; %Sensors for use in calibration equations
settingsSet.podPreProcess = {'rem30','removeNaNs','podTimeZone','TempC2K','RbyR0'}; %Preprocessing functions for pod data

settingsSet.regList = {'line3'}; %Regressions to evaluate

settingsSet.valList = {'randVal', 'timeFold'}; %Validation set selections
settingsSet.nFolds = 10; %Number of 'folds' for validation (e.g. 10 folds = 1/10 = 10% dropped for validation)
settingsSet.nFoldRep = 4; %Number of folds to actually use (will be selected in order from first to last)

settingsSet.statsList = {'myRMSE', 'myAIC'}; %Statistics to calculate - THESE ARE NOT YET WRITTEN
settingsSet.plotsList = {'timeSeries', 'acfPlot'}; %Plotting functions - NOT YET USED


%These variables are for tracking what part of the analysis is running (for functions that need this info)
settingsSet.currentPod = 'none';  %This is a dummy variable that is updated each loop to allow functions to know what pod they are analyzing (if necessary)
settingsSet.currentRegression = 'none';  %This is a dummy variable that is updated each loop to allow functions to know what regression they are analyzing (if necessary)
settingsSet.currentValidation = 'none';  %This is a dummy variable that is updated each loop to allow functions to know what validation they are analyzing (if necessary)
%-----------------------------------------------------------------


%% User selects the folder with data for analysis
%Ask user for folder path and get the directory info
disp('Select folder with dataset for analysis'); %Mostly useful for Mac users who don't get GUI labels :(

%Prompt user to select folder w/ pod data
settingsSet.analyzeDir=uigetdir(pwd,'Select folder with dataset for analysis'); 

%Throw an error if user hits "cancel"
assert(isa(settingsSet.analyzeDir,'char'), 'No data folder selected!'); 
disp(['Analyzing data in folder: ' settingsSet.analyzeDir '...'])

%% Review directories for files to analyze
%MODIFY THIS FUNCTION TO ALLOW THE LOADING OF NEW INSTRUMENT TYPES OTHER THAN U-PODS OR Y-PODS
[settingsSet.fileList, settingsSet.podList] = getFilesList(settingsSet.analyzeDir); 

%% Create a folder for outputs to be saved into
disp('Creating output folder...');
mkdir(settingsSet.analyzeDir, settingsSet.outFolder)
settingsSet.outpath = [settingsSet.analyzeDir,slash,settingsSet.outFolder]; %Store that file path for use later

%% Read Pod Inventory and Deployment Log
%The deployment log is used to determine if data should be analyzed based on the timestamp
disp('Reading deployment log...');
settingsSet.deployLog = readDeployment(settingsSet.analyzeDir);

%The pod inventory is used to assign headers and therefore determine which columns contain required information. 
%At a minimum, each pod must have an enrgy with labels 'temperature', 'humidity', 'datetime' or 'Unix time', and then containing the names of sensors entered above
disp('Reading pod inventory...');
settingsSet.podInventory = readInventory(settingsSet.analyzeDir);


%% Convert Data to .mat Files as Needed
%Import the Pod Data
disp('Converting unconverted data files to .mat files...');

%Convert colocated pod files to .mat filess
if ~isempty(settingsSet.fileList.colocation.pods.files)
    disp('-Converting colocated pod files...')
    convertDatatoMat(settingsSet.fileList.colocation.pods);
    settingsSet.fileList.colocation.pods = assignPodHeaders(settingsSet.fileList.colocation.pods,settingsSet.podInventory);
end

%Convert field (not colocated) pod files to .mat
if ~isempty(settingsSet.fileList.field.pods.files)
    disp('-Converting field pod files...')
    convertDatatoMat(settingsSet.fileList.field.pods);
    settingsSet.fileList.field.pods = assignPodHeaders(settingsSet.fileList.field.pods,settingsSet.podInventory);
end

%Convert colocated reference files to .mat
if ~isempty(settingsSet.fileList.colocation.reference.files)
    disp('-Converting colocated reference files...')
    convertDatatoMat(settingsSet.fileList.colocation.reference);
end

% End the program if user has selected that they only want to convert files
assert(~settingsSet.convertOnly , 'Finished converting files, and "Convert Only" was selected'); 

%% These are the number of reference files, pods, regressions, validations, and folds to evaluate
nref = length(settingsSet.fileList.colocation.reference.files.bytes); %Number of reference files
if ischar(settingsSet.podList)%Account for only analyzing one Pod (indexing is weird with a list of one)
    nPods=1;
else
    nPods=length(settingsSet.podList);
end
nRegs = length(settingsSet.regList); %Number of regression functions
nVal = length(settingsSet.valList); %Number of validation functions
nFolds = settingsSet.nFoldRep;  %Number of folds to evaluate
nStats = length(settingsSet.statsList); %Number of statistical functions to apply
nPlots = length(settingsSet.plotsList); %Number of plotting functions

fprintf('* Total number of loops to evaluate: %d * Beginning...\n',nref*nPods*nRegs*nVal*nFolds);

%Create empty cell matrix to store fitted models and statistics for each combination
fittedMdls = cell(nref,nPods,nRegs,nVal,nFolds); 
mdlStats = cell(nref,nPods,nRegs,nVal,nFolds,nStats);

%% --------------------------Fit Calibration Equations--------------------------
if settingsSet.generateCal
    %% --------------------------START REFERENCE FILE LOOP------------------------------
    %Note, these reference files will be analyzed independently
    %Only the time and gas concentration will be extracted from each reference file
    %If you want to combine multiple colocations into one calibration, manually append the reference files into a single file
    for i = 1:nref
        %% Load the reference file
        %Get the reference file to load
        %Indexing is weird if only one file
        if nref==1
            reffileName = settingsSet.fileList.colocation.reference.files.name;
        else
            reffileName = settingsSet.fileList.colocation.reference.files.name{i};
        end
        
        %Load the reference file into memory
        fprintf('-Importing reference file %s ...\n',reffileName);
        refData = loadRefData(settingsSet,reffileName);
        
        %Extract just the datestring and the gas of interest
        disp('-Extracting important variables from reference data');
        [Y, yt] = dataExtract(refData, settingsSet, settingsSet.refGas);
        
        %% Pre-process Reference Data (Filter, normalize, etc)
        fprintf('-Pre-processing reference file: %s ...\n',reffileName);
        for ii = 1:length(settingsSet.refPreProcess)
            %Get string representation of function - this must match the name of a filter function
            filtFunc = settingsSet.refPreProcess{ii};
            fprintf('--Applying reference preprocess function %s ...\n',filtFunc);
            %Convert this string to a function handle to feed the pod data to
            filtFunc = str2func(filtFunc);
            %Save filtered reference data into Y
            [Y,yt] = filtFunc(Y, yt, settingsSet);
            %Clear for next loop
            clear filtFunc
        end%loop for preprocessing reference data
        
        %Clear temporary variables
        clear refData
        
        %Average or find median values for the reference data
        [Y, yt] = applyAvging(Y, yt, settingsSet);
        
        
        %% --------------------------START POD LOOP------------------------------
        for j = 1:nPods
            
            fprintf('---Generating calibrations for %s ...\n',settingsSet.podList{j});
            %% Load Pod Data
            fprintf('--Loading data for %s ...\n', settingsSet.podList{j});
            podData = loadPodData(settingsSet.fileList.colocation.pods, settingsSet.podList{j});
            settingsSet.currentPod = settingsSet.podList{j}; %Keep track of pod currently being analyzed
            
            %Extract just columns needed
            disp('--Extracting important variables from pod data');
            [X, xt] = dataExtract(podData, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
            clear podData
            
            %% Pre-Process Pod Data (Filter, normalize, etc)
            disp('--Applying selected pod data preprocessing...');
            for jj = 1:length(settingsSet.podPreProcess)
                %Get string representation of function - this must match the name of a regression function
                filterFunc = settingsSet.podPreProcess{jj};
                fprintf('---Applying pod preprocess function %s ...\n',filterFunc);
                
                %Convert this string to a function handle to feed the pod data to
                filterFunc = str2func(filterFunc);
                
                %Apply the filter function
                [X, xt] = filterFunc(X, xt, settingsSet);
                
                clear filterFunc
            end%pod preprocessing loop
            
            %Average or find median values for the processed pod data
            [X, xt] = applyAvging(X, xt, settingsSet);
            
            %Match reference and Pod data based on timestamps
            disp('--Joining pod and reference data...');
            [Y, X, t] = alignRefandPod(Y,yt,X,xt,settingsSet);
            clear xt yt
            
            %Use deployment log to verify that only colocated data is included
            disp('--Checking data against the deployment log...');
            [Y, X, t] = deployLogMatch(Y,X,t,settingsSet.deployLog,settingsSet.podList{j},reffileName);
            
            %% Generate calibration using each validation/calibration dataset selections
            for k = 1:nVal
                %Get string representation of validation selection function
                valFunc = settingsSet.valList{k};
                fprintf('----Selecting validation set with function: %s ...\n',valFunc);
                settingsSet.currentValidation = settingsSet.valList{k};
                %Convert this string to a function handle for the validation selection function
                valFunc = str2func(valFunc);
                %Run that validation function and get the list of points to fit/validate on for each fold
                valList = valFunc(Y, X, t, settingsSet.nFolds);
                
                %% Fit regression equations and validate them
                for m = 1:nRegs
                    fprintf('-----Fitting regression%s ...\n',settingsSet.regList{m});
                    settingsSet.currentRegression = settingsSet.regList{m};
                    
                    %Create empty arrays to hold estimates output by model
                    Y_hat.cal = NaN(1,3);
                    Y_hat.val = NaN(1,3);
                    
                    %Get string representation of functions - this must match the name of a function saved in the directory
                    regFunc = settingsSet.regList{m};
                    %Convert this string to a function handle for the regression
                    regFunc = str2func(regFunc);
                    %Get the generation function for that regression
                    %Note that the function must be set up correctly - see existing regression functions for an example
                    calFunc = regFunc(1);
                    %Get the application function for that regression
                    valFunc = regFunc(2);
                    
                    %For each repetition (fold) of the validation selection criteria, select the data
                    for kk = 1:nFolds
                        fprintf('------on calibration/validation fold #%d ...\n',kk);
                        
                        %% Fit the selected regression
                        %Fit the regression and get the estimates and fitted coefficients
                        %Indices for the regression model array are: (i=nRef, j=nPods, m=nRegs,k=nVal,kk=nFolds)
                        disp('-------Fitting regression...');
                        [fittedMdls{i,j,m,k,kk}, Y_hat_temp] = calFunc(Y(valList~=kk,:), X(valList~=kk,:), settingsSet);
                        
                        %Store the calibrated estimates in a matrix
                        foldn = ones(length(Y_hat_temp),1)*kk; %Label for what fold this was fitted on
                        Y_hat_temp = [datenum(t(valList~=kk,:)) Y_hat_temp foldn]; %Join together as timeseries
                        if kk==1; Y_hat.cal=Y_hat_temp;else;Y_hat.cal=[Y_hat.cal;Y_hat_temp];end %Assign to the Y_hat variable
                        clear Y_hat_temp
                        
                        
                        %% Validate the fitted regression on the validation data
                        %Apply the fitted regression to the validation data
                        Y_hat_temp = valFunc(X(valList==kk,:),fittedMdls{i,j,m,k,kk},settingsSet);
                        %Store the validation estimates in a matrix
                        disp('-------Validating regression...');
                        %Store the calibrated estimates in a matrix
                        foldn = ones(length(Y_hat_temp),1)*kk;
                        Y_hat_temp = [datenum(t(valList==kk,:)) Y_hat_temp foldn];
                        if kk==1; Y_hat.val=Y_hat_temp;else;Y_hat.val=[Y_hat.val;Y_hat_temp];end %Assign to the Y_hat variable
                        clear Y_hat_temp
                        
                    end %loop of calibration/validation folds
                    
                    %Save estimates to the output folder for future reference
                    disp('-----Saving estimates...');
                    yhat_path = fullfile(settingsSet.outpath,['Estimates_' settingsSet.currentPod settingsSet.currentValidation settingsSet.currentRegression]); %Create file path for fitted coefficients to save
                    save(char(yhat_path),'Y_hat'); %Save out model estimates
                    
                    
                    %% Determine statistics
                    disp('-----Running statistical analyses...');
                    for mm = 1:nStats
                        %Get string representation of function - this must match the name of a function
                        statFunc = settingsSet.statsList{mm};
                        fprintf('------Applying statistical analysis function %s ...\n',statFunc);
                        
                        %Convert this string to a function handle to feed the pod data to
                        statFunc = str2func(statFunc);
                        
                        %Apply the statistical function i=nRef, j=nPods,m=nRegs,k=nVal,kk=nFolds,mm=nStats
                        mdlStats{i,j,m,k,kk,mm} = statFunc(X, Y, Y_hat, settingsSet);
                    end%loop of common statistics to calculate
                    
                    
                    %% Create plots
                    disp('-----Plotting estimates and statistics...');
                    for mm = 1:nPlots
                        %Get string representation of function - this must match the name of a function
                        plotFunc = settingsSet.plotsList{mm};
                        fprintf('------Running plotting function %s ...\n',plotFunc);
                        
                        %Convert this string to a function handle to feed the pod data to
                        plotFunc = str2func(plotFunc);
                        
                        %Run the plotting function
                        plotFunc(t, X, Y, Y_hat,valList,settingsSet);
                    end%loop of plotting functions
                    
                    
                end%loop of regressions
            end%loop of calibration/validation methods
            clear X t
        end%loop for each pod
        clear Y
    end%loop for each reference file
end%If statement for checking if models should be fitted to colocated data

%% Save out important information for future replication/application
disp('Saving fitted regression models...');
regPath = fullfile(settingsSet.outpath,'run_fittedModels'); %Create file path for fitted coefficients to save
save(char(regPath),'fittedMdls'); %Save out fitted regression models
disp('Saving settings structure...');
settingsPath = fullfile(settingsSet.outpath,'run_settings'); %Create file path for settings to save
save(char(settingsPath),'settingsSet'); %Save out settings



%% --------------------------Apply Fitted Equations to New Data--------------------------
if settingsSet.applyCal
    %% If no calibrations were generated, have to load a set of fitted models from elsewhere
    if ~settingsSet.generateCal
        %Ask the user to select a mat file with the fitted models to apply
        disp('----Select file with previous analysis...');
        oldRegsPath = uigetdir(pwd,'Select folder with previous analysis');
        assert(~isequal(oldRegsFiles,0),'No file selected, run ended'); %Check that file was selected
        
        %Load the old fitted models file into memory
        disp('----Loading previously fitted models...');
        tempFile = load([oldRegsPath slash 'run_fittedModels']);
        %Extract the structure holding fitted models
        fittedMdls = tempFile.fittedMdls;
        clear tempFile
        
        %Load the old settings file into memory
        disp('----Loading previously used settings...');
        tempFile = load([oldRegsPath slash 'run_settings']);
        %Extract the regressions used in the previous analysis
        oldsettingsSet = tempFile.settingsSet;
        clear tempFile oldRegsPath
    else
        oldsettingsSet = settingsSet;
    end
    
    %Loop through each pod selected from the deployment file that you originally selected (where the new data is)
    for j = 1:nPods
        fprintf('---Applying fitted calibrations to %s ...\n',settingsSet.podList{j});
        
        %Check that the pod and reference gas are found in the old data
        assert(any(strcmp(oldsettingsSet.refGas,settingsSet.refGas)),'Pollutant is not the same!');
        assert(any(strcmp(settingsSet.podList{j},oldsettingsSet.podList)),['Pod ' settingsSet.podList{j} ' is not found in the original model fitting!']);
        
        %Get the position the pod was listed in the old run file 
        podPos = 1:length(oldsettingsSet.podList);
        podPos = podPos(strcmp(settingsSet.podList{j},oldsettingsSet.podList)); 
        
        %% Allow users to select fitted equations to actually apply
        %Make array to hold user's decisions (1=keep, 0=ignore)
        %Indices for the regression model array are: (i=nRef, j=nPods, m=nRegs,k=nVal,kk=nFolds)
        tempMdls = zeros(size(fittedMdls));
        modelNum = 0;
        
        %Loop through each generated model and report
        for i = 1:length(oldsettingsSet.fileList.colocation.reference.files.bytes)
            for m = 1:length(oldsettingsSet.regList)
                regName = oldsettingsSet.regList{m};
                for k = 1:length(oldsettingsSet.valList)
                    valName = oldsettingsSet.valList{k};
                    for kk = 1:oldsettingsSet.nFoldRep
                        %Get string representation of the model function
                        reportFunc = settingsSet.regList{m};
                        %Convert this string to a function handle for the model
                        reportFunc = str2func(reportFunc);
                        %Get the reporting function for that model
                        reportFunc = reportFunc(3);
                        %Report results of original model fitting
                        modelNum = modelNum+1;
                        tempMdls(i,podPos,m,k,kk) = modelNum;
                        disp([num2str(modelNum) ': Model: ' regName ', Validation: ' valName ', Fold #' num2str(kk)]);
                        reportFunc(fittedMdls{i,podPos,m,k,kk},oldsettingsSet);
                    end
                end
            end
        end
        
        %Let user pick the models to keep for application
        keepMods = input('Which models would you like to use? (separate S/N with commas)   ','s');
        keepMods = split(keepMods,',');
        %Loop through and mark these models for use
        keepMdls = zeros(size(fittedMdls));
        for i = 1:length(keepMods)
            keepMdls(tempMdls==str2num(keepMods{i}))=1;
        end
        clear tempMdls
        
        %% Load the field pod data
        fprintf('--Loading data for %s ...\n', settingsSet.podList{j});
        podData = loadPodData(settingsSet.fileList.colocation.pods, settingsSet.podList{j});
        settingsSet.currentPod = settingsSet.podList{j}; %Keep track of pod currently being analyzed
        
        %Extract just columns needed
        disp('--Extracting important variables from pod data');
        [X, xt] = dataExtract(podData, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
        clear podData
        
        %Average or find median values for the processed pod data
        [X, xt] = applyAvging(X, xt, settingsSet);
        
        %% Pre-Process Pod Data (Filter, normalize, etc)
        disp('--Applying selected pod data preprocessing...');
        for jj = 1:length(settingsSet.podPreProcess)
            %Get string representation of function - this must match the name of a regression function
            filterFunc = settingsSet.podPreProcess{jj};
            fprintf('---Applying pod preprocess function %s ...\n',filterFunc);
            
            %Convert this string to a function handle to feed the pod data to
            filterFunc = str2func(filterFunc);
            
            %Apply the filter function
            [X, xt] = filterFunc(X, xt, settingsSet);
            
            clear filterFunc
        end%pod preprocessing loop
        
        %% Apply averaging and filters
        
        %% Loop through saved regressions and apply them to field data
        for m = 1:nRegs
            
            for mm = 1:length(settingsSet.regList)
                
            end
            
        end%loop through each regression to apply
    end
end%if statement that allows application to field data


