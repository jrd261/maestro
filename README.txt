MAESTRO Users Guide
Last Updated: 2011/04/06


________________




Table of Contents


Installation
Ubuntu/Debian
Windows
MATLAB Users
More Information about Installation
Introduction
FAQ
Basic Syntax
Using Maestro
High Speed Photometry Reduction
The Simple Procedure
Star Labeling
Automatic Frequency Finder
Reference
Global Flags


________________




Installation
Ubuntu/Debian
An installation package for Ubuntu/Debian can be downloaded here. Simply double click on the package from your desktop or run “sudo dpkg -i maestro.deb” from the command line. 


Other Linux and Macintosh
Users of other Linux distributions can run the automatic install script. Running this script as root will install Maestro and the MCR for all users. Once installed just run “update-maestro” as root to upgrade to the latest stable release. If you run this script as a user, Maestro will be installed to your user account. You will need to add the scripts contained in “~/.Maestro/program/binaries/” to your path. You must be root to install Maestro on the Mac. 
Windows
Maestro is not available for Windows. Windows users can still use Maestro natively in MATLAB. 
MATLAB Users
You can run the latest source code directly without any formal “installation” if you own a recent copy of MatLab (2008A and above). Extracting the archive (click here if you are unfamiliar with a tar.gz file) will create a directory named “maestro”. To run this code in MATLAB you will need to add the source files located in the sub directory “source” to your MATLAB path. You will also need to set the environment variables “MAESTRO_ROOT_PATH” to the location of the maestro directory and “MAESTRO_USER_PATH” to the location of the sub directory “user” under the maestro directory. 
More Information about Installation
The installation of Maestro consists of four distinct components: 1) The Matlab Component Runtime (MCR), 2) The Maestro binaries/scripts, 3) The program configuration files, 4) The User configuration files. More here soon...


________________
Introduction
FAQ
What is Maestro?
Maestro is a collection of specialized astronomy and physics software written in MatLab. Maestro also supplies some useful astronomy and physics libraries in GNU Octave. 
What exactly does Maestro do?
Maestro was developed to robustly extract light curves from sets of photometric FITS images. Maestro is a large part of the high speed photometry reduction pipeline for the Whole Earth Telescope (WET).   
Do I need a MatLab license?
No.  You can run the Linux binaries with the free MatLab Component Runtime (MCR) and most of the code can be run by GNU Octave.
Why MatLab?
MatLab provides a strong layer of cross platform compatibility, documentation, and built in libraries.
Can I just use GNU Octave? 
No, well sort of. Although MatLab and GNU Octave are extremely similar, the differences between the two are very embedded within the core of how Maestro works at the top level.  However, the bulk of the source code is compatible with GNU Octave so Maestro may provide some useful GNU Octave libraries.
________________


Basic Syntax
 
Running Maestro is as simple as typing:


maestro <command>


Where “<command>” could be something like “help” or “reduce”. For a list of Maestro commands you can type “maestro commands”. You’ll see there that “commands” is itself a command. 


Each command can require arguments.  What the arguments contain (a word,  a number, true/false, etc)  is specific to each particular command and some commands may not allow any arguments at all. The general form for calling a command with arguments is:


maestro <command> <arg1> <arg2> … <argN>  


Commands can also have flags. Each flag may be required or optional and require “flag arguments” as well.  “flag arguments” are just words or numbers that come after a flag. Command flags always come AFTER the command arguments (if any). Here is an example of a made up Maestro command.


maestro dance now --style foxtrot --quickly


The command is “dance”. There is one argument, “now”, and two flags “--style” and “--quickly” were specified. The “style” flag has an flag argument “foxtrot” and the “--quickly” flag has no arguments.  Note that its traditional for flags to have a short name like “-v” and a long name like “--verbose”. 


This is pretty standard in terms of calling programs at the command line. Here is a complete list of flags that can be passed to any Maestro command.
________________


Using Maestro 
High Speed Photometry Reduction
The Simple Procedure
In your data directory create an ASCII list of bias, dark, flat, and object files called biaslist, darklist (optional), flatlist, and objlist respectively. Then, from the directory where the list files are located run “maestro reduce”.  However, if your CCD uses overscan, or the images should be trimmed you will need to build a special configuration and run “maestro reduce -c <your configuration name>”.  
Star Labeling
Identifying which star is which in the output file is of importance. Maestro can automatically sort the order of stars in the output using a “field” file. If you run “maestro buildfield” instead of “maestro reduce” a file with four columns, “name, x, y, amplitude”,  and a row for each star found in this set of images, will be created in ~/.Maestro/fields/. This file will also indicate a fits file to which the star positions are in reference to. Find your target star in this file and move it to the top. Rename the file something relevant. Now if you run “maestro reduce -s <field file name>” the order of the stars in the output files will be set by the field file. 


Output Files


When the reduction is complete a directory (the naming convention for this directory may change) will be created containing files for a range of aperture sizes. These files were designed to work with WQED. These files are labeled with their aperture size in the filename (i.e. counts_4) and contain columns of data “time, star counts 1, sky counts 1, star counts 2, sky counts 2” etc. 
________________
Automatic Frequency Finder
Maestro, given some file with at least two columns containing time and flux, can extract dominant frequencies in the data. Use the command  “maestro ffinder <lightcurvefile> <outfile>” More on this soon! 


Reference
Global Flags
--version                Display  the version of Maestro that is currently installed
The output will be the name of the program version like “maestro R14” or “4.1” followed by a newline (\n). This should be ideal for “grep” statements.
--about                Display information about Maestro
--copyright                Display copyright  information and a statement about the license.
--license                Display  Maestro’s license in full.
-c --config                Specify configuration options (requires a single argument). 
As an argument, specify the name of the configuration that you wish to load. A configuration with a matching name should appear in the Maestro configuration path. If more than one configuration is to be used, use the --c/--config flag more than once but note that the configurations are applied left to right (configuration entries may be overwritten).
-d --debug                Turn debug mode on.
Debug mode is only relevant to developers running Maestro in MatLab. If debug mode is on, persistent variables are not cleared and the user can access them after the program has terminated. To disable debug mode just type “clear all”. 
-h --help                Display the main help information for Maestro.
Is identical to typing “maestro help” and will display some basic information about how to use Maestro.
-q --quiet                 Turns on quiet mode suppressing all output.
-v --verbose                Turns on verbose mode displaying extra information
-l --loud                Turns on loud mode displaying an obnoxious amount of output.
--log-quiet                Turns log to quiet mode (disables logging)
--log-verbose         Turns log to verbose mode.
--log-loud                Turns log to loud mode. May affect performance.