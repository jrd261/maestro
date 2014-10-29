function [bpar,bdpar,best_chi2,chi2] = mfitlinsin(x,y,e,p)

  model = mgetmodel('linear_sinusoid');
  chi2 = zeros(size(p));

  for i=1:length(p)
    [par,dpar] = mllsqr(model.basis(x,1/p(i)),y,e);
    [par,dpar] = model.translate(par,dpar,1/p(i));
    chi2(i) = sum(((y-model.evaluate(x,par))./e).^2);
  end

  


aiminima = find(chi2(1:length(chi2)-2) > chi2(2:length(chi2)-1) & chi2(3:length(chi2)) > chi2(2:length(chi2)-1));
[best_chi2,ind] = min(chi2(aiminima));
pp = p(aiminima);
P = pp(ind);

if isempty(P)
   fprintf('NO MINIMUM FOUND');


[best_chi2,ind] = min(chi2);
P = p(ind);
end



[par,dpar] = mllsqr(model.basis(x,1/P),y,e);
[bpar,bdpar] = model.translate(par,dpar,1/P);

  
  
	 
end
