function [f,a,A] = mfastperiodogram(x,y,n,k,ny,N)
% n is os, k is extirpolation accuracy.
if nargin < 3, n = 5; end
if nargin < 4, k = 5; end

% Sort the data.
[x,iOrder] = sort(x);
y = y(iOrder);

% Correct time to zero and amplitude to average to zero.
x = x - x(1);
y = y - mean(y);



X = unique(x);


ny = 1/median(X(2:length(X))-X(1:length(X)-1))/2;



% Calculate the number of frequencies for the fft. We will make it a power
% of 2.This is basically the nyquist divided by the oversampled step rate.

N = 2^nextpow2(X(length(X))*n*k/median(X(2:length(X))-X(1:length(X)-1)));

% Generate the output frequencies and amplitudes for the fft.
f = (0:1:N-1)/X(length(X))/k;
a = zeros(N,1);
z = zeros(N,1);

% Convert x to new system.
x = round(x/x(length(x))*N/k);
z(x+1) = y;


% Calculate the FFT of the generated data.


A = fft(z)*2/length(y);
a = abs(A);




a = a(f<ny);
A = A(f<ny);
f = f(f<ny);



if size(f,1) < size(f,2), f = f'; end
if size(a,1) < size(a,2), a = a'; end

end







