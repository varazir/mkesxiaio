UPDATE!!!
I have added 2 options to create a USB boot / USB installation
without changing anything to the media


Version 2.0
Changed some functions to be shared.
Made so the folder names can be changed more easier using a array


Version 2.1
Added so you can choose if you like to add SSH, FTP
Added the installation of wget


Version 2.2
Added so the folders that is created in this script get the right ownership


Version 2.3
Added a question to edit the proftd.conf file if need be


Version 2.4
Bug fixes with the no custom files part


Version 2.5
Added option to edit the simple.map and pci.ids


Version 2.6
Added download of new Wget and Rsync from vm-help.com


Version 2.7
Added unzip and ed to the installation list
Changed so N is default on all questions
Changed the order of the USB selection,
The question to continue comes after you have selected the device
Changed the udevinfo to udevadm info so it will work in 9.x version of Ubuntu


Version 2.8
Added a check for the apt-get and if it's not there it will ask for the install command line
Added a check for the binaries needed in the script
Changed to Joe is the standard editor


Version 2.9
Added a test before copy the files from the ISO file


Version 3.0
Changed so the binary used in the script can be changed in esx\_pkg\_install array


Version 3.1
Added a redo function so the user can create another USB installation
Fixed so the awk in the fdisk part search for bytes


Version 3.2
Fixed a bug and made so option no 4 can be used for ESXi 4


Version 3.3
Added ESXi 4.0 support for ISO and USB installation , should work with the running from USB
ESXi there is no support for enable SSH and FTP or edit the simple and pci files.


Version 3.4
Added support for custom OEM file, ftp, ssh and edit files for ESXi 4


Version 3.5
Added a select option for 3.5 and 4.0


Version 3.6
Some bug fixes and check for the language problem at fdisk


Version 3.7
Some bug fixes around the language fdisk check


Version 3.8
Added shopt -s dotglob to inc hidden folders
Added a option to edit the inetd.conf and a check if there is one in the OEM folder already
Added option to skip wget and rsync.
Added custom-esx folder where you can place files you like to add to the OEM file. extra drivers


Version 3.9
Added option för running the script non interactiv
OBS It works ONLY if you have one oem/iso file in the same dir as the script
OBS It works ONLY in Enlish Ubuntu/debian


Version 3.9.1
Added udevadm into a $esx\_usb\_check\_cmd and replced it in the function NOT TESTED

Version 3.9.2
Add support for 4.1

Version 3.9.3
Changed the non english systems part, hard set esx\_bytes=512

Version 3.9.4
Bug fix, adding the oem.tgz into the isolinux.cfg failed due to change in names of the other files

Version 3.9.5
Changed so the dd push would work

Version 3.9.6
Fixed bug in the non english and the dd copy that I added in 3.9.5

Version 3.9.7
Removed old code that isn't in use and fixed a bug in the ISO finish part of the script

Version 3.9.8
USB installation stoped working so I added a new command to add the bootflag to the device  and some smal text changes to the menus


Version 3.9.9
New way the inetd.conf is handel in 4.1.
Removed the need for inetd.conf for all versions