#!/bin/bash
#exec > >(tee vars1.log) 2>&1
#set -x
#set logs.log


#	INFO
#	All you now need is to download this file and the vmware ESXi ISO file
#	sudo chmod +x mkesxiaio_x.x.sh
#	sudo ./mkesxiaio_x.x.sh
#
#	You may need to download a extra file like inetd.conf
#
#	You need 2GB of free space to run the script 
#
#	Then you need a blank USB drive minimum 1GB OBS if this script
#	breaks your USB drive or you loose DATA don't blame me.
#	There will be warnings before anything happens to the USB drive.
#
#	I will test all installations types(script) on my Ubuntu system
#
#
	

####################Contact information####################
#
#	You can find me on Vmware's forum or www.vm-help.com/forum/index.php as Varazir
#	E-mail varazir@gmail.com
#		


#	UPDATE!!!
#	I have added 2 options to create a USB boot / USB installation 
#	without changing anything to the media
#

#	Version 2.0 
#	Changed some functions to be shared.
#	Made so the folder names can be changed more easier using a array 
#

#	Version 2.1
#	Added so you can choose if you like to add SSH, FTP 
#	Added the installation of wget
#

#	Version 2.2
#	Added so the folders that is created in this script get the right ownership 
#

#	Version 2.3
#	Added a question to edit the proftd.conf file if need be
#

#	Version 2.4
#	Bug fixes with the no custom files part 
#

#	Version 2.5
#	Added option to edit the simple.map and pci.ids
#

#	Version 2.6
#	Added download of new Wget and Rsync from vm-help.com
#

#	Version 2.7
#	Added unzip and ed to the installation list
#	Changed so N is default on all questions
#	Changed the order of the USB selection, 
#	The question to continue comes after you have selected the device
#	Changed the udevinfo to udevadm info so it will work in 9.x version of Ubuntu 
#

#	Version 2.8
#	Added a check for the apt-get and if it's not there it will ask for the install command line
#	Added a check for the binaries needed in the script
#	Changed to Joe is the standard editor
#

#	Version 2.9
#	Added a test before copy the files from the ISO file
#

#	Version 3.0
#	Changed so the binary used in the script can be changed in esx_pkg_install array 
#	

#	Version 3.1
#	Added a redo function so the user can create another USB installation 
#	Fixed so the awk in the fdisk part search for bytes 
#

#	Version 3.2
#	Fixed a bug and made so option no 4 can be used for ESXi 4
#

#	Version 3.3
#	Added ESXi 4.0 support for ISO and USB installation , should work with the running from USB 
#	ESXi there is no support for enable SSH and FTP or edit the simple and pci files.
#

#	Version 3.4
#	Added support for custom OEM file, ftp, ssh and edit files for ESXi 4
#	

#	Version 3.5
#	Added a select option for 3.5 and 4.0
#

#	Version 3.6
#	Some bug fixes and check for the language problem at fdisk
#

#	Version 3.7
#	Some bug fixes around the language fdisk check 
#

#	Version 3.8
#	Added shopt -s dotglob to inc hidden folders 
#	Added a option to edit the inetd.conf and a check if there is one in the OEM folder already
#	Added option to skip wget and rsync.
#	Added custom-esx folder where you can place files you like to add to the OEM file. extra drivers 
#

#	Version 3.9
#	Added option för running the script non interactiv 
#	OBS It works ONLY if you have one oem/iso file in the same dir as the script
#	OBS It works ONLY in Enlish Ubuntu/debian 
#

#	Version 3.9.1
#	Added udevadm into a $esx_usb_check_cmd and replced it in the function NOT TESTED 
#

#	Version 3.9.2 
#	Add support for 4.1 
#

#	Version 3.9.3
#	Changed the non english systems part, hard set esx_bytes=512
#

#	Version 3.9.4
#	Bug fix, adding the oem.tgz into the isolinux.cfg failed due to change in names of the other files
#

#	Version 3.9.5
#	Changed so the dd push would work
#

#	Version 3.9.6
#	Fixed bug in the non english and the dd copy that I added in 3.9.5
#

#	Version 3.9.7
#	Fixed bug in the non english ( cleaned up the code abit ) and bug in the ISO finish part. 
#


#  Array
esx_folders=(									#	Work folders (Array)
esx-cd 											#0	Mount point for the ISO file will
esx-temp 										#1	Where the install.tgz will be extracted
esx-ienv 										#2	Where the ienviron.tgz will be extracted
esx-oem 										#3	Where the OEM file will be extracted
esx-5 											#4	Mount point for the dd file
esx-build										#5	The work folder
esx-usb											#6	Mount point for the USB drive
esx-ftp											#7	Where the proftpd.zip will be extracted
)

esx_pkg_install=( 								#	Pkg's that is needed for this script (Array)
mkisofs		 									#0	Needed to create the ISO file
syslinux 										#1	Needed to make the USB drive bootable
wget											#2	To download the proftp server from vm-help 
unzip											#3	For the installation of proftp
ed												#4	Used to edit text inside files
nano											#5	Used to manually edit files
tar												#6	Used to extract files from compressed files 
bzip2											#7	Used to compress the dd file 
bunzip2										#8	Used to extract bz2 files
md5sum											#9	To create the hash file for 4.1 
parted											#10	add the Boot flag to the USB 
)
#udevadm										#9	Needed to check for USB devices


esx_menu=(										#	For case menus (Array)
"ISO installation"								#0	To create a ISO file to burn on a CD for installation
"USB installation"								#1	Creates custom made files that can be copied to a bootable USB drive for installation
"USB boot"										#2	Creates a custom DD file that can be written to a USB to boot and run ESXi
"USB installation without custom files"			#3	Copies the files from the ISO and make the USB bootable
"USB boot without custom files"					#4	Extract the DD and writes it to a USB drive to boot and run ESXi
"Exit!"											#5	Just exiting the script
"FTP support"									#6	If there are going to be FTP support enabled
"SSH support  DO NOT USE WITH 4.1"				#7	If there are going to be SSH support enabled
"SSH + FTP support   DO NOT USE WITH 4.1"		#8	If there are going to be FTP and SSH support enabled
"Continue without any of them"					#9	Exit the ssh/ftp menu without doing anything
"Installing ${esx_pkg_install[*]}"				#10	Install app info
)

esx_version=(
"4.1"
"4.0"
"3.5"
)

esx_auto_com=(
--a						#0	Need to be there to run the script non interactiv
--s						#1	If you like to enable ONLY SSH
--e						#2	If you like downloading wget and rsync from vm-help.com
--c						#3	If you have more files in the custom-esx folder
--v						#4	Version you are going to make
--d						#5	USB device 
--i						#6	Installtion typ
--h						#7	Help
)
esx_auto_exe=(
esxi_auto_a					#0
esxi_add_ssh_ftp_menu_s		#1
esxi_add_ssh_ftp_e			#2
esxi_add_ssh_ftp_c			#3
esxi_version				#4
esxi_esx_usb_install		#5
esxi_auto_dest				#6
esxi_help					#7
)

