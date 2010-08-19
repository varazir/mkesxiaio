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


#  Array
array_work_dir=(								#	Work directories (Array)
esx-cd 											#0	Mount point for the ISO file will
esx-temp 										#1	Where the install.tgz will be extracted
esx-ienv 										#2	Where the ienviron.tgz will be extracted
esx-oem 										#3	Where the OEM file will be extracted
esx-5 											#4	Mount point for the dd file
esx-build										#5	The work directory
esx-usb											#6	Mount point for the USB drive
esx-ftp											#7	Where the proftpd.zip will be extracted
)

array_pkg_install=( 							#	Pkg's that is needed for this script (Array)
mkisofs		 									#0	Needed to create the ISO file
syslinux 										#1	Needed to make the USB drive bootable
wget											#2	To download the proftp server from vm-help 
unzip											#3	For the installation of proftp
ed												#4	Used to edit text inside files
nano											#5	Used to manually edit files
tar												#6	Used to extract files from compressed files 
bzip2											#7	Used to compress the dd file 
bunzip2										#8	Used to extract bz2 files
md5sum											#9	Is need to create the md5 file on the 4.1 iso
)

array_main_menu=(												#	Main menu (Array)
"Adding customized files to a VMware ESXi installation"			#0	Topic
""																#1
"   	Using $esx_iso_file"									#2	Iso file going to be used
""																#3
"	1) ISO installation"										#4	To create a ISO file to burn on a CD for installation
"	2) USB installation"										#5	Creates custom made files that can be copied to a bootable USB drive for installation
"	3) USB boot"												#6	Creates a custom DD file that can be written to a USB to boot and run ESXi
"	4) USB installation without custom files"					#7	Copies the files from the ISO and make the USB bootable
"	5) USB boot without custom files"							#8	Extract the DD and writes it to a USB drive to boot and run ESXi
"	6) Exit!"													#9	Just exiting the script
" "
" "
)

array_extra_menu=(									#	Extra menu
"     Extra support "
" "
"	1)	FTP support"								#0	If there are going to be FTP support enabled
"	2)	SFTP support"								#1	If there are going to be sFTP support enabled
"	3)	SSH support"								#2	If there are going to be SSH support enabled
"	4)	SSH + FTP support"							#3	If there are going to be FTP and SSH support enabled
"	5)	Continue without any of them"				#4	Exit the ssh/ftp menu without doing anything
)
array_install_text=(
"Installing ${array_pkg_install[*]}"				#0	Install app info
)

array_version=(				#	Versions
"3.5"
"4.0"
"4.1"
)

array_auto_flag=(
-a							#0	Need to be there to run the script non interactiv
-s							#1	If you like to enable ONLY SSH
-e							#2	If you like downloading wget and rsync from vm-help.com
-c							#3	If you have more files in the custom-esx directory
-v							#4	Version you are going to make
-d							#5	USB device 
-i							#6	Installtion typ
-h							#7	Help
)

array_auto_func=(			#	The function that is called in the func_auto_loop , it's indexed with array_auto_flag
func_auto_set_flag			#0
func_auto_add_ssh_ftp		#1
func_auto_add_extra			#2
func_auto_add_custom_files	#3
func_auto_version			#4
func_auto_usb_install		#5
func_auto_dest				#6
func_help_info				#7
)

array_auto_help_text=(		#	The help text 
"	Need to be there to run the script non interactiv"
"	If you like to enable SSH, FTP or SFTP  eg. -s=SSH -s=FTP -s=SFTP defult is "
"	Downloading wget and rsync from vm-help.com."
"	If you have more files in the custom-esx folder."
"	Version you are going to create 3.5 , 4.0 or 4.1 eg. -v=4.1 "
"	If you are creating a USB installtion or boot, -d=/dev/  . ONLY used with -i=USB, -i=DD"
"	Installtion typ ISO USB(install from USB) DD (Boot from USB), -i=ISO, -i=DD or -i=UDB"
"	This help"
)

#	Variables 

install_path="$PWD"										#	Work path
custom_name="VMware_esxi_custom_"						#	The name of the custom made file/directory
save_dir="save"											#	The directory where the custom file/directories  will be  saved
custom_oem_dir="custom-esx"								#	Add files in custom-esx that is going to be in the oem.tgz file.
install_cmd="apt-get -qq -y --force-yes install"		#	The command string used to install 
usb_check_cmd="udevadm"

#	Extra options 

shopt -s dotglob										#	To make * include hidden directorys/files 

#	Functions

function func_text_done() {							#	The [Done] echo after every step
	echo -e "\e[01;32m	[\e[00mDone\e[01;32m]\e[00m"
}

function func_text_green() {							#	Change the text to Green
	printf "\e[01;32m$*\e[00m"
}

function func_text_red() {								#	Change the text to red
	printf "\e[00;31m$*\e[00m"
}

