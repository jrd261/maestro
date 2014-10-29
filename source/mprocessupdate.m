function  mprocessupdate(pid,percentage)
%MPROGRESSUPDATE Summary of this function goes here
%   Detailed explanation goes here


global MAESTRO_PROCESS_DATA

MAESTRO_PROCESS_DATA(pid).PERCENTAGE = percentage;

if(mvolume==1 && (percentage-MAESTRO_PROCESS_DATA(pid).LASTPERCENTAGE) > .01)
    MAESTRO_PROCESS_DATA(pid).LASTPERCENTAGE = percentage;
   % MAESTRO_PROCESS_DATA(pid).LASTTIME = now;    
    percentString = num2str(percentage*100,'%2.0f');
    if length(percentString)<2, percentString = ['0',percentString]; elseif(length(percentString)==3); percentString = '99'; end
    mtalk(['\b\b\b\b\b',percentString,'%% ]'],1,false);
end

