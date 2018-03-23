function [X,t] = humidrel2abs(X, t, settingset)
%convert Humidity in X from relative to absolute turn on and off at line 58
temp = X.temperature;
humidity=X.humidity;
%make sure the values that go in the function are reasonable and otherwise remove them
uppertemp= temp > 370
X(uppertemp==1,:)=[];
t(uppertemp==1,:)=[];

lowertemp= temp<263
X(lowertemp==1,:)=[]
t(lowertemp==1,:)=[]

%if the values are blank we cannot calculate, assume atmopheric pressure     
if exist(humidity, temp);
     absHumtemp = convert_humidity(101320.75,X.temperature,X.humidity, 'relative humidity','partial pressure','Murphy&Koop2005'); %Calculates water mixing ratio (given as fraction).  Assumes average Boulder atmospheric pressure.
else
     error('Variables necessary for RH conversion do not exist!');
end
X.humidity = absHumtemp;
end
     
     
     
     
% try
% convert_humidity(101320.75,filetemp(g1).rawdatasetENV.Temp ,filetemp(g1).rawdatasetENV.RH, 'relative humidity','partial pressure','Murphy&Koop2005'); %Calculates water mixing ratio (given as fraction).  Assumes average Boulder atmospheric pressure.
%     pressure = X.pressure;
%     temperature = X.temperature;
%     absHumtemp = convert_humidity(X.pressure,X.temperature,X.humidity, 'relative humidity','partial pressure','Murphy&Koop2005'); %Calculates water mixing ratio (given as fraction).  Assumes average Boulder atmospheric pressure.
% catch
%     if exist(pressure, temperature)
%             
%     else
%         error('Variables necessary for RH conversion do not exist!');
%     end
%     
% end
% 
%   X.humidity = absHumtemp
% end
