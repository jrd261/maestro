function data = mpdottranslate(par,dpar,f)

  data = struct;

  data.offset = par(1);
  data.doffset = dpar(1);

  data.f = f - par(2)*f;
  data.df = dpar(2)*f;   

  data.pdot = 2*par(3)/f;
  data.dpdot = 2*dpar(3)/f;

  data.fdot = -data.pdot*f^2;
  data.dfdot = data.dpdot*f^2;
      	 

end
