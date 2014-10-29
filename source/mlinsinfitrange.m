function [par,dpar,best_chi2,chi2] = mlinsinfitrange(x,y,e,range)

  model = mgetmodel('linear_sinusoid');
  chi2 = zeros(size(range));
  for i=1:length(range)
    [par,dpar] = mllsqr(model.basis(x,1/range(i)),y,e);
    [par,dpar] = model.translate(par,dpar,1/range(i));    
    chi2(i) = sum(((y-model.evaluate(x,par))./e).^2);
  end

 
  [best_chi2,ind] = min(chi2);

 [par,dpar] = mllsqr(model.basis(x,1/range(ind)),y,e);
 [par,dpar] = model.translate(par,dpar,1/range(ind));    
	 
end
