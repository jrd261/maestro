function waswritten = mtalk(message,volume,dolog)
%MTALK Displays a message to the user in MAESTRO.
%   MTALK(MESSAGE) will write a message if the volume is above standard. This will be printed out with no modification.
%
%   MTALK(MESSAGE,VOLUME) will write a message if the volume is above VOLUME.
%
%   MTALK(MESSAGE,VOLUME,DOLOG) indicates whether or not the message should also be logged.
%
%   WASWRITTEN = MTALK(...) writes out WASWRITTEN, which is boolean and indicates if the message was actually written out.
%
%   Example:
%       MTALK('Hello, this is a verbose message in MAESTRO',2)
%
%   See also MVOLUME, MLOG, MLOGVOLUME
%
%   Copyright (C) 2009-2010 James Dalessio

% Find the volume of the message.
if nargin<2, volume = 1; end

% Find whether or not we are logging the message. If it is not specified we will not try to write the message to log.
if nargin<3, dolog = false; end

% Find out whether we will write the message and write it.
if mvolume>=volume, waswritten=true; fprintf(message); else waswritten = false; end

% Log the message if neccessary.

%if dolog, mlog('write',message,volume); end