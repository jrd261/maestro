function value = mextractheadervalue(keyvalcom,keyword,regex)
%MEXTRACTHEADERVALUE Extract a FITS keyword value.
%   Given a FITS header imported into the keyvalcom nx3 cell array of
%   strings format, this will extract the value of the first appearance of
%   the given keyword.
%
%   VALUE = MEXTRACTHEADERVALUE(KEYVALCOM,KEYWORD) specifies the
%   KEYVALCOM cell array and the targeted KEYWORD.
%
%   KEYVALCOM is an nx3 cell array typically generated by reading in a FITS
%   header. The first column is the keywords, the second is the values, and
%   the third is the comments.
%
%   KEYWORD is a string that should be one of the keyword entries in the
%   KEYVALCOM section.
%
%   VALUE will contain a string corresponding to the entry in the KEYVALCOM
%   cell array will the keyword KEYWORD.
%
%   Example:
%       KEYVALCOM = importfitsheader('testfile.fits'); 
%       KEYWORD = 'DATE-OBS'; 
%       VALUE = MEXTRACTHEADERVALUE(KEYVALCOM,KEYWORD)
%
%   See also IMPORTFITSHEADER
%
%   Copyright (C) 2009-2010 James Dalessio

% Extract the value. 
 aiMatches = find(strcmp(keyvalcom(:,1),keyword),1);

% If it is empty, throw an error.
if isempty(aiMatches), error('MAESTRO:mextractheadervalue:noMatches',['Error extracting fits header value. Could not find any matches for keyword ',keyword,'.']), end
value = keyvalcom{aiMatches,2}; 
if nargin==3, value = regexp(value,regex,'match');  value = value{1}; end
if isempty(value), error('MAESTRO:mextractheadervalue:noMatches','Error extracting fits header value. No match to regular expression.'), end
