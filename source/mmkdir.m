function mmkdir(directoryName)

% Check if the directory exists.
if ~exist(directoryName,'dir')
    if ~mkdir(directoryName)
        error('MAESTRO:mmkdir:mkdirFail',['Error creating output directory "',directoryName,'". The path may not be writable or cannot be parsed by the system.']);
    end
    if ~exist(directoryName,'dir'), error('MAESTRO:mmkdir:fileExists','Cannot make directory with same name as a file.'); end

    
end  



end

