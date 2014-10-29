function [f,a] = mdft(x,y,fmin,fmax,sr)

[junk,o] = sort(x); %#ok<ASGLU>
x = x(o);
y = y(o);

x = x - min(x);
y = y - mean(y);


if nargin < 5, sr = 1/max(x)/20; end
if nargin < 4, fmax = 1/median(x(2:length(x))-x(1:length(x)-1))/2; end
if nargin < 3, fmin = 0; end



f = fmin:sr:fmax;
a = zeros(size(f));
pid = mprocessinit('\nPerforming DFT...');

for iFreq = 1:length(f)
    
    
    a(iFreq) = 2/length(x)*sum(y.*(cos(2*pi*f(iFreq)*x)-1i*sin(2*pi*f(iFreq)*x)));
    
    
    
    
    
    
    mprocessupdate(pid,iFreq/length(f));
    
end
mprocessfinish(pid,1);










end