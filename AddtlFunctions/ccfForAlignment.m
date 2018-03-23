function ccfForAlignment(X,Y,n)

%Plot n lags for the sample cross covariance function between X and Y
%Useful for seeing if there is some time lag between the pod and reference

%Assign reference and sensor vectors
ref = Y;
sens = X;

%Calculate and plot the XCF at n lags on either side of 0
[XCF,lags,bounds] = crosscorr(sens,ref,n);

%Identify lag with maximum XCF
maxXCF = max(XCF);
maxIndex = find(XCF == maxXCF);

% f_plot=figure('Position',[100 40 800 650]);
% fignum(1)=figure(f_plot);
% plot(Tsteps(1:end-1),corrTstep,'-*')
% title([sen ] );
% ylabel('Pearsons R');
% xlabel('Minutes Lag')
% [MaxVal, MaxIdx] = max(corrTstep);
% text(.1,.9,['Max corr of ' num2str(MaxVal) ' @ ' num2str(Tsteps(MaxIdx))],'Units','Normalized')
% grid on
% print(figure(f_plot), '-append', '-dpsc2', psname);