function func_help_info() {							#	The help menu 
	echo
	func_text_green "$0 ${array_auto_flag[@]}"
	echo
	echo
	for index in ${!array_auto_flag[@]};
		do
			func_text_green "%s%s" "${array_auto_flag[index]}" "${array_auto_help_text[index]}"
			echo
		done
	echo
	func_text_green "	e.g. $0 -a -v=4.0 -e -i=ISO -s=SSH -s=FTP"
	echo
	echo
	exit
}

function func_auto_flag() {							#	To grep the flags used when running the script noninteractiv 
	
	local flag=$1
	shift
	while [[ $1 == -* ]]; do
		case "$1" in
			-) return 1;; # by convention, -- is end of options
			"$flag="*) echo "${1#"$flag="}"; return 0;;
			"$flag") return 0 ;;
		esac
		shift
	done
	return 1
}

function func_auto_loop(){								#	Noninteractiv loop 

	local flags
	
	for i in "${!array_auto_flag[@]}"; do 
		if flags=$(func_auto_flag ${array_auto_flag[i]} "$@"); then
			if [[ $flags ]]; then
				${array_auto_func[i]} "$flags"
			else
				${array_auto_func[i]}
			fi
		fi
				

	done

}

function func_checkRoot() {							#	To check if the script is run as a superuser
    if [ ! $( id -u ) -eq 0 ]
		then
			sudo $0
	fi
}

function func_clean(){									#	Cleans up after the script 

	clean_cd=$(mount | awk -v mfold="${array_work_dir[0]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_cd" ]																		#	Checking if there is anything mounted to esx-cd
		then
			echo
			func_text_green "U mounting ${array_work_dir[0]}s"
			umount $ipath/${array_work_dir[0]}
			func_text_done
			sleep 5
	fi

	clean_5=$(mount | awk -v mfold="${array_work_dir[4]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_5" ]																		#	Checking if there is anything mounted to esx-5
		then
			echo
			func_text_green "U mounting ${array_work_dir[4]}"
			umount $ipath/${array_work_dir[4]}
			func_text_done
			sleep 5
	fi


	esx_usb=$(mount | awk -v mfold="${array_work_dir[6]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_usb" ]																		#	Checking if there is anything mounted to esx-usb
		then
			echo
			func_text_green "U mounting ${array_work_dir[6]}"
			umount $ipath/${array_work_dir[6]}
			func_text_done
			sleep 5
	fi

	cd $ipath
	
	shopt -s nullglob
	rm_dirs=(esx-*)
	
	if [[ "${#rm_dirs[@]}" -gt 0 ]]																#	If there is folder left to delete
		then
			func_text_green "Removing working folders (esx-*)"
			rm -R $ipath/esx-*																		#	Cleaning up, removing the folders
			func_text_done
			sleep 5
	fi
	shopt -u nullglob

	if [[ -u "$custom_name" ]]
		then
			chown --from=$USER $SUDO_UID:$SUDO_GID $ipath/*
	fi
}

function func_version() {								#	Version ? $esxi
	
	clear 							#	Clear the screen.
	
	local menu
	
	if [[ -z $auto_flag ]]
		then
			for index in ${!array_extra_menu[@]}
				do
					func_text_green "	%s\n" "${array_extra_menu[index]}";
				done
			func_text_green " Choose what you like to do: "
			read menu
		else
			menu=$1
	fi 
	
	if [[ -z $menu ]]
		then 
			esxi_red "You need to define the version of ESXi you like to create "
			sleep 4
			clear
			exit
	fi

	case "$menu" in
		2 | 4.0 ) 
			esxi_ver="4.0"
			clear
		;;
		1 | 3.5 )
			esxi_ver="3.5"
			clear
		;;
		3 | 4.1 )
			esxi_ver="4.1"
			clear
		;;
		* )
			esxi_red "That's not a valid option"
			sleep 1
			clear 					#	Clear the screen.
			func_version			#	Loop the menu
		;;
	esac
}

function func_menu(){ 									#	Menu function 
	
	clear 												# 	Clear the screen.

	local menu
	
	if [[ -z $auto_flag ]]
		then
			for index in ${!array_main_menu[@]}
				do
					func_text_green "	%s\n" "${array_main_menu[index]}";
				done
			func_text_green " Choose what you like to do: "
			read menu
		else
			menu=$1
	fi 
	

exit
}

function func_auto_set_flag(){ 

echo $1

}
function func_auto_add_ssh_ftp(){ 


local array0

array0+=("$1")

echo "$array0"

}
function func_auto_add_extra(){ 

echo "$1"

}
function func_auto_add_custom_files(){ 

echo $1

}
function func_auto_version(){ 

echo $1

}
function func_auto_usb_install(){ 

echo $1

}
function func_auto_dest(){ 

echo $1

}


func_checkRoot ./$0										#	Starts with a check that you are superuser
func_auto_loop "$@"										#	To make the script nonintractiv
# func_menu
func_clean												#	Deletes work folders if there is any