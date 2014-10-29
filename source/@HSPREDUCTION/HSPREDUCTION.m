classdef HSPREDUCTION < handle
    %REDUCTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties                      
        
        FITSList
        MaestroConfiguration
        
        
        %% STORAGE FOR FAILURE INFORMATION
        % liCorruptFiles (nx1 logical) 
        % liStarOffImage (nxm logical) 
        % liGoodIndicies (nxm logical)
        liCorruptFiles
        liStarOffImage
        liGoodIndicies         
        % These properties store information about which files had problems
        % and which stars were off image.
        %
        % liCorruptFiles: Contains logical indicies referencing the FITS
        % objects which had problems. This is initialized when the reduction is started.              
        %
        % liStarOffImage: Contains logical indicies referencing the the
        % image in the y direction and the star in the x direction for
        % stars that were off of the image. This is initialized when the
        % photometry is performed. 
        %
        % liGoodIndicies: Contains logical indicies referring to the
        % inverse of the combination of all failures. This is the easiest
        % way to reference the final data product. This is generated when
        % the reduction is completed.
                
                        
        %% MASTER FIELD INFORMATION
        % .MasterFieldArray (mx1 struct)
        %       .JulianDate (double)
        %       .Geometry (10xn double)
        %       .Labels {nx1 string}
        %       .RotationStyle (double)
        %       .RotationFlipindex (double)
        %       .RotationIsFlipInverted (bool)       
        %       .FieldName (string)
        MasterFieldArray = struct('JulianDate',[],'Geometry',zeros(10,0),'Labels',{},'RotationStyle',[],'RotationFlipIndex',[],'RotationIsFlipInverted',false,'FieldName','');
        % The master field array contains all information about each master
        % field. Note that there can be more than one master field and these are stored in. Also stored here is
        % information about how the master field is oriented to the object
        % images and the total number of master fields. Note that the
        % master field can be populated many different ways. For example a
        % master field can be built from some images currently in maestro.
        % A master field can also be built from clicking on stars from some
        % master image, or from some saved ascii file.              
                           
        %% FIELD SOLUTIONS
        % .FieldSolutions (mx1)
        %       .WasFound (boolean)
        %       .FieldIndex (double)       
        %       .xxTranslation (double)
        %       .dxTranslation (double)
        %       .yyTranslation (double)
        %       .dyTranslation (double)
        %       .mmRatio (double)
        %       .dmRatio (double)
        %       .nHashSources (double)
        %       .nTotalMatches (double)
        %       .RotationStyle (double)
        %       .GoodStaritude (double)
        %       .BadStaritude (double)
        %       .TranslationalRC2 (double)
        %       .ScalingAC2 (double)
        FieldSolutions= struct('WasFound',false,'FieldIndex',[],'xxTranslation',[],'dxTranslation',[],'yyTranslation',[],'dyTranslation',[],'mmRatio',[],'dmRatio',[],'nHashSources',[],'RotationStyle',[],'GoodStaritude',[],'BadStaritude',[],'TranslationalRC2',[],'ScalingAC2',[])
        % The field solutions array stores information about how the master
        % fields are geometrically related to each image in the FITS list. 
        
        
         %% FILE INFORMATION        
        % .FileObject (1x1 FILE)
        FileObject = FILE;
        % The file object will store the location of the reduction                                 
       
        %% CENTERING DATA
        % .CenteringData 
        %       .XX (mxn)
        %       .YY (mxn)       
        %       .FitParameters (mxnxj)
        %       .FitCovariance (mxnxjxj) (Or other depending on the model)     
        CenteringData
        
        %% APERTURE DATA
        % .ApertureData 
        %       .Sizes (kx1)
        %       .Area (mxnxk)
        %       .Counts (mxnxk)
        %       .Noise (mxnxk)
        %       .Sky (mxn)
        ApertureData                                          
      
    end
    
  
    
end

