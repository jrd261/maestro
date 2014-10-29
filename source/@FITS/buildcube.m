function cube = buildcube(FITSList,type)




pid = mprocessinit(['\n Loading ',num2str(length(FITSList)),' images and checking size...']);

switch type
    case 'raw'
        fieldName = 'RawImage';
    case 'calibrated'
        fieldName = 'CalibratedImage';
end

% Initialize the cube.
cube = zeros([size(FITSList(1).RawImage),length(FITSList)]);
for iFile = 1:length(FITSList)
    
    cube(:,:,iFile) = FITSList(iFile).(fieldName);
    FITSList(iFile).clear;
    mprocessupdate(pid,iFile/length(FITSList));
end
mprocessfinish(pid,1);
