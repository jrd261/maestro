function data = mloadtimeseries(FileName)
	 
  [path,name,ext] = fileparts(FileName);
  
  if any(strcmp(ext,{'.lc','.lc1','.bdy'}))     
    data = mwqedload(FileName);
  else
    data = str2double(mread(FileName));
  end	 


end
