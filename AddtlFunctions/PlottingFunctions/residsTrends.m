function residsTrends(t,coVars,Y,Y_hat,valList,settingsSet)
%Plots the validation and calibration estimates for each fold

%Get names of current pod, regression, and validation methods
podName = settingsSet.currentPod;
valName = settingsSet.currentValidation;
regName =   settingsSet.currentRegression;

Y_hat_cal = Y_hat.cal; %Extract calibrated estimates
Y_hat_val = Y_hat.val; %Extract validation estimates

coVars.ref = table2array(Y); %Converts to array for use in plotting

%Make arrays to compare to y_hat and residuals
for kk = 1:settingsSet.nFoldRep
    if kk==1;plotArray_cal = coVars(valList~=kk,:);else;plotArray_cal = [plotArray_cal;coVars(valList~=kk,:)];end
    if kk==1;plotArray_val = coVars(valList==kk,:);else;plotArray_val = [plotArray_val;coVars(valList==kk,:)];end
end

values = [sprintf('%s_',plotArray_cal.Properties.VariableNames{1:end-1}),plotArray_cal.Properties.VariableNames{end}];
indicators = [values '_Indicators'];

%Get residuals
plotArray_cal.resids = Y_hat_cal(:,2) - plotArray_cal.ref;
plotArray_val.resids = Y_hat_val(:,2) - plotArray_val.ref;

%Join arrays
Y_hat_cal = array2table(Y_hat_cal,{'datetime','Y_hat','fold'});
Y_hat_val = array2table(Y_hat_val,{'datetime','Y_hat','fold'});

%Join arrays
plotArray_cal = [plotArray_cal Y_hat_cal];
plotArray_val = [plotArray_val Y_hat_val];


%Convert into stacked array
plotArray_cal=stack(plotArray_cal,{coVars.Properties.VariableNames{:},'datetime'});
plotArray_cal=stack(plotArray_cal,coVars.Properties.VariableNames);

indicators = [sprintf('%s_',plotArray_cal.Properties.VariableNames{1:end-1}),plotArray_cal.Properties.VariableNames{end}];
values = plotArray_cal.Properties.VariableNames{2};

%
g = gramm('x',Y_hat_cal(:,1),'y',resids_cal,'color',Y_hat_cal(:,3));% Create a gramm object


end