esx_auto_help=(				#	The help text 
"Need to be there to run the script non interactiv"
"If you like to enable SSH FTP or No eg. --s=SSH --s=SSHFTP --s=FTP defult is No"
"Downloading wget and rsync from vm-help.com."
"If you have more files in the custom-esx folder."
"Version you are going to create 3.5 , 4.0 or 4.1 eg. --v=4.1 "
"If you are creating a USB installtion or boot. ONLY used with --i=USB or --i=DD  --d=/dev/ "
"Installtion typ ISO USB(install from USB) DD (Boot from USB)"
"This help"
)

#	Variables 

ipath="$PWD"									#	Work path
esx_custom="VMware_esxi_custom_"				#	The name of the custom made file/folder
esx_save="save"									#	The folder where the custom file/folder will be  saved
custom_esx="custom-esx"							#	Add files in custom-esx that is going to be in the oem.tgz file.
esx_ibin="apt-get -qq -y --force-yes install"	#	The command string used to install 
esx_bytes="bytes"								#	The default search parameter in the fdisk function
esx_usb_check_cmd="udevadm"
#	Extra options 

shopt -s dotglob								#	To make * include hidden folders/files 

#	Functions

function esxi_auto_a(){

esx_auto=1

}

function esxi_HaveOpt() {			#	To grep the flags used when running the script noninteractiv 
  local needle=$1
  shift
  while [[ $1 == -* ]]; do
    case "$1" in
		--) return 1;; # by convention, -- is end of options
		"$needle="*) echo "${1#"$needle="}"; return 0;;
		"$needle") return 0 ;;
    esac
    shift
  done
  return 1
}

function esxi_file_name(){			#	Sets the name on the file / folder $esx_finish
	esx_finish="$esx_custom${esx_oem_file%*.tgz}.$esx_inst_type"
}

function esxi_done() {				#	The [Done] echo after every step
	echo -e "\e[01;32m	[\e[00mDone\e[01;32m]\e[00m"
}

function esxi_green() {				#	Change the text to Green
	printf "\e[01;32m$*\e[00m"
}

function esxi_red() {				#	Change the text to red
	printf "\e[00;31m$*\e[00m"
}

function esxi_version() {			#	Version ? $esxi
	
	clear 							#	Clear the screen.
	
	if [[ -z $esx_auto ]]
		then
			esxi_green  "  Which version of ESXi are you going to do "
			echo
			esxi_green  "  [1] ${esx_version[2]}"
			echo
			esxi_green  "  [2] ${esx_version[1]}"
			echo
			esxi_green  "  [3] ${esx_version[0]}"
			echo
			esxi_green  "  Choose what you like to do: "
			read esx_ver
		else
			if [[ -z $esx_ver ]]
				then
					esx_ver=$1
			fi
	fi
	
	if [[ -z $esx_ver ]]
		then 
			esxi_red "You need to define the version of ESXi you like to create "
			sleep 4
			clear
			exit
	fi

	case "$esx_ver" in
		2 | 4.0 ) 
			esxi="4.0"
			clear
		;;
		1 | 3.5 )
			esxi="3.5"
			clear
		;;
		3 | 4.1 )
			esxi="4.0"
			esxi1="4.1"
			clear
		;;
		* )
			esxi_red "That's not a valid option"
			sleep 1
			clear 					#	Clear the screen.
			esxi_version			#	Loop the menu
		;;
	esac
}

function esxi_check() {				#	Checking for files $esx_file
	cd $ipath
	shopt -s nullglob
		esx_check_files=($2)							#	Creating a array if there is more then one file
		
		if [[ ${#esx_check_files[@]} == 0 ]]
			then
				clear 							#	Clear the screen.
				echo
				esxi_red "	No $1 file..  Exiting"
				echo
				sleep 5
				clear 							#	Clear the screen.
				esxi_clean
				exit 0
		fi
	shopt -u nullglob
	
	if [ "${#esx_check_files[@]}" -gt 1 ]				#	If there is more then one file
		then
			esx_check_files[100]="Exit"
			esxi_check_menu ${esx_check_files[@]:0}
		else
			esx_file="${esx_check_files[*]}"
	fi
}

function esxi_check_menu() {		#	Checking for files menu
	
	clear 							#	Clear the screen.
	
	PS3='With file are you going to use ?  '

	printf "There are more then one ${esx_check[0]} file"
	echo

	select esx_check_files 

	do
		if [ -z $esx_check_files ]
			then
				clear 							#	Clear the screen.
				esxi_check "${esx_check[@]:0}"
				clear 							#	Clear the screen.
			else	
				if [ "$esx_check_files" = "Exit" ]
					then
						clear 							#	Clear the screen.
						echo
						esxi_red "Exiting ...."
						echo
						echo
						sleep 2
						esxi_clean
						clear 							#	Clear the screen.
						exit 0
					else
						esx_file="$esx_check_files"
				fi
		fi
	break
	done
	clear
}

function esxi_check_iso() {			#	Check if there is more then one iso file $esx_iso_file 
	esx_check=(ISO "*.iso")
	esxi_check "${esx_check[@]:0}"
	esx_iso_file="$esx_file"
	
	if [[ $esxi == "4.0" ]]
		then
			if [[ $esxi1 == "4.1" ]]
				then
					esx_custom=${esx_custom}${esxi1}_
				else
					esx_custom=${esx_custom}${esxi}_
			fi
		else
			esx_iso_file_temp=${esx_iso_file#*_}
			esx_update=${esx_iso_file_temp%-*}
			esx_custom=${esx_custom}${esx_update}_
	fi
}

function esxi_check_oem() {			#	Check if there is more then one oem $esx_oem_file 
	esx_check=("OEM" "*oem*.*")
	esxi_check "${esx_check[@]:0}"
	esx_oem_file="$esx_file"
}

function esxi_check_inetd() {		#	Check if there is a inetd file $esx_inetd_file
	esx_check=(inetd.conf "*inetd*")
	esxi_check "${esx_check[@]:0}"
	esx_inetd_file="$esx_file"
}

function esxi_menu() {				#	Main menu $esx_inst_type 1.ISO 2.USB 3.DD FILES

	clear 							# 	Clear the screen.
	
	if [[ -z $esx_auto ]]
		then
			echo
			esxi_green " Adding customized files to a VMware ESXi installation"
			echo
			echo
			esxi_green " Using $esx_iso_file" 
			echo
			echo
			esxi_green  "  [1] ${esx_menu[0]}"
			echo
			esxi_green  "  [2] ${esx_menu[1]}"
			echo
			esxi_green  "  [3] ${esx_menu[2]}"
			echo
			esxi_green  "  [4] ${esx_menu[3]}"
			echo
			esxi_green  "  [5] ${esx_menu[4]}"
			echo
			esxi_green  "  [6] ${esx_menu[5]}"
			echo
			esxi_green " Choose what you like to do: "
			read menu
			clear
		else 
			if [[ -z $1 ]]
				then
					esxi_red "You have to set type of installtion"
					echo
					sleep 3
					exit
				else
					menu=$1
			fi
	fi

	case "$menu" in
		1 | ISO | iso )
			esx_inst_type="iso"		#	Setting the installation type to ISO
			esxi_check_oem			#	Check witch OEM file to use
			esxi_cd					#	Copy the files from the iso file
			esxi_add_ssh_ftp		#	Adds SSH or FTP or both to the inetd.conf and copy it into the oem file
			esxi_file_name			#	Set's the file/folder name
			esxi_check_old			#	Check if there is any iso/dd/folder created with this custom files
			esxi_dd_start			#	Extract the DD file
			esxi_dd_end				#	Uncompress the dd and mount it. Uncompress environ.tgz copy inetd.conf. 
									#	Copy the OEM file and unmount, Compress the dd file and rebuild the install.tgz copy the OEM file
			esxi_iso_finish			#	Making the ISO file
			esxi_clean
		;;

		2 | USB | usb )
			esx_inst_type="usb"	#	Setting the installation type FOLDER
			esxi_check_oem
			esxi_cd
			esxi_add_ssh_ftp
			esxi_file_name
			esxi_check_old
			esxi_dd_start
			esxi_dd_end
			esxi_usb_finish 		#	Moving/rename the esx-build folder to the save folder and copy the files to the USB drive
			esxi_clean
		;;

		3 | DD | dd )
			esx_inst_type="dd"		#	Setting the installation type to DD
			esxi_check_oem
			esxi_cd
			esxi_add_ssh_ftp
			esxi_file_name
			esxi_check_old
			esxi_dd_start
			esxi_dd_end
			esxi_dd_finish			#	Rename dd file, move it to the save folder and write it to the USB drive
			esxi_clean
		;;

		4)	#	USB installation without changes
		
			esx_inst_type="usb"	#	Setting the installation type to fold
			esx_custom="$esx_iso_file"
			esxi_cd
			esxi_file_name
			esxi_check_old
			esxi_usb_finish
			esxi_clean
		;;
		
		5)	#	Boot from USB without changes
		
			esx_inst_type="dd"		#	Setting the installation type to DD
			esx_custom="$esx_iso_file"
			esxi_cd
			esxi_file_name
			esxi_check_old
			esxi_dd_start
			esxi_dd_finish
			esxi_clean
		;;
		
		6)
			clear 					#	Clear the screen.
			esxi_clean
			exit 0
		;;

		QQ-)
			#esxi_usb_use
			#esxi_usb_finish
			#esx_inst_type="usb"
			#esxi_check_oem
			#echo $esx_oem_file
			#echo $esx_custom
			#esxi_file_name
			#echo $esx_finish
			#esxi_file_name
			#esxi_cd
			#esxi_add_ssh_ftp
			#esxi_usb_finish			#	Just for testing
			#esxi_clean
			exit 0
		;;

		*)
			esxi_red "That's not a valid option"
			sleep 1
			clear 					#	Clear the screen.
			esxi_menu				#	Loop the menu
		;;

	esac
}

