classdef FIELD < handle
    %FIELD A geometric arrangement of objects.
    %   An object that stores information about the geometric relationship
    %   between stars or other objects in a set of images.
    %
    %   Copyright (C) 2007-2011 James Dalessio
    
    properties
        
        JulianDate  = [];
                             
        StaticGeometry = zeros(0,8); % XX,YY,ZZ,SS,DX,DY,DZ,DS                
        
        Labels = {};
        
        Signal = 0; 
        Noise = Inf;
        Range = [1,1,1,1];               
        
        Rotation = zeros(0,2);
        
    end
    
    methods
        function save(obj)
        end
        function load(obj)
        end
        
    end
end