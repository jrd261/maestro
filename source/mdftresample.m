function h = mdftplot(axes,x,y,fmin,fmax,n,varargin)



[f,a] = mfastperiodogram(x,y);

a(f<fmin) = [];
f(f<fmin) = [];

a(f>fmax) = [];
f(f>fmax) = [];

df = (fmax-fmin)/(n-1);

aa = zeros(n,1);
ff = (fmin:df:fmax)';

for i=1:length(ff)

  aa(i) = max(a(f > ff(i) - df & f < ff(i) + df));


end



h = area(axes,ff,aa,varargin{:});






end