function esxi_create_folders() {	#	Create folders

	cd $ipath																		#	Change so the start path is correct
		
	clear						 													#	Clear the screen.
		
	esxi_check_dir $ipath/$esx_save													#	Check if there is all ready a save folder
	esxi_check_dir $ipath/$custom_esx 
	
	shopt -s nullglob
	esx_rm=(esx-*)
	
	echo
	
	if [[ ${#esx_rm[@]} == 0 ]]														#	If there is any working folder left
		then
			esxi_green "Creating folders ${esx_folders[*]}"
			mkdir ${esx_folders[*]}
			esxi_done
			sleep 2
			if [[ -n "$esx_inst_type" ]] 
				then
					esxi_file_rights
			fi
		else								#	If there is folders it will delete them and start over
			clear 							#	Clear the screen.
			echo
			esxi_red "There was some working folders left, \n deleting them and restarting the script"
			echo
			sleep 4
			esxi_clean
			esxi_create_folders

	fi
	shopt -u nullglob
	
	esx_folders[8]=custom-esx														#8	Where you can add files you like to be added to the oem file.
}

function esxi_cd() {				#	Copy the files on the ISO to the build folder
	esxi_green "Mounting $ipath/$esx_iso_file file to $ipath/${esx_folders[0]}"
	mount -o loop $ipath/$esx_iso_file $ipath/${esx_folders[0]}								#	Mounting the ISO file to the esx-cd folder
	esxi_done

	esxi_check_files "esx-cd"
	
	esxi_green "Copy CD to $ipath/${esx_folders[5]}"
	cp -r -p $ipath/${esx_folders[0]}/* $ipath/${esx_folders[5]}							#	Copying files from ISO to the build folder keeping attributes
	esxi_done

	esxi_green "U mounting $ipath/${esx_folders[0]}"
	umount $ipath/${esx_folders[0]}															#	U mounting the ISO
	esxi_done
	
	esxi_check_files "esx-build"
	
	if [[ "$esx_custom" != "$esx_iso_file" ]]
		then
			if [[ $esxi == "3.5" ]]
				then 
					if [[ -e  "$ipath/${esx_folders[5]}/oem.tgz" ]]
						then 
							esxi_green	"Removes the oem file from ${esx_folders[5]}"
							rm $ipath/${esx_folders[5]}/oem.tgz
							esxi_done
						else
							esxi_red "There is no oem.tgz file please check if you have a ESXi 3.5 iso file"
							sleep 5
							
							clear
							exit
					fi
				else
					esxi_check_inetd
			fi
	fi
	sleep 2
	clear
}

function esxi_add_ssh_ftp() {		#	Extracting inetd.conf from ienviron.tgz and copy the custom oem to the build folder $esx_extra=Y/N $esx_custom_f=Y/N wget and rsync
	
		esxi_green "Untar $esx_oem_file to $ipath/${esx_folders[3]}"
		${esx_pkg_install[6]} -xzf $ipath/$esx_oem_file -C $ipath/${esx_folders[3]}						#	Untaring the oem.tgz
		esxi_done

		if [[ $esxi == "3.5" ]]
			then
				esxi_green "Untar ienviron.tgz to $ipath/${esx_folders[2]}"
				${esx_pkg_install[6]} -xzf $ipath/${esx_folders[5]}/ienviron.tgz -C $ipath/${esx_folders[2]}		#	Untaring the ienviron.tgz 
				esxi_done
				sleep 3
		fi

		if [[ $esxi == "4.0" ]]
			then
				esxi_check_dir $ipath/${esx_folders[3]}/etc
				
				if [[ ! -e $ipath/${esx_folders[3]}/etc/inetd.conf ]]
					then 
						cp $ipath/$esx_inetd_file $ipath/${esx_folders[3]}/etc
					else
					esxi_edit $ipath/${esx_folders[3]}/etc/inetd.conf
				fi
		fi

		if [[ ! -e $ipath/${esx_folders[3]}/etc/inetd.conf ]]
			then
				esx_add_ssh_ftp_menu_fold=${esx_folders[2]}
				esxi_add_ssh_ftp_menu 
			else
				esx_add_ssh_ftp_menu_fold=${esx_folders[3]}
				esxi_add_ssh_ftp_menu 
		fi
		
		esxi_check_dir $ipath/${esx_folders[3]}/etc

		if [[ ! -e $ipath/${esx_folders[3]}/etc/inetd.conf ]] ; 
			then
				esxi_green "Copy inetd.conf to $ipath/${esx_folders[3]}/etc"
				cp -r -p $ipath/${esx_folders[2]}/etc/inetd.conf $ipath/${esx_folders[3]}/etc/			#	Copying the custom SSH enabled inetd.conf file
				esxi_done	
		fi
		if [[ -z $esx_auto ]]
			then
				esxi_edit $ipath/${esx_folders[3]}/etc/inetd.conf
				
				if [[ $esxi == "4.0" ]]
					then
						esxi_edit $ipath/${esx_folders[3]}/etc/vmware/pci.ids
					else
						esxi_edit $ipath/${esx_folders[3]}/usr/share/hwdata/pci.ids
				fi

				esxi_edit $ipath/${esx_folders[3]}/etc/vmware/simple.map
		fi
				
		if [[ -z $esx_auto ]]
			then
				esxi_green "Do you like to install wget and rsync ? \e[00m [Y/n]"
				read esx_extra_e
				echo
			else
				if [[ -z $esx_extra_e ]]
					then
						esx_extra_e="N"
				fi
		fi
		
		if [[ $esx_extra_e == "N" || $esx_extra_e == "n" ]]			#	Downloading wget and rsync from vm-help.com
			then 
				echo ""
			else
				esxi_extra
		fi
		
		if [[ $esxi == "3.5" ]]
			then
				esxi_green "Changing ownership on the files in the ${esx_folders[3]} folder"				#	Channing the ownership and mod on the files in the build folder
				chown -R 201:201 $ipath/${esx_folders[3]}/*
				chmod +x $ipath/${esx_folders[3]}/sbin/*
				esxi_done
		fi

				
		if [[ -z $esx_auto ]]
			then
				esxi_green "Do you have any extra file in $ipath/${esx_folders[8]} \e[00m [y/N] "					#	Copy custom files to the oem folder 
				read esx_custom_f
				echo
			else
				if [[ -z $esx_custom_f ]]
					then
						esx_custom_f="N"
				fi
		fi
		
		if [[ $esx_custom_f == "Y" || $esx_custom_f == "y" ]]
			then
				echo
				esxi_green "Copy ${esx_folders[8]} to ${esx_folders[3]} "
				cp -r $ipath/${esx_folders[8]}/* $ipath/${esx_folders[3]}
				echo
		fi

		esxi_green "Rebuilding $ipath/${esx_folders[5]}/oem.tgz using $ipath/${esx_folders[3]}"
		cd $ipath/${esx_folders[3]}
		${esx_pkg_install[6]} czf $ipath/${esx_folders[5]}/oem.tgz *								#	Rebuilding the oem.tgz file
		cd $ipath/
		esxi_done
		sleep 3

if [[ $esxi == "4.0" ]]
	then
		sed -i 's/install.tgz/install.tgz --- oem.tgz/g' $ipath/${esx_folders[5]}/isolinux.cfg
fi
}

function esxi_add_ssh_ftp_menu() {	#	Menu for ftp / ssh support
	
	if [[ -z $esx_auto ]]
		then 
			clear 								# 	Clear the screen.
			echo
			esxi_green "     Extra support "
			echo
			esxi_green  "  [1] ${esx_menu[6]}"	#	If there are going to be FTP support enabled
			echo
			esxi_green  "  [2] ${esx_menu[7]}"	#	If there are going to be SSH support enabled
			echo
			esxi_green  "  [3] ${esx_menu[8]}"	#	If there are going to be FTP + SSH support enabled
			echo
			esxi_green  "  [4] ${esx_menu[9]}"	#	Exit and continue
			echo
			esxi_green "  Do you like to add: "
			read esx_menu_extra
		else
			if [[ -z $esx_menu_extra ]]
				then
					esx_menu_extra="NO"
			fi
	fi

	case "$esx_menu_extra" in
		1 | FTP )
			clear
			esxi_ftp $esx_add_ssh_ftp_menu_fold
			esx_extra="ftp"
			esx_custom=${esx_custom}ftp_
		;;

		2 | SSH )
			clear
			esxi_edit_file "^#ssh" "ssh" $ipath/$esx_add_ssh_ftp_menu_fold/etc/inetd.conf
			esx_extra="ssh"
			esx_custom=${esx_custom}ssh_
		;;
		
		3 | SSHFTP )
			clear
			esxi_edit_file "^#ssh" "ssh" $ipath/$esx_add_ssh_ftp_menu_fold/etc/inetd.conf
			esxi_ftp $esx_add_ssh_ftp_menu_fold
			esx_extra="ftp and ssh"
			esx_custom=${esx_custom}ftp_ssh_
		;;
		
		4 | NO )
			clear
			esx_extra=""
			echo
		;;
		* )
			esxi_red "That's not a valid option"
			sleep 1
			clear 					#	Clear the screen.
			esxi_add_ssh_ftp_menu	#	Loop the menu
		;;
	esac

}

function esxi_edit_file() {			#	Change a files 
	
	esxi_green "Replacing $1 with $2 in $3"
	${esx_pkg_install[4]} -s $3 <<< ",s/$1/$2/g"$'\nw'
	esxi_done
	sleep 1
}

function esxi_ftp(){				#	To install ftp on the ESXi server

	esxi_check_dir $ipath/${esx_folders[3]}/sbin										#	Check if there is all ready a sbin folder
	esxi_check_dir $ipath/${esx_folders[3]}/etc											#	Check if there is all ready a etc folder

	esxi_green "Downloading ProFtpd to $ipath/${esx_folders[7]}"
	cd $ipath/${esx_folders[7]}
	wget -q http://www.vm-help.com/esx/esx3i/ftp/proftpd.zip 2>>/dev/null
	${esx_pkg_install[3]} -qq proftpd.zip 2>>/dev/null
	esxi_done
	
	cd $ipath/${esx_folders[7]}/proftpd
	
	if [[ ! -e $ipath/${esx_folders[3]}/etc/proftpd.conf ]]
		then
			esxi_green "Copy the proftpd.conf to $ipath/${esx_folders[3]}/etc"
			cp proftpd.conf $ipath/${esx_folders[3]}/etc
			esxi_done
	fi
	
	esxi_green "Copy the proftpd to $ipath/${esx_folders[3]}/sbin"
	cp proftpd $ipath/${esx_folders[3]}/sbin
	esxi_done
	esxi_green "Copy the tcpd to $ipath/${esx_folders[3]}/sbin"
	cp tcpd $ipath/${esx_folders[3]}/sbin
	esxi_done

	if [[ $esxi == "3.5" ]]
		then
			esxi_edit_file "^#ftp" "ftp" $ipath/$1/etc/inetd.conf
			esxi_edit_file "in.ftpd" "proftpd" $ipath/$1/etc/inetd.conf 
		else
			echo "ftp    stream  tcp     nowait  root    /usr/sbin/tcpd  proftpd" >> $ipath/$1/etc/inetd.conf
			echo "" >> $ipath/$1/etc/inetd.conf

	fi
	if [[ -z $esx_auto ]]
		then
			esxi_edit $ipath/$1/etc/proftpd.conf
	fi
}

function esxi_edit(){				#	Edit files
	
	esx_loop=$1
	
	esxi_green "Do you like to edit $1 \e[00m [y/N] "
	if [[ -z $esx_auto ]]
		then
			read edfile
		else
			edfile="N"
	fi
	
	case $edfile in
		
		"Y" | "y" )
			if hash ${esx_pkg_install[5]} 2>>/dev/null
				then 
					${esx_pkg_install[5]} $1
					clear
				else
					esxi_red \n \n ${esx_pkg_install[5]} is not installed \n Please install it manually  and rerun the script
			fi
		;;
		
		"N" | "n" | '' )
		#			esxi_green "Continue without editing the file $1"
		;;
		
		*)
			clear
			esxi_edit $esx_loop
		;;
	esac
}

function esxi_extra(){				#	Downloading wget and rsync from vm-help.com
	
	esxi_check_dir $ipath/${esx_folders[3]}/sbin
	cd $ipath/${esx_folders[3]}/sbin
	esxi_green "Downloading New wget and rsync"
	wget -q http://www.vm-help.com/esx/esx3i/Enable_FTP/wget 2>>/dev/null
	wget -q http://www.vm-help.com/esx/esx3i/Enable_FTP/rsync 2>>/dev/null
	esxi_done	
}

function esxi_check_old() {			#	Checking for old custom files/folders

	cd $ipath

	if [[ -d $ipath/$esx_save ]]														#	Check if there is all ready a save folder
		then
			cd $ipath/$esx_save
			esx_old_file="$esx_finish"
				if [[ -e $esx_old_file ]]
					then
						clear 						#	Clear the screen.
						if [[ -z $esx_auto ]]
							then
								echo
								esxi_red " You have all ready made a custom file/folder \n \n $esx_old_file"
								echo
								echo
								esxi_red " Do you like to delete that file/folder\n and continue the script or (u)se it again  ?\e[00m [u/y/N] "
								read key
							else
								key="Y"
						fi
						
						case "$key" in
						"Y" | "y" )
							rm -R $esx_old_file		#	Deleting the old file
							cd $ipath
							clear 					#	Clear the screen.
							;;
						"N" | "n" | '' )
							echo
							esxi_red " OK good luck with the one you have"
							echo
							esxi_red " You can find the files at \n $ipath/$esx_save"
							echo
							echo
							sleep 3
							clear 					#	Clear the screen.
							esxi_clean
							exit 0
							;;
						"U" | "u" )
							if [[ $esx_inst_type == usb ]]
								then
									esxi_usb_finish
									esxi_clean
									exit
								else
									if [[ $esx_inst_type == dd ]]
										then
											esxi_dd_finish
											esxi_clean
											exit
										else
											esxi_check_old
									fi
							fi
						;;
						* )
							esxi_check_old
							;;
						esac
			fi
	fi
}

function esxi_dd_start(){			#	Extracting DD file

	if [[ $esxi == "3.5" ]]
		then
			esxi_green "Untar install.tgz to $ipath/${esx_folders[1]}"
			${esx_pkg_install[6]} -xzf $ipath/${esx_folders[5]}/install.tgz -C $ipath/${esx_folders[1]}						#	Untaring the installation.tgz file to get the dd file
			esxi_done
			cd $ipath/${esx_folders[1]}/usr/lib/vmware/installer/

		else
			if [[ $esxi1 == "" ]]
				then
					esxi_green "Untar image.tgz to $ipath/${esx_folders[1]}"
					${esx_pkg_install[6]} -xzf $ipath/${esx_folders[5]}/image.tgz -C $ipath/${esx_folders[1]}						#	Untaring the installation.tgz file to get the dd file
					esxi_done
					cd $ipath/${esx_folders[1]}/usr/lib/vmware/installer/

			fi
	fi
	
	if [[ $esxi1 == "4.1" ]]
		then cd $ipath/${esx_folders[5]}/
	fi
	
	esx_ddf=(*.bz2)

	esxi_green "Bunzip2 ${esx_ddf[0]} "
	bunzip2 ${esx_ddf[0]}																	#	Uncompressing the bz2 file
	esxi_done

	esx_ddf=(*dd)
}

function esxi_dd_end(){				#	Add the customized to the DD file and the build folder

	if [[ $esxi1 == "4.1" ]]
		then 
			cd $ipath/${esx_folders[5]}/
		else
			cd $ipath/${esx_folders[1]}/usr/lib/vmware/installer
	fi
	
	esx_ddf=(*dd)
	
	if hash fdisk 2>>/dev/null
		then 
			esx_sector=$( fdisk -ul ${esx_ddf[0]} 2>>/dev/null | awk -v pat=$esx_bytes '$0 ~ pat {print $9}' )			#   Checking the number of sectors
			if [[ -z $esx_sector ]]
				then
					esx_sector="512"
			fi
			esx_number=$( fdisk -ul ${esx_ddf[0]} 2>>/dev/null | awk '/dd5/ {print $2}' ) 								#	Checking where the 5th partition starts

		else 
			esx_fdisk=(find / -name fdisk)
			esx_sector=$( $esx_fdisk -ul ${esx_ddf[0]} 2>>/dev/null |  awk -v pat=$esx_bytes '$0 ~ pat {print $9}' )	#   Checking the number of sectors
			
			if [[ -z $esx_sector ]]
				then
					esx_sector="512"
			fi
	
			esx_number=$( $esx_fdisk -ul ${esx_ddf[0]} 2>>/dev/null | awk '/dd5/ {print $2}' )	#	Checking where the 5th partition starts
	fi

	esxi_green "Mounting $ddf to $ipath/${esx_folders[4]}"
	mount -o loop,offset=$(($esx_sector*$esx_number)) $esx_ddf $ipath/${esx_folders[4]}/		#	Mounting the 5th partition of the DD file to esx-5
	esxi_done

	esxi_green "Copy ${esx_folders[5]}/oem.tgz to ${esx_folders[4]}/oem.tgz"
	cp $ipath/${esx_folders[5]}/oem.tgz $ipath/${esx_folders[4]}/oem.tgz						#	Copy the custom oem file to the mounted dd file
	esxi_done

	esxi_green "U mounting $ipath/${esx_folders[4]}"
	umount $ipath/${esx_folders[4]}																#	U mounting the dd file
	esxi_done

	if [[ $esx_inst_type != dd ]]
		then 
			if [[ $esxi1 == "4.1" ]]
				then
					cd $ipath/${esx_folders[5]}/
					esxi_green "Bzip2 the $esx_ddf"
					${esx_pkg_install[7]} $esx_ddf															#	Compressing the dd file
					esxi_done
					esx_ddf=(*.bz2)
					${esx_pkg_install[9]} $esx_ddf > ${esx_ddf%.bz2}.md5
					esxi_edit_file "$esx_ddf" "VMware-VMvisor-big-260247-x86_64.dd.bz2" ${esx_ddf%.bz2}.md5
			else
					cd $ipath/${esx_folders[1]}/usr/lib/vmware/installer
					esxi_green "Bzip2 the $esx_ddf"
					${esx_pkg_install[7]} $esx_ddf															#	Compressing the dd file
					esxi_done
			fi
			
			if [[ $esxi == "3.5" ]]
				then
					esxi_green "Rebuilding install.tgz"
					cd $ipath/${esx_folders[1]}/
					${esx_pkg_install[6]} czf $ipath/${esx_folders[5]}/install.tgz sbin/ usr/		#	Rebuilding install.tgz
					esxi_done
				else
					if [[ $esxi1 != "4.1" ]]
						then
							esxi_green "Rebuilding image.tgz"
							cd $ipath/${esx_folders[1]}/
							${esx_pkg_install[6]} czf $ipath/${esx_folders[5]}/image.tgz usr/		#	Rebuilding install.tgz
							esxi_done
					fi
			fi

			esxi_file_rights
	fi 
}

function esxi_iso_finish(){			#	Making the ISO file

	esxi_file_rights
	
	esxi_green "Creating $ipath/$esx_save/$esx_finish"								#	Creating the ISO file $ipath/save/esxi_custom_oem.iso
	echo
	cd $ipath/${esx_folders[5]}
	
	if [[ $esxi == "4.0" ]]
		then
			if [[ $esxi1 == "4.1" ]]
				then
					sed -i 's/install.vgz/install.vgz --- oem.tgz/g' $ipath/${esx_folders[5]}/isolinux.cfg
				else
					sed -i 's/install.tgz/install.tgz --- oem.tgz/g' $ipath/${esx_folders[5]}/isolinux.cfg
			fi
	fi	
	
	${esx_pkg_install[0]} -o $ipath/$esx_save/$esx_finish -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -input-charset utf-8 ../${esx_folders[5]} 2>>/dev/null
	echo
	echo
	clear 							#	Clear the screen.
	esxi_green " You can find the iso file at \n $ipath/$esx_save/$esx_finish"
	echo
	echo
	sleep 3

}

function esxi_check_usb() {			#	Gather data for the USB menu

	for i in /sys/block/[sh]d?
		do
			if $esx_usb_check_cmd info -a -p "$i" | grep -qF 'usb'	#	DRIVERS=="usb-storage"									#	Checking witch device is a USB
				then
					esx_usb_dev_info=("${i##*/}")																						#	Sets the device
					esx_usb_dev=$(fdisk -l /dev/$esx_usb_dev_info | awk '/^\/dev/ {print $1}')											#	Checks witch partition to use / mount
					esx_usb_name_info=$($esx_usb_check_cmd info -a -p "/sys/block/$esx_usb_dev_info" | awk '/ATTRS{product}==/ { print $0;exit }')		#	Get's the product name of the USB
					esx_usb_name_mfg=$($esx_usb_check_cmd info -a -p "/sys/block/$esx_usb_dev_info" | awk '/ATTRS{manufacturer}==/ { print $0;exit }')	#	Get's the vendor name of the USB
					esx_usb_size=$(fdisk -l "/dev/$esx_usb_dev_info" | awk '/dev/ { print $3;exit }')									#	The size of the USB in MB
					esx_usb_size_name=$(fdisk -l "/dev/$esx_usb_dev_info" | awk '/dev/ { print $4;exit }')
					esx_usb_name_col=${esx_usb_name_info%\"*}																			#	Removing the " and the text after it
					esx_usb_name_mfg_col=${esx_usb_name_mfg%\"*}																		#	Removing the " and the text after it
					esx_usb_dev_list+=("$esx_usb_dev")																					#	Creating a array of the USB devices
					esx_usb_name_list+=("${esx_usb_name_col#*\"}")																		#	Creating a array of USB product
					esx_usb_mfg_list+=("${esx_usb_name_mfg_col#*\"}")																	#	Creating a array of USB vendor
					esx_usb_size_list+=("$esx_usb_size")																				#	Creating a array of USB Size
					esx_usb_size_name_list+=("$esx_usb_size_name")																		#	Creating a array of USB Size type MB/GB
			fi
		done
	shopt -s nullglob
		if [  ${#esx_usb_name_list[*]} != 0 ]
			then
				esx_usb_menu_text=("There are one or more USB drive installed")
				esx_usb_menu_question=('Witch USB drive are you going to use ?  ')
			else
				esx_usb_menu_text=("There is no USB drive installed")
				esx_usb_menu_question=('Try to connect a USB drive and use update ! ')
		fi
	shopt -u nullglob
}

function esxi_usb_menu() {			#	Menu for the USB $esx_usb_install

	PS3=$esx_usb_menu_question

	select esx_usb_dev_array
		do
			if [ -z $esx_usb_dev_array ]
				then 
					unset esx_usb_dev_list[*]
					esxi_usb_use									#	Calls the menu again if the answer is incorrect
				else 
					if [ "$esx_usb_dev_array" = "Exit" ]			#	If the Select is exit
						then
							clear 									#	Clear the screen.
							echo
							esxi_green " You can find the files at \n $ipath/$esx_save/"
							echo
							echo
							echo
							esxi_red " Exiting ...."
							sleep 2
							echo
							echo
							echo
							esxi_clean
							echo
							echo
							exit 0
						else
							if [ "$esx_usb_dev_array" = "Update" ]
								then
									unset esx_usb_dev_list[*]
									unset esx_usb_name_list[*]
									unset esx_usb_mfg_list[*]
									unset esx_usb_size_list[*]
									unset esx_usb_size_name_list[*]
									esxi_usb_use
								else
								esx_usb_install="$esx_usb_dev_array"
							fi
					fi
		
			fi
		clear 							#	Clear the screen.
		break
		done
}

function esxi_usb_use(){			#	Witch USB drive to use menu

	clear 							#	Clear the screen.

	esxi_check_usb

	echo $esx_usb_menu_text
	echo
	for index in ${!esx_usb_dev_list[@]};
		do
			printf " %s is %s - %s  %s %s" "${esx_usb_dev_list[index]}" "${esx_usb_name_list[index]}" "${esx_usb_mfg_list[index]}" "${esx_usb_size_list[index]}" "${esx_usb_size_name_list[index]}" ;
			echo
			echo
		done
			esx_usb_dev_list[9]="Update"
			esx_usb_dev_list[10]="Exit"
			esxi_usb_menu ${esx_usb_dev_list[*]}

}

function esxi_usb_finish(){			#	To confirm that the user really like to continue with the USB installation 	$esx_usb_install
									#	Moving the and renaming the USB installation folder
	if [[ "$esx_custom" != "$esx_iso_file" ]]
		then		
			esxi_file_rights
	fi

	if [[ $esxi == "4.0" ]]
		then
			if [[ $esxi1 == "4.1" ]]
				then
					sed -i 's/install.vgz/install.vgz --- oem.tgz/g' $ipath/${esx_folders[5]}/isolinux.cfg
				else
					sed -i 's/install.tgz/install.tgz --- oem.tgz/g' $ipath/${esx_folders[5]}/isolinux.cfg
			fi
	fi	
	
	esxi_move_files $ipath/${esx_folders[5]}											#	Rename the build folder
	
	clear 		#	Clear the screen.
	if [[ -z $esx_auto ]]
		then
			esxi_usb_use			#	Getting the usb device to use
	fi
	
	clear 																										#	Clear the screen.
	echo
	esxi_red "Next step will be to make the USB drive bootable \n and copy the installations files to the it.\n		OBS !!! You need 700 MB free on the USB"
	echo
	esxi_red "Using $esx_usb_install"
	echo
	esxi_red "Do you really like to continue with this ?\e[00m [y/N] "
	
	if [[ -z $esx_auto ]]
		then
			read gogo
		else
			gogo="Y"
	fi
	
	case $gogo in

			"Y" | "y" )
			
			esxi_green "Making the USB bootable"
			${esx_pkg_install[1]} $esx_usb_install																#	Using syslinux to make the USB bootable
			# ${esx_pkg_install[10]} $esx_usb_install																#	Add the boot flag to the USB 
			esxi_done

			esxi_green "Mounting the $esx_usb_install to $ipath/${esx_folders[6]}/ "
			mount -o loop $esx_usb_install $ipath/${esx_folders[6]}												#	mounting the USB device
			esxi_done

			esxi_green "Copy the installation media to the mounted USB"
			cp $ipath/$esx_save/$esx_finish/* $ipath/${esx_folders[6]}/										#	Copying the files from the installation folder to the USB
			esxi_done

			esxi_green "Renaming  the file isolinux.cfg to SYSlinux.cfg"
			mv $ipath/${esx_folders[6]}/isolinux.cfg $ipath/${esx_folders[6]}/SYSlinux.cfg						#	renaming the isolinux.cfg to SYSlinux.cfg
			esxi_done

			esxi_green "U mounting the USB drive"
			umount $ipath/${esx_folders[6]}/																		#	U mounting the usb drive
			esxi_done
			echo
			esxi_green "Now your usb ready to install from \n just plug it into the system you like to install ESXi on"
			echo
			esxi_redo esxi_usb_finish
			echo
			echo
			sleep 2
		;;

			"N" | "n" | '' )																							#	If you like to move the files your self
			
			clear 																								#	Clear the screen.
			echo
			esxi_red "The files are in \n $ipath/$esx_save/$esx_finish folder"
			echo
			sleep 3
			clear 																								#	Clear the screen.
		;;

			* )
		
			esxi_usb_finish
		;;

	esac

}

function esxi_dd_finish(){			#	To confirm that the user really like to continue with the USB installation 	Moving and renaming the DD ( USB boot file)

	if [[ $esxi1 == "4.1" ]]
		then
			esxi_move_files $ipath/${esx_folders[5]}/$esx_ddf
		else
			esxi_move_files $ipath/${esx_folders[1]}/usr/lib/vmware/installer/$esx_ddf
	fi
	
	if [[ -z $esx_auto ]]
		then
			esxi_usb_use			#	Getting the usb device to use
	fi

	clear 							#	Clear the screen.
	echo
	esxi_red " Next step will be to make the USB drive bootable. \n It will write the boot image to the USB drive \n ALL files will be lost !!! \n Do not use a USB stick that is under 1GB "
	echo
	esxi_red " Using "$esx_usb_install
	echo
	esxi_red " Do you really like to continue with this ?\e[00m [y/N] "
	
	if [[ -z $esx_auto ]]
		then
			read gogo
		else
			gogo="Y"
	fi

	case $gogo in

			"Y" | "y" )

			esxi_green "Writing DD image to the usb device $esx_usb_install "
			dd bs=1M if=$ipath/$esx_save/$esx_finish of=${esx_usb_install%[0-9]} 2>>/dev/null
			esxi_done
			sleep 2
			esxi_redo esxi_dd_finish
			echo
			esxi_green "The USB stick is now ready to plug in in your server and boot up"
			echo
			;;

			"N" | "n" | '' )																							#	If you like to move the files your self

			esxi_green " Moving the $esx_ddf file to $ipath/$esx_save "
			if [[ esxi1 == "4.1" ]]
				then
					mv -f $ipath/${esx_folders[5]}/$esx_ddf $ipath/$esx_save/$esx_finish
				else
					mv -f $ipath/${esx_folders[1]}/usr/lib/vmware/installer/$esx_ddf $ipath/$esx_save/$esx_finish		#	Moving the DD file to work folder and rename it
			fi
			sleep 2
			esxi_done
			clear 							#	Clear the screen.

			echo
			esxi_red "the $esx_finish can be found here \n $ipath/$esx_save/$esx_finish"
			echo
			sleep 3
			clear 																							#	Clear the screen.
			;;

			* )
			
			clear
			esxi_dd_finish
			;;
	esac
}

function esxi_clean(){				#	Cleans up after the script 

	esx_cd=$(mount | awk -v mfold="${esx_folders[0]}" '$0 ~ mfold {print $3}')

	if [ -n "$esx_cd" ]																		#	Checking if there is anything mounted to esx-cd
		then
			echo
			esxi_green "U mounting ${esx_folders[0]}s"
			umount $ipath/${esx_folders[0]}
			esxi_done
			sleep 5
	fi

	esx_5=$(mount | awk -v mfold="${esx_folders[4]}" '$0 ~ mfold {print $3}')

	if [ -n "$esx_5" ]																		#	Checking if there is anything mounted to esx-5
		then
			echo
			esxi_green "U mounting ${esx_folders[4]}"
			umount $ipath/${esx_folders[4]}
			esxi_done
			sleep 5
	fi


	esx_usb=$(mount | awk -v mfold="${esx_folders[6]}" '$0 ~ mfold {print $3}')

	if [ -n "$esx_usb" ]																	#	Checking if there is anything mounted to esx-usb
		then
			echo
			esxi_green "U mounting ${esx_folders[6]}"
			umount $ipath/${esx_folders[6]}
			esxi_done
			sleep 5
	fi

	cd $ipath
	shopt -s nullglob
	esx_rm=(esx-*)
	if [[ "${#esx_rm[@]}" -gt 0 ]]															#	If there is folder left to delete
		then
			esxi_green "Removing working folders (esx-*)"
			rm -R $ipath/esx-*																#	Cleaning up, removing the folders
			esxi_done
			sleep 5
	fi
	shopt -u nullglob

	if [[ -u "$esx_custom" ]]
		then
			chown --from=$USER $SUDO_UID:$SUDO_GID $ipath/*
	fi
}

function esxi_checkRoot() {			#	To check if the script is run as a superuser
    if [ ! $( id -u ) -eq 0 ]
		then
			echo
			esxi_red "Must have super-user rights to run this script. \n Run with the command 'sudo $0'"
			echo
			echo
			exit 0
	fi
}

function esxi_check_dir() {			#	Checks the dir given 
	
	if [ ! -d $1	]				#	Check if there is all ready a folder
		then
			esxi_green "Creating $1"
			mkdir -p $1				#	Creates the folder
			esxi_done
			sleep 2
	fi
}

function esxi_file_rights(){		#	Change the ownership and permissions for files
	
	if [[ $esxi == "3.5" ]]
		then 
			esxi_green "Changing ownership and mod on install.tgz"
			chown -R 201:201 $ipath/${esx_folders[5]}/install.tgz 										#	Channing the ownership and mod for install.tgz
			chmod 755 $ipath/${esx_folders[5]}/install.tgz
			esxi_done

			esxi_green "Changing ownership on the files in the ${esx_folders[5]} folder"				#	Channing the ownership and mod on the files in the build folder
			
			chown -R 201:201 $ipath/${esx_folders[5]}/*
			chmod 755 $ipath/${esx_folders[5]}/oem.tgz
			esxi_done
	fi
}

function esxi_apt-get(){			#	Check if apt-get is there and if not asks for a new install bin

echo
echo
esxi_green "	Installing..."
echo

if hash apt-get 2>/dev/null
	then
		esxi_green "	apt-get is already installed"
		echo
		sleep 2
	else
		esxi_red "\n	Standard command is $esx_ibin, \n	apt-get can't be found on your system \n	Please specify the install command for your system\n"
		esxi_green "	Type whole command similar to the command above \n	"
		read ibin
		esx_ibin="$ibin" 
fi
}

function esxi_pkg_inst(){			#	Loop to find binaries 

for pkgbin in ${esx_pkg_install[*]}
do	
	if hash $pkgbin 2>>/dev/null
		then 
			esxi_green "	$pkgbin is already installed"
			echo
			sleep 2
		else
			$esx_ibin $pkgbin 2>>/dev/null
			if [ ! $? -eq 0 ]
				then
					echo
					esxi_red "	Script encountered an error during package installation.  \n	Check errors and retry"
					echo
					exit 0
			fi
			esxi_green "	$pkgbin is now installed"
			echo
			sleep 2
	fi
done
sleep 2
clear
}

function esxi_check_files(){		#	Check if the files is in the folder
	shopt -s nullglob
	local i=($1/*)
		if [ -z "$i" ]
			then
				esxi_red " There is no files in $ipath/$1 please check the dir/files"
				echo
				sleep 2
				exit 1
		fi
	shopt -u nullglob;
}

function esxi_user(){				#	Need user input

esxi_red "$*"
reda esx_input

}

function esxi_redo(){				#	Redo the operation 

esx_redo=$1

esxi_green "Do you like to create another? \e[00m [y/N] "
	if [[ -z $esx_auto ]]
		then
			read key
		else
			key="N"
	fi

case "$key" in
	"Y" | "y" )
		$1
		;;
	"N" | "n" | '' )
		;;
	* )
		esxi_redo $esx_redo
		;;
esac

}

function esxi_move_files(){			#	To move the work file / dir to the save folder

	if [[ ! -e $ipath/$esx_save/$esx_finish ]]
		then
			esxi_green "Moving $1 to $ipath/$esx_save/$esx_finish "
			mv -f $1 $ipath/$esx_save/$esx_finish						#	Moving the DD/dir file to work folder and rename it
			chown $SUDO_UID:$SUDO_GID $ipath/$esx_save/$esx_finish
			chmod -x $ipath/$esx_save/$esx_finish
			sleep 2
			esxi_done
			clear 														#	Clear the screen.
	fi

}

function esxi_auto(){				#	Noninteractiv loop 
	
	for i in "${!esx_auto_com[@]}"; do 
		if esx_arg=$(esxi_HaveOpt ${esx_auto_com[i]} "$@"); then
			if [[ $esx_arg ]]; then
				${esx_auto_exe[i]} "$esx_arg"
			else
				${esx_auto_exe[i]}
			fi
		fi
				

	done

}

function esxi_auto_dest(){			#	Auto installtion type
		esxi_apt-get			#	Checks if apt-get is installed 
		esxi_pkg_inst			#	Install the pkg's needed
		esxi_create_folders		#	Creates the base folders
		esxi_check_iso			#	Check if you have any ISO file in the same folder as this script 
		esxi_menu $1	
		esxi_clean				#	Deletes work folders if there is any
		exit
}

function esxi_esx_usb_install(){	#	Sets the USB device

esx_usb_install=$1

}

function esxi_add_ssh_ftp_menu_s(){	#	Sets if you are going to install ssh or ftp 

esx_menu_extra=$1

}

function esxi_add_ssh_ftp_e() {		#	sets if you are going to install wget and rsync

esx_extra_e="Y"

}

function esxi_add_ssh_ftp_c() {		#	If you have extra files in t he custom-esx folder

esx_custom_f="Y"

}

function esxi_help() {				#	The help menu 
	echo
	esxi_green "$0 ${esx_auto_com[@]}"
	echo
	echo
	for index in ${!esx_auto_com[@]};
		do
			printf "	%s	%s " "${esx_auto_com[index]}" "${esx_auto_help[index]}" ;
			echo
		done
	echo
	esxi_green "	e.g. $0 --a --v=4.0 --e --i=ISO -s=SSHFTP"
	echo
	echo
	exit
}

clear
esxi_checkRoot ./$0		#	Starts with a check that you are superuser
esxi_clean				#	Deletes work folders if there is any
esxi_auto "$@"			#	To make the script nonintractiv 
esxi_version			#	To check with version to use.
esxi_check_iso			#	Check if you have any ISO file in the same folder as this script 
esxi_apt-get			#	Checks if apt-get is installed 
esxi_pkg_inst			#	Install the pkg's needed
esxi_create_folders		#	Creates the base folders
esxi_menu				#	Starts the main menu 
esxi_clean
exit 0
