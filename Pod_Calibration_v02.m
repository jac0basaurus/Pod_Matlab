%% USAGE NOTES
%{
This code is based on Ricardo Piedraheta's Pod_calibration_generation
code, with attemps to make it more readable and more easily modified.
This was developed on Matlab R2017b, so some unhandled errors may be caused
by the use of different versions.
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
clear variables; 
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
settingsSet.groupMethod = 1;  %Use median or mean values when grouping by timestamp - 0=mean, 1=median, 2=linear interpolation, 3=smoothing spline
settingsSet.datetimestrs = {'M/d/yy H:mm:ss','yyyy.MM.dd H.m.s'}; %Datetime formats to use when trying to convert non-standard import datetime strings
settingsSet.datestrings = {'yyyy.MM.dd','MM-dd-yyyy'}; %Date formats to use when trying to convert non-standard import dates
settingsSet.timestrings = {'H.m.s'}; %Date formats to use when trying to convert non-standard import times
settingsSet.outFolder=['Outputs_' datestr(now,'yymmddHHMMSS')]; %Create a unique name for the save folder

%Note: for these lists, enter function names in the order in which you'd like them to be performed (if it matters)
%Please also note that these increase multiplicatively, so selecting too many options will significantly increase analysis time
settingsSet.refGas = {'testpoint'}; %Currently only partially works with more than one pollutant, but entered as cell array in case multiple pollutant functionality is added
settingsSet.refTZ = {-7}; %Time zone in which the reference data is reported.  Cell structure is used to allow possible extension to multiple files later
settingsSet.refPreProcess = {'removeNaNs','remove999','sortbyTime','applyAvging'}; %Preprocessing functions for reference data

settingsSet.podSensors = {'co2','fig2600_s','fig2602_s','bl_mocon','e2v_s',...
    'quadstat_1_m','quadstat_2_m','quadstat_3_m','quadstat_4_m',...
    'outbrd1_s','outbrd2_s','outbrd3_s','outbrd4_s'}; %Sensors for use in calibration equations ,'NO_B4' ,'MICS5121wp_sob'
settingsSet.envSensors = {'temperature','humidity'}; %Sensors for use in calibration equations
settingsSet.podPreProcess = {'removeNaNs','sortbyTime','applyAvging','rem30','podTimeZone','TempC2K','makePCs'}; %Preprocessing functions for pod data

settingsSet.regList = {'clusterAll'}; %Regressions to evaluate

settingsSet.valList = {'randVal', 'timeFold'}; %Validation set selections
settingsSet.nFolds = 10; %Number of 'folds' for validation (e.g. 10 folds = 1/10 = 10% dropped for validation)
settingsSet.nFoldRep = 4; %Number of folds to actually use (will be selected in order from first to last)

settingsSet.statsList = {'podRMSE'}; %Statistics to calculate - THESE ARE NOT YET WRITTEN
settingsSet.plotsList = {'timeseriesPlot', 'acfPlot'}; %Plotting functions

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



%% ------------------------------Read Pod Inventory and Deployment Log------------------------------
%The deployment log is used to determine if data should be analyzed based on the timestamp
disp('Reading deployment log...');
settingsSet.deployLog = readDeployment(settingsSet.analyzeDir);

%The pod inventory is used to assign headers and therefore determine which columns contain required information. 
%At a minimum, each pod should have an enrgy with labels 'temperature', 'humidity', 'datetime' or 'Unix time', and then containing the names of sensors entered above
disp('Reading pod inventory...');
settingsSet.podList = readInventory(settingsSet);



%% ------------------------------Convert Data to .mat Files as Needed------------------------------
%Import the Pod Data
disp('Converting unconverted data files to .mat files...');

%Convert colocated pod files to .mat files
convertPodDatatoMat(settingsSet);

%Convert reference files to .mat files
convertRefDatatoMat(settingsSet);

%End the program if user has selected that they only want to convert files
assert(~settingsSet.convertOnly , 'Finished converting files, and "Convert Only" was selected'); 



%% These are the number of reference files, pods, regressions, validations, and folds to evaluate
nref = length(settingsSet.fileList.colocation.reference.files.bytes); %Number of reference files
if ischar(settingsSet.podList.podName)%Account for only analyzing one Pod (indexing is weird with a list of one)
    nPods=1;
else
    nPods=size(settingsSet.podList.podName,1);
end
nRegs = length(settingsSet.regList); %Number of regression functions
nVal = length(settingsSet.valList); %Number of validation functions
nFolds = settingsSet.nFoldRep;  %Number of folds to evaluate
nStats = length(settingsSet.statsList); %Number of statistical functions to apply
nPlots = length(settingsSet.plotsList); %Number of plotting functions

fprintf('*** Total number of loops to evaluate: %d *** \n Beginning...\n',nref*nPods*nRegs*nVal*nFolds);



%% --------------------------Fit Calibration Equations--------------------------
%% --------------------------START REFERENCE FILE LOOP------------------------------
%Note, these reference files will be analyzed independently
%Only the time and gas concentration will be extracted from each reference file
%If you want to combine multiple colocations into one calibration, manually append the reference files into a single file
for i = 1:nref
    %Keep track of the loop number in case it's needed by a sub function
    settingsSet.loops.i=i;
    
    %If statement checks whether to generate models and skips this loop if not
    if ~settingsSet.generateCal
        break
    end
    
    %% ------------------------------Get Reference Data------------------------------
    %Get the reference file to load
    %Indexing is weird if only one file
    if nref==1
        reffileName = settingsSet.fileList.colocation.reference.files.name;
    else
        reffileName = settingsSet.fileList.colocation.reference.files.name{i};
    end
    
    %Load the reference file into memory
    fprintf('-Importing reference file %s ...\n',reffileName);
    Y_ref = loadRefData(settingsSet);
    
    %Extract just the datestring and the gas of interest
    disp('-Extracting important variables from reference data');
    [Y_ref, yt] = dataExtract(Y_ref, settingsSet, settingsSet.refGas);
    
    %% Pre-process Reference Data (Filter, normalize, etc)
    fprintf('-Pre-processing reference file: %s ...\n',reffileName);
    for ii = 1:length(settingsSet.refPreProcess)
        settingsSet.loops.ii=ii;
        %Get string representation of function - this must match the name of a filter function
        filtFunc = settingsSet.refPreProcess{ii};
        fprintf('--Applying reference preprocess function %s ...\n',filtFunc);
        %Convert this string to a function handle to feed the pod data to
        filtFunc = str2func(filtFunc);
        
        %Save filtered reference data into Y
        [Y_ref,yt] = filtFunc(Y_ref, yt, settingsSet);
        
        %Clear for next loop
        clear filtFunc
    end%loop for preprocessing reference data
    
    
    
    %% --------------------------START POD LOOP------------------------------
    for j = 1:nPods
        
        %Create empty cell matrices to store fitted models and statistics for each combination
        fittedMdls = cell(nRegs,nVal,nFolds);
        mdlStats = cell(nRegs,nVal,nStats);
        Y_hat.cal = cell(nRegs,nVal,nFolds);
        Y_hat.val = cell(nRegs,nVal,nFolds);
        valList = cell(nVal,1);
        
        %Keep track of the loop number in case it's needed by a sub function
        settingsSet.loops.j=j;
        fprintf('---Generating calibrations for %s ...\n',settingsSet.podList.podName{j});
        %% Load Pod Data
        fprintf('--Loading data for %s ...\n', settingsSet.podList.podName{j});
        X = loadPodData(settingsSet.fileList.colocation.pods, settingsSet.podList.podName{j});
        
        %Extract just columns needed
        disp('--Extracting important variables from pod data');
        [X, xt] = dataExtract(X, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
        
        %% Pre-Process Pod Data (Filter, normalize, etc)------------------------------
        disp('--Applying selected pod data preprocessing...');
        for jj = 1:length(settingsSet.podPreProcess)
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.jj=jj;
            %Get string representation of function - this must match the name of a regression function
            filterFunc = settingsSet.podPreProcess{jj};
            fprintf('---Applying pod preprocess function %s ...\n',filterFunc);
            %Convert this string to a function handle to feed the pod data to
            filterFunc = str2func(filterFunc);
            
            %Apply the filter function
            [X, xt] = filterFunc(X, xt, settingsSet);
            
            %Clear function for next loop
            clear filterFunc
        end%pod preprocessing loop
        
        %Match reference and Pod data based on timestamps
        disp('--Joining pod and reference data...');
        [Y, X, t] = alignRefandPod(Y_ref,yt,X,xt,settingsSet);  
        
        %Use deployment log to verify that only colocated data is included
        disp('--Checking data against the deployment log...');
        [Y, X, t] = deployLogMatch(Y,X,t,settingsSet);
        
        
        %% --------------------------START VALIDATION SETS LOOP------------------------------
        %Create a vector used to separate calibration and validation data sets
        for k = 1:nVal
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.k=k;
            %Get string representation of validation selection function
            validFunc = settingsSet.valList{k};
            fprintf('----Selecting validation set with function: %s ...\n',validFunc);
            %Convert this string to a function handle for the validation selection function
            validFunc = str2func(validFunc);
            
            %Run that validation function and get the list of points to fit/validate on for each fold
            valList{k} = validFunc(Y, X, t, settingsSet.nFolds);
            %Clear the validation selection function for tidyness
            clear validFunc
            
            
            
            %% --------------------------START REGRESSIONS LOOP------------------------------
            %Fit regression equations and validate them
            for m = 1:nRegs
                %Keep track of the loop number in case it's needed by a sub function
                settingsSet.loops.m=m;
                fprintf('-----Fitting regression%s ...\n',settingsSet.regList{m});
                
                %Get string representation of functions - this must match the name of a function saved in the directory
                regFunc = settingsSet.regList{m};
                %Convert this string to a function handle for the regression
                regFunc = str2func(regFunc);
                %Get the generation function for that regression
                %Note that the function must be set up correctly - see existing regression functions for an example
                calFunc = regFunc(1);
                %Get the application function for that regression
                valFunc = regFunc(2);
                %Clear the main regression function for tidyness
                clear regFunc
                
                
                
                %% --------------------------START K-FOLDS LOOP------------------------------
                %For each repetition (fold) of the validation list, select the data and fit a regression to it
                for kk = 1:nFolds
                    %Keep track of the loop number in case it's needed by a sub function
                    settingsSet.loops.kk=kk;
                    fprintf('------Using calibration/validation fold #%d ...\n',kk);
                    
                    %% Fit the selected regression
                    %Fit the regression and get the estimates and fitted coefficients
                    %Indices for the regression model array are: (m=nRegs,k=nVal,kk=nFolds)
                    disp('-------Fitting regression...');
                    [fittedMdls{m,k,kk}, Y_hat.cal{m,k,kk}] = calFunc(Y(valList{k}~=kk,:), X(valList{k}~=kk,:), settingsSet);
                    
                    %% Apply the fitted regression to the validation data
                    %Apply the fitted regression to the validation data
                    disp('-------Validating regression...');
                    Y_hat.val{m,k,kk} = valFunc(X(valList{k}==kk,:),fittedMdls{m,k,kk},settingsSet);
                    
                end %loop of calibration/validation folds

                
                %% ------------------------------Determine statistics------------------------------
                disp('-----Running statistical analyses...');
                for mm = 1:nStats
                    %Keep track of the loop number in case it's needed by a sub function
                    settingsSet.loops.mm=mm;
                    %Get string representation of function - this must match the name of a function
                    statFunc = settingsSet.statsList{mm};
                    fprintf('------Applying statistical analysis function %s ...\n',statFunc);
                    
                    %Convert this string to a function handle to feed the pod data to
                    statFunc = str2func(statFunc);
                    
                    %Apply the statistical function m=nRegs,k=nVal,mm=nStats
                    mdlStats{m,k,mm} = statFunc(X, Y, Y_hat, valList{k}, settingsSet);
                end%loop of common statistics to calculate

                
            end%loop of regressions
            
        end%loop of calibration/validation methods
        
        
        %% ------------------------------Create plots----------------------------------------
        disp('-----Plotting estimates and statistics...');
        for mm = 1:nPlots
            %Keep track of the loop number in case it's needed by a sub function
            settingsSet.loops.mm=mm;
            %Get string representation of function - this must match the name of a function
            plotFunc = settingsSet.plotsList{mm};
            fprintf('------Running plotting function %s ...\n',plotFunc);
            
            %Convert this string to a function handle to feed the pod data to
            plotFunc = str2func(plotFunc);
            
            %Run the plotting function
            plotFunc(t, X, Y, Y_hat,valList,mdlStats,settingsSet);
        end%loop of plotting functions

        
        %% ------------------------------Save info for each pod for future reference------------------------------
        disp('---Saving estimates...');
        temppath = fullfile(settingsSet.outpath,['Estimates_' settingsSet.podList.podName{j}]); %Create file path for estimates
        save(char(temppath),'Y_hat'); %Save out model estimates

        disp('---Saving fitted regression models...');
        temppath = fullfile(settingsSet.outpath,['fittedModels_' settingsSet.podList.podName{j}]); %Create file path for fitted coefficients to save
        save(char(temppath),'fittedMdls'); %Save out fitted regression models

        
        %Clear temporary variables
        clear X xt t temppath valList
    end%loop for each pod
    
    %Clear temporary variables
    clear Y_ref Y yt
end%loop for each reference file

%% Save out settings for future replication/application
disp('Saving settings structure...');
settingsPath = fullfile(settingsSet.outpath,'run_settings'); %Create file path for settings to save
save(char(settingsPath),'settingsSet'); %Save out settings



%% --------------------------Apply Fitted Equations to New Data--------------------------
if settingsSet.applyCal
    %% If no calibrations were generated, have to load a set of fitted models from elsewhere
    if ~settingsSet.generateCal
        %Ask the user to select a file with the fitted models to apply
        disp('----Select file with previous analysis...');
        oldRegsPath = uigetdir(pwd,'Select folder with previous analysis');
        assert(~isequal(oldRegsPath,0),'Error: no file selected, run ended'); %Check that file was selected
        
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
    
    %% Loop through each pod selected from the deployment file that you originally selected (where the new data is)
    for j = 1:nPods
        fprintf('---Applying fitted calibrations to %s ...\n',settingsSet.podList.podName{j});
        
        %Check that reference gas was used for the old data
        assert(any(strcmp(oldsettingsSet.refGas,settingsSet.refGas)),'Pollutant is not the same!');
        
        %Check that a calibration was generated for this pod
        if ~any(strcmp(settingsSet.podList.podName{j},oldsettingsSet.podList.podName))
            warning(['Pod ' settingsSet.podList.podName{j} ' is not found in the old calibration set!']);
            %If it's not in the old settings set, move onto the next loop (pod)
            continue
        end
        
        %Get the position the pod was listed in the old run file 
        podPos = 1:length(oldsettingsSet.podList.podName);
        podPos = podPos(strcmp(settingsSet.podList.podName{j},oldsettingsSet.podList.podName)); 
        
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
                        fprintf('---------------------\n');
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
            keepMdls(tempMdls==str2double(keepMods{i}))=1;
        end
        clear tempMdls
        
        %% Load the field pod data
        fprintf('--Loading data for %s ...\n', settingsSet.podList.podName{j});
        X = loadPodData(settingsSet.fileList.colocation.pods, settingsSet.podList.podName{j});
        
        %Extract just columns needed
        disp('--Extracting important variables from pod data');
        [X, xt] = dataExtract(X, settingsSet, [settingsSet.podSensors settingsSet.envSensors]);
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
        
        
        %% Loop through saved regressions and apply them to field data
        for m = 1:nRegs
            
            for mm = 1:length(settingsSet.regList)
                
            end
            
        end%loop through each regression to apply
    end
end%if statement that allows application to field data
