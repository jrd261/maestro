function cmd_saao2wqed(args)
%CMD_SAAO2WQED Summary of this function goes here
%   Detailed explanation goes here


fid = fopen(args.fileName{1});


runName= fscanf(fid,'%s',1);
targetName= fscanf(fid,'%s',1);
day= fscanf(fid,'%s',1);
month= fscanf(fid,'%s',1);
year= fscanf(fid,'%s',1);
hour= fscanf(fid,'%s',1);
minute= fscanf(fid,'%s',1);
second= fscanf(fid,'%s',1);
hjd = fscanf(fid,'%s',1);
exptime= fscanf(fid,'%s',1);
npts= fscanf(fid,'%s',1);
nchannels = fscanf(fid,'%s',1);


date = ['19',year,'-',month,'-',day,'T',hour,':',minute,':',second];
dn = datenum(date,'yyyy-mm-ddTHH:MM:SS');
dn = dn + str2double(exptime)/86400/2;

date_out = datestr(dn,'yyyy-mm-dd');
time_out = datestr(dn,'HH:MM:SS');

j = 1;
times = 0:str2double(exptime):str2double(npts)*str2double(exptime);
counts = zeros(size(times));
pid = mprocessinit('Reading in file...');
while(1) 
    mprocessupdate(pid,j/str2double(npts))
    for i=1:10
        counts(j) = str2double(fscanf(fid,'%s',1));        
      j = j + 1;  
      
    end
    if j> str2double(npts), break, end
    LN = fscanf(fid,'%s',1);
end
mprocessfinish(pid,1)


fclose(fid);


fid = fopen(args.outFileName{1},'w');
fprintf(fid,'#Date = ');
fprintf(fid,date_out);
fprintf(fid,'\n');
fprintf(fid,'#UTC = ');
fprintf(fid,time_out);
fprintf(fid,'\n');
fprintf(fid,'#Object = ');
fprintf(fid,targetName);
fprintf(fid,'\n');
for i=1:length(times)   
    fprintf(fid,num2str(times(i)));
    fprintf(fid,'\t');
    fprintf(fid,num2str(counts(i)));
    fprintf(fid,'\t');
    fprintf(fid,'1\t1\t1\n');
end



end

