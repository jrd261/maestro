function data = mpdotfit(x,y,e,f)

  m = mgetmodel('polynomial');

  [par,dpar] = mllsqr(m.basis(x,[0 0 0]),y,e);

  data = struct;

  f
  


  data.pdot = 2*par(3)/f;
  data.dpdot = 2*dpar(3)/f;

  
  


	 




end
