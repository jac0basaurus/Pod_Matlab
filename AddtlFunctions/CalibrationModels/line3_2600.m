function func = line3_2600(a)

switch a
    case 1; func = @line3_2600Gen;
    case 2; func = @line3_2600Apply;
end

end

function [mdl, y_hat] = line3_2600Gen(Y,X,settingsSet)

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
C.temperature = X.temperature;
C.humidity = X.humidity;

modelSpec = [foundColName '~' Y.Properties.VariableNames{1} '+ temperature + humidity']; %Sensor response as function of gas concentration

mdl = fitlm(C,modelSpec);  %Fit the model
coeffs = mdl.Coefficients.Estimate'; %Get the estimates of coefficients

mdlinv = @(p,sens,temp,hum) ((sens-p(1)-p(3).*temp-p(4).*hum)/p(2)); %Invert the model (concentration~Figaro+Temperature+Humidity)

y_hat = mdlinv(coeffs,C.Fig2600,C.temperature,C.humidity); %Get the estimated concentrations

end

function y_hat = line3_2600Apply(X,mdl,settingsSet)

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
C=Fig2600; %Join into a temporary table
C.temperature = X.temperature;
C.humidity = X.humidity;

coeffs = mdl.Coefficients.Estimate'; %Get the estimates of coefficients

mdlinv = @(p,sens,temp,hum) ((sens-p(1)-p(3).*temp-p(4).*hum)/p(2)); %Invert the model (concentration~Figaro+Temperature+Humidity)

y_hat = mdlinv(coeffs,C.Fig2600,C.temperature,C.humidity); %Get the estimated concentrations

end