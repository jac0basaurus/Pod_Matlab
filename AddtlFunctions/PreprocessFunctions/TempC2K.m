function [X,t] = TempC2K(X, t, settingsSet)
%{
Convert temperatures in X from Celcius to Kelvin
%}

%Convert temperature to K
X.temperature = X.temperature+273.15;

end