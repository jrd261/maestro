function text = mcopyright
%MCOPYRIGHT returns a brief copyright notice
%   TEXT = MCOPYRIGHT will return information about the copyrights of MAESTRO
%
%   Example: 
%       TEXT = MCOPYRIGHT
%
%   See also MVERSION, MABOUT
%
%   Copyright (C) 2007-2010 James Dalessio

% Generate copyright information about MAESTRO.
text = ['\n ------------------------------------------------------------------------------ \n|               Maestro: The Matlab Astronomy Toolkit ',mversion,'                 |\n|                   Copyright (C) 2007-2011 James Dalessio                     |\n'...
    ' ------------------------------------------------------------------------------ \n'];