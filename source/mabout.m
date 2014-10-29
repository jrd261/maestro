function text = mabout
%MABOUT returns a brief description of the program.
%   TEXT = MABOUT will return information about maestro in MAESTROINFO. MAESTROINFO will be a string.
%
%   Example: 
%       TEXT = MABOUT
%
%   See also MVERSION, MCOPYRIGHT
%
%   Copyright (C) 2007-2010 James Dalessio

text = 'MAESTRO was developed as the data reduction pipeline of the Whole Earth Telescope by the Delaware Asteroseismology Research Center.\n\n';

% Generate information about MAESTRO.
text = [mcopyright,text];