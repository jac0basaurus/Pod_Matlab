function timeseriesPlot(t,~,Y,Y_hat,valList,settingsSet)
%Plots the validation and calibration estimates for each fold

%Get names of current pod, regression, and validation methods
podName = settingsSet.currentPod;
valName = settingsSet.currentValidation;
regName =   settingsSet.currentRegression;

Y_hat_cal = Y_hat.cal; %Extract calibrated estimates
Y_hat_val = Y_hat.val; %Extract validation estimates
Y = table2array(Y); %Converts to array for use in plotting
t = datenum(t); %Convert to datenums for plotting

%First plot the reference values colored by validation set
g(1,1) = gramm('x',t,'y',Y(:,1),'color',valList);% Create a gramm object
g(1,1).geom_line('alpha',0.5);% Plot raw data as points
g(1,1).set_names('x',' ','y','Reference','color','Val. Set'); % Set appropriate names for legends
g(1,1).set_color_options('map','lch'); %Set color
g(1,1).set_datetick('x'); %Make x-axis display dates/times instead of the datenum
g(1,1).set_title('Reference Concentrations');% Set figure title

%The plot the estimates on data used for training the model
g(1,2) = gramm('x',Y_hat_cal(:,1),'y',Y_hat_cal(:,2),'color',Y_hat_cal(:,3));% Create a gramm object
g(1,2).geom_line('alpha',0.5);% Plot raw data as points
g(1,2).set_names('x',' ','y','Estimate','color','Fold #'); % Set appropriate names for legends
g(1,2).set_color_options('map','lch'); %Set color
g(1,2).set_datetick('x');
g(1,2).set_title('Calibrated Timeseries');% Set figure title

%The plot the estimates on data used for validating the model
g(1,3) = gramm('x',Y_hat_val(:,1),'y',Y_hat_val(:,2),'color',Y_hat_val(:,3));% Create a gramm object
g(1,3).geom_line('alpha',0.5);% Plot raw data as points
g(1,3).set_names('x',' ','y','Estimate','color','Fold #'); % Set appropriate names for legends
g(1,3).set_color_options('map','lch'); %Set color
g(1,3).set_datetick('x');
g(1,3).set_title('Validation Timeseries');% Set figure title

%Set the overall title
g.set_title(['Pod: ' podName ', Validation: ' valName ', Regression: ' regName]);

% Do the actual drawing
figure('Position',[100 100 1000 400]);
g.draw();

end

