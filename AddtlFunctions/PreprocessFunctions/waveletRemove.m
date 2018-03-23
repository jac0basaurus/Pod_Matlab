%function waveletRemove(s_seq,nBins)
% Load original one-dimensional signal. 
load leleccum; s = leleccum(1:3920); ls = length(s); 

% Perform decomposition of signal at level 3 using db5. 
[c,l] = wavedec(s,3,'db5');

% Reconstruct s from the wavelet decomposition structure [c,l]. 
a0 = waverec(c,l,'db5');

%Get first three
[cd1,cd2,cd3] = detcoef(c,l,[1 2 3]);

%Calculate reconstruction error
err = norm(s-a0)

plot(1:length(s),s)
line(1:length(a0),a0,'Color','r')
title('Original signal')

figure
plot(1:length(cd3),cd3)
line(1:length(cd2),cd2,'Color','r')
line(1:length(cd1),cd1,'Color','g')
title('Detail Coefficients (cd3)')

%end