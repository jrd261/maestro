function data = mlinsinpartranslate(par,dpar,f)

  data = struct;

  data.offset = par(1);
  data.doffset = dpar(1);

  data.f = f - par(2)*f;
  data.df = dpar(2)*f;   

  data.pdot = 2*par(3)/f;
  data.dpdot = 2*dpar(3)/f;

  data.fdot = -data.pdot*f^2;
  data.dfdot = data.dpdot*f^2;

  data.Pi = 1/par(5);
  data.dPi = dpar(5)/f^2;
    
  data.alpha = 2*pi*f/data.Pi*par(4);
  data.dalpha = 2*pi*f/data.Pi*dpar(4);

  data.phi = par(6)/data.Pi*360 + 90;
  data.dphi = dpar(6)/data.Pi*360;        

  if data.phi > 180
     data.phi = data.phi - 360;
  end

end
