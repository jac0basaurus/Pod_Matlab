function func = line1_kNN(a)

switch a
    case 1; func = @l1kNNGen;
    case 2; func = @l1kNNApply;
    case 3; func = @l1kNNReport;
end

end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function mdl = l1kNNGen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;
mainSensor = settingsSet.podSensors{1}; %Assume that the first sensor is the one to model
pollutant = Y.Properties.VariableNames{1};

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi(columnNames{i},mainSensor))
        foundCol=foundCol+1; %Keep track of how many columns matching this sensor were found
        sensorData = X(:,i); %Extract that data into its own table
        mainSensor = columnNames{i}; %Get the real name of the sensor
    end
end
assert(foundCol == 1,['Could not find a unique column for sensor: ' mainSensor]);

%Join into a temporary table
C=[Y(:,1),sensorData]; 
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column

%% Sensor response as linear function of gas concentration
%Fit the model
modelSpec = [pollutant '~' mainSensor]; 
linmdl = fitlm(C,modelSpec); 
linmdl = compact(linmdl); %Make the model compact to reduce size
%Predict
y_hat_lin = predict(linmdl,C.(mainSensor));

%% Now fit a local spline to the residuals as plotted against temperature and humidity
res_lin = table2array(Y(:,1)) - y_hat_lin; %Calculate the residuals as Y - y_hat
smoothfit = fit([C.temperature, C.humidity],res_lin,'lowess','span',0.05); %Fit a smooth model based on temp and rh

%Export both models and some info
mdl = {linmdl, smoothfit, normMat, mainSensor};

end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function y_hat = l1kNNApply(X,mdl,settingsSet)

%Extract the two models from the cell array "mdl"
linmdl = mdl{1};
smoothfit = mdl{2};
normMat = mdl{3};
mainSensor = mdl{4};

%Make a temporary data table
C = X(:,mainSensor);
C.temperature = X.temperature; %Add the temperature column
C.humidity = X.humidity; %Add the humidity column

%Normalize temperature and humidity for fitting
C.temperature = (C.temperature-normMat(1,1))/normMat(1,2); %Normalize the temperature column
C.humidity = (C.humidity-normMat(2,1))/normMat(2,2); %Normalize the humidity column

%% Get the Line 1 estimated concentrations
y_hat_lin = predict(linmdl,C.(mainSensor));

%% Get the estimated residuals
y_hat_smooth = smoothfit([C.temperature, C.humidity]); 

%% Get a final estimate
y_hat = y_hat_lin + y_hat_smooth;

end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function l1kNNReport(mdl,~)
linmdl = mdl{1};
try
    linmdl.Coefficients.Estimate'
catch err
    disp('Error reporting this model');
end

end