function close(obj)
%CLOSE Closes a file object.
%   Attempts to close a file object. If the object isn't open it does NOT
%   throw an error.

% Try to close the file in a try catch loop. If it fails do not report the
% error.
try fclose(obj.FID); catch ME;  end %#ok<NASGU>

obj.FID = -1;
%try fclose(obj.FID); catch ME, end