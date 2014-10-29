function [a,da,rchi2] = mweighteddft(x,y,e,f)

	 
  m = mgetmodel('linear_sinusoid');
  a = zeros(size(f));
  da = zeros(size(f));
  rchi2 = zeros(size(f));

  for i=1:length(f)
    [par,dpar] = mllsqr(m.basis(x,f(i)),y,e);
    [par,dpar] = m.translate(par,dpar,f(i));
    rchi2(i) = sum((y-m.evaluate(x,par)).^2./e.^2)/(length(x)-3);
    a(i) = par(1);
    da(i) = dpar(1);
  end
  
  

end
