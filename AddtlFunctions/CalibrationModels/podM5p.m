function func = podM5p(a)

switch a
    case 1; func = @podM5pGen;
    case 2; func = @podM5pApply;
    case 3; func = @podM5pReport;
end

end

function [mdl, y_hat] = podM5pGen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;

%Need as an array
X = table2array(X);

%Fit model tree
params = m5pparams2('modelTree',true);
model = m5pbuild(X,Y,params);

%Report on model
m5pprint(model);
m5pplot(model);

%Report cross-validation
m5pcv(X,Y,params)

%Make predictions
y_hat = m5ppredict(model,X);

%Export the model
mdl = model;

end

function y_hat = podM5pApply(X,mdl,settingsSet)

%Need as an array
X = table2array(X);

%Make predictions
y_hat = m5ppredict(model,X);

end

function podM5pReport(fittedMdl,~)
try
    m5pprint(model);
    m5pplot(model);
catch err
    disp('Error reporting this model');
end

end