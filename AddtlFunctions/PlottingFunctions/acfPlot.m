function acfPlot(t,X,Y,Y_hat,valList,settingsSet)
%Plots the correlation between X variables and the Y matrix

%Get the time averaging to guess appropriate lags
deltaT = settingsSet.timeAvg;
nlags = hours(12)/minutes(deltaT);
%Assume that first column (only column) of Y has data
yarray = table2array(Y(:,1));
%Remove NaNs
yarray(isnan(yarray))=0;
for i = 1:size(X,2)
    %Get variable name
    VarName = X.Properties.VariableNames{i};
    
    %Only plot this for designated sensors (not T, P, Rh, etc)
    isSensor = 0;
    for j = 1:length(settingsSet.podSensors)
        if strfind(VarName,settingsSet.podSensors{j})>0
            isSensor = 1;
        end
    end
    if isSensor == 1
        %Get X as array
        xarray = table2array(X(:,i));
        %Remove NaNs
        xarray(isnan(xarray))=0;
        
        %Plot the cross correlation
        figure
        crosscorr(yarray, xarray,nlags);
        %Give the plot a better title
        title(['Correlation of Reference with ' VarName])
        %Display the max correlation
        [xcf,lags,~] = crosscorr(yarray, xarray,nlags);
        displaytext = ['\leftarrow Max XCF: ' num2str(round(max(xcf),3)) ' at lag: ' num2str(lags(max(xcf)==xcf))];
        text(lags(max(xcf)==xcf),max(xcf),displaytext);
    end
end

end

