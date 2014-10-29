function mklc2lc(filename,n)

  if nargin < 2
    n = 5;
  end

  file = FILE(filename);
  [path,name,ext] = fileparts(file.FullName);
  data = fitsread(file.FullName,'BinTable');
  header = fitsinfo(file.FullName);
  BJED_I = header.BinaryTable.Keywords{strcmp(header.BinaryTable.Keywords(:,1),'BJDREFI'),2};
  BJED_F = header.BinaryTable.Keywords{strcmp(header.BinaryTable.Keywords(:,1),'BJDREFF'),2};

  X = data{1} + BJED_I + BJED_F;
  Y = data{4};

  X(isnan(Y)) = [];
  Y(isnan(Y)) = [];

  li_bad = (Y-nanmedian(Y))/mrobuststd(Y) > n;

  X(li_bad) = [];
  Y(li_bad) = [];

  XX = X-mean(X);

  par = polyfit(XX,Y,2);

  Y = Y./polyval(par,XX) - 1;

  outfile = [path filesep name '.bjed'];
  outdata = [X,Y];

  save(outfile,'outdata','-ASCII','-DOUBLE');

  
  



end
