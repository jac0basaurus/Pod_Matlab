function func = line1(a)

switch a
    case 1; func = @line1Gen;
    case 2; func = @line1Apply;
end

end

function [mdl, y_hat] = line1Gen(Y,X,settingsSet)

columnNames = X.Properties.VariableNames;
foundCol = 0;

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi('Fig2600',columnNames{i}))
        foundCol=foundCol+1;
        foundColName = columnNames{i};
        Fig2600=X(:,i);
    end
end
assert(foundCol == 1,'Could not find the Figaro 2600 column');

C=[Y,Fig2600]; %Join into a temporary table

modelSpec = [foundColName '~' Y.Properties.VariableNames{1}]; %Sensor response as function of gas concentration

mdl = fitlm(C,modelSpec);  %Fit the model
coeffs = mdl.Coefficients.Estimate'; %Get the estimates of coefficients

mdlinv = @(p,sens) ((sens-p(1))/p(2)); %Invert the model (concentration~Figaro)

y_hat = mdlinv(coeffs,table2array(Fig2600)); %Get the estimated concentrations

end

function y_hat = line1Apply(X,mdl,settingsSet)
columnNames = X.Properties.VariableNames;
foundCol = 0;

%Find the column containing the sensor for analysis
for i = 1:length(columnNames)
    if any(regexpi('Fig2600',columnNames{i}))
        foundCol=foundCol+1;
        foundColName = columnNames{i};
        Fig2600=X(:,i);
    end
end
assert(foundCol == 1,'Could not find the Figaro 2600 column');

coeffs = mdl.Coefficients.Estimate'; %Get the estimates of coefficients

mdlinv = @(p,sens) ((sens-p(1))/p(2)); %Invert the model (concentration~Figaro)

y_hat = mdlinv(coeffs,table2array(Fig2600)); %Get the estimated concentrations

end