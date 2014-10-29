function reducedev(HSPReduction)
%REDUCE Executes a high speed photometry reduction.
%   This is a top level function that will call several other class methods
%   to execute the reduction. 
%
%   Copyright (C) 2010-2011 James Dalessio


%% LOCK IN CRITICAL INFORMATION
% Before the reduction begins we want to fix the configuration and the list
% of FITS files for the reduction. As the MAESTRO configuration and the
% FITS list are dynamic this would allow changes in the programs internal
% copy of FITS files and configuration to change without impacting the
% reduction. It will also allow us to store the configuration and FITS list
% with the reduction when saved. When this method is executed it is assumed
% that we are reducing from scratch as oppose to rereducing which would
% want to use the options already stored here.
HSPReduction.MaestroConfiguration = mconfig;
mtalk('\n\nBUILDING MASTER FIELD');

%% BUILD A MASTER FIELD
% No matter the method we are using to reduce the data the building of a
% master field is neccessary. This will cycle through all images and build
% a list of "geometries" or star positions that appear of the images.
% This also determines if the images are rotating or if they suddenly
% flip.
HSPReduction.FITSList = mfits('RETRIEVE','OBJECT');
HSPReduction.MaestroConfiguration = mconfig;
HSPReduction.buildmasterfields5;

HSPReduction.labelfield3;
%% CHOOSE A MASTER FIELD
% This will select the master field that will be used to aquire the images.
% There are several ways that a master field will be chosen. See the
% function for more information.
%HSPReduction.choosemasterfield;

%% OBTAIN GEOMETRIC SOLUTIONS
% While some solutions were likely already found when the master fields
% were built this will attempt to figure out the relative geometry from
% each of the images to the chosen master field.

%HSPReduction.aquirefieldsolutions2;

%% REDUCE THE IMAGES
% This method will center the stars and perform aperture
% photometry.

mtalk('\n\nREDUCTING THE DATA SET');
%HSPReduction.dophotometry2;
HSPReduction.aquireandreduce;



