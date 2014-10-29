function c = mcellstr(s)
%CELLSTR Create cell array of strings from character array.
%   C = CELLSTR(S) places each row of the character array S into 
%   separate cells of C.
%
%   Use CHAR to convert back.
%
%   Another way to create a cell array of strings is by using the curly
%   braces: 
%      C = {'hello' 'yes' 'no' 'goodbye'};
%
%   See also STRINGS, CHAR, ISCELLSTR.

%   Copyright 1984-2006 The MathWorks, Inc.
%   $Revision: 1.16.4.8 $  $Date: 2006/06/20 20:12:41 $
%==============================================================================


        
		[rows,cols]=size(s);%#ok ignore rows
		c = cell(rows,1);	
		for i=1:rows
            c{i} = s(i,:);
		end
	

%==============================================================================