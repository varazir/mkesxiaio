#!/bin/bash
#exec > >(tee vars1.log) 2>&1
#set -x
#set logs.log


#	INFO
#	All you need is to download this file and the vmware ESXi ISO file
#	sudo chmod +x mkesxiaio_x.x.sh
#	sudo ./mkesxiaio_x.x.sh
#
#	You need 2GB of free space to run the script 
#
#	Then you need a blank USB drive minimum 1GB OBS if this script
#	breaks your USB drive or you loose DATA don't blame me.
#	There will be warnings* before anything happens to the USB drive.
#
#	I will test all installations types(script) on my Ubuntu system
#
#
#
#	*If you don't run noninteracting 
	

####################Contact information####################
#
#	You can find me on Vmware's forum or www.vm-help.com/forum/index.php as Varazir
#	E-mail varazir@gmail.com
#		


#  Array
array_work_dir=(					#	Work directories (Array)
esx-cd 										#0	Mount point for the ISO file will
esx-temp 									#1	Where the install.tgz will be extracted
esx-ienv 									#2	Where the ienviron.tgz will be extracted
esx-oem 									#3	Where the OEM file will be extracted
esx-5 										#4	Mount point for the dd file
esx-build									#5	The work directory
esx-usb										#6	Mount point for the USB drive
esx-ftp										#7	Where the proftpd.zip will be extracted
esx-download							#8	Where I download all files needed during the script
)

array_cmd_install=( 			#	Pkg's that is needed for this script (Array)
mkisofs		 								#0	Needed to create the ISO file
syslinux 									#1	Needed to make the USB drive bootable
wget											#2	To download the proftp server from vm-help 
unzip											#3	For the installation of proftp
ed												#4	Used to edit text inside files
nano											#5	Used to manually edit files
tar												#6	Used to extract files from compressed files 
bzip2											#7	Used to compress the dd file 
bunzip2										#8	Used to extract bz2 files
md5sum										#9	Is need to create the md5 file on the 4.1 iso
parted										#10	Add the Boot flag to the USB 
fdisk											#11	Used to get mount info 
)

array_main_menu=(												#	Main menu (Array)
"Adding customized files to a VMware ESXi installation"			#0	Topic
""																													#1
"   	Using"																								#2	Iso file going to be used
""																													#3
"	1) ISO installation"																			#4	To create a ISO file to burn on a CD for installation
"	2) USB installation"																			#5	Creates custom made files that can be copied to a bootable USB drive for installation
"	3) USB boot"																							#6	Creates a custom DD file that can be written to a USB to boot and run ESXi
"	4) USB installation without custom files"									#7	Copies the files from the ISO and make the USB bootable
"	5) USB boot without custom files"													#8	Extract the DD and writes it to a USB drive to boot and run ESXi
"	6) Exit!"																									#9	Just exiting the script
" "
" "
)

array_version=(				#	Versions
"3.5"
"4.0"
"4.1"
)

array_auto_flag=(
-q							#0	Skipp install
-a							#1	Need to be there to run the script non interactive
-v							#2	Version you are going to make
--ssh						#3	If you like to enable SSH
--sftp					#4	If you like to download and enable sftp
--ftp						#5	If you like to download and enable ftp
--wget					#6	If you like downloading wget from vm-help.com
--rsync					#7	If you like downloading rsync from vm-help.com
--iso						#8	Need to be set when ruining the script non interactive
--oem						#9	You need to set the oem file you are going to use
-c							#10	If you have more files in the custom-esx directory
-d							#11	USB device 
-i							#12	Installation type
-h							#13	Help
--clean					#14	Clean up folders
--test					#15 used to test function in the script
)

array_auto_func=(						#	The function that is called in the func_auto_loop , it's indexed with array_auto_flag
func_skipp_install					#0
func_auto_set_flag					#1
func_version								#2
func_add_ssh								#3
func_add_sftp								#4
func_add_ftp								#5
func_add_wget								#6
func_add_rsync							#7
func_check_iso							#8
func_check_oem							#9
func_auto_add_custom_files	#10
func_auto_usb_device				#11
func_main_menu							#12
func_help_info							#13
func_auto_clean							#14
func_debug									#15
)

array_auto_help_text=(		#	The help text 
"		Used to skip the installation Can't be used with -a "
"		Need to be there to run the script non interactive"
"		Version you are going to create 3.5 , 4.0 or 4.1 eg. -v=4.1 "
"		If you like to enable SSH, OBS with 4.1 you do not need to enable SSH"
"	If you like to enable SFTP, You can read more here http://thebsdbox.co.uk/?p=224"
"		If you like to enable FTP, downloaded from http://www.vm-help.com"
"	Downloading wget and rsync from vm-help.com."
"	Downloading rsync from vm-help.com."
"		The name of the iso file you are going to use --iso=vmware.iso"
"		Set the name of the oem file you like to use --oem=oem.tgz"
"		If you have more files in the custom-esx folder."
"		If you are creating a USB installation or boot, -d=/dev/  . ONLY used with -i=USB, -i=DD"
"		Installation type ISO USB(install from USB) DD (Boot from USB), -i=ISO, -i=DD or -i=USB"
"		This help"
"	If you aborted the script and like to clean up the folders"
"		Used to debug functions in the script"
)

#	Variables 

install_path="$PWD"										#	Work path
custom_name="VMware_esxi_custom_"						#	The name of the custom made file/directory
save_dir="save"											#	The directory where the custom file/directories  will be  saved
custom_oem_dir="custom-esx"								#	Add files in custom-esx that is going to be in the oem.tgz file.
install_cmd="apt-get -qq -y --force-yes install"		#	The command string used to install 
usb_check_cmd="udevadm"
first_time=0
all_installed=0
esx_bytes="bytes"
fdisk_cmd="fdisk"
#	Extra options 

shopt -s dotglob							#	To make * include hidden directories/files 

#	Functions

func_skipp_install() {	#	Used to skip the installtion if you run script several times using -q 

all_installed=1

}

func_auto_clean() {			#	If you like just like to clean up the folders using --clean 

func_clean

exit 0

}

func_text_done() {			#	The [Done] echo after every step

if [[ $? == 0 ]]
	then
		echo -e "\e[01;32m	[\e[00mDone\e[01;32m]\e[00m"
	else
		echo -e "\e[00;31m	[\e[00mFail\e[00;31m]\e[00m"
		
		echo
		
		func_text_red "The script failed for som reason, \n if you can't solve it your self please make a post on http://vm-help.com/forum"
		
		exit 1
fi

}

func_text_green() {			#	Change the text to Green
	printf "\e[01;32m$*\e[00m"
}

func_text_red() {				#	Change the text to red
	printf "\e[00;31m$*\e[00m"
}

func_help_info() {			#	The help menu 
	echo
	func_text_green "$0 ${array_auto_flag[@]}"
	echo
	echo
	for index in ${!array_auto_flag[@]};
		do
			func_text_green "%s%s" "${array_auto_flag["$index"]}" "${array_auto_help_text["$index"]}"
			echo
		done
	echo
	func_text_green "	e.g. $0 -a -v=4.0 -i=ISO --ssh"
	echo
	echo
	func_clean											#	Deletes work folders if there is any
	exit
	
	

}

func_auto_flag() {			#	To grep the flags used when running the script noninteracting 
														#	http://mywiki.wooledge.org/BashFAQ/035
	local flag=$1
	shift
	while [[ $1 == -* ]]; do
		case "$1" in
			--) return 1;; # by convention, - is end of options
			"$flag="*) echo "${1#"$flag="}"; return 0;;
			"$flag") return 0 ;;
		esac
		shift
	done
	return 1
}

func_auto_loop(){				#	Noninteracting loop 

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

func_debug(){						#	Added so I can test/debug a function in the script 

$1

exit 0

}

func_auto_set_flag(){ 	#	Sets the auto flag, installs bin, creates folders

auto_flag=1

func_clean
func_install_cmd								#	Checks if apt-get is installed 
func_pkg_inst									#	Install the pkg's needed
func_create_folders								#	Create folders 

}

func_add_ssh(){ 				#	Adds ssh support for 3.5 and 4.0 

if [[ "$1" != "y" && -z "$auto_flag" ]]
	then
		local menu
		
		func_text_green "Do you like to add ssh? \e[00m [Y/n]"
		read menu
		
		case $menu in 
		
		"Y" | "y" | "" )
			
		if [[ "$esxi_version" != "4.1" ]]
			then
				func_edit_file "^#ssh" "ssh" $install_path/inetd.conf
				custom_name=${custom_name}ssh_
		fi
		;;
		"N" | "n" | * )
		;;
		esac
		
	else
		
		if [[ "$esxi_version" != "4.1" ]]
			then
				func_edit_file "^#ssh" "ssh" $install_path/inetd.conf
				custom_name=${custom_name}ssh_
		fi
		
fi

}

func_add_sftp(){ 				#	Adds sftp support

func_check_dir $install_path/${array_work_dir[3]}/sbin	#	Check if there is all ready a sbin folder

func_download "http://thebsdbox.co.uk/wp-content/uploads/2010/08/sftp-server.tar.gz" "sftp-server.tar.gz" "$install_path/${array_work_dir[7]}/" "$1" "sftp_"

	if [[ -e $install_path/${array_work_dir[7]}/sftp-server.tar.gz ]]
		then
			func_text_green "Untar sftp-server.tar.gz to $install_path/${array_work_dir[3]}/sbin"
			${array_cmd_install[6]} -xzf $install_path/${array_work_dir[7]}/sftp-server.tar.gz -C $install_path/${array_work_dir[3]}/sbin
			func_text_done
		else
			func_text_red "No file was downnloaded, sftp is not installed"
			sleep 3
	fi

}

func_add_ftp(){ 				#	Adds FTP support

	func_download "http://www.vm-help.com/esx/esx3i/ftp/proftpd.zip" "proftpd.zip" "$install_path/${array_work_dir[7]}" $1
	
	if [[ -e $install_path/${array_work_dir[7]}/proftpd.zip ]]
		then
			
			func_check_dir $install_path/${array_work_dir[3]}/sbin	#	Check if there is all ready a sbin folder
			func_check_dir $install_path/${array_work_dir[3]}/etc		#	Check if there is all ready a etc folder

			cd $install_path/${array_work_dir[7]}
			
			${array_cmd_install[3]} -qq proftpd.zip 2>/dev/null
			
			cd $install_path/${array_work_dir[7]}/proftpd
			
			if [[ ! -e $install_path/${array_work_dir[3]}/etc/proftpd.conf ]]
				then
					func_text_green "Copy the proftpd.conf to $install_path/${array_work_dir[3]}/etc"
					cp proftpd.conf $install_path/${array_work_dir[3]}/etc
					func_text_done
			fi
			
			func_text_green "Copy the proftpd to $install_path/${array_work_dir[3]}/sbin"
			cp proftpd $install_path/${array_work_dir[3]}/sbin
			func_text_done
			
			func_text_green "Copy the tcpd to $install_path/${array_work_dir[3]}/sbin"
			cp tcpd $install_path/${array_work_dir[3]}/sbin
			func_text_done

			if [[ "$esxi_version" == "3.5" ]]
				then
					func_edit_file "^#ftp" "ftp" $install_path/inetd.conf
					func_edit_file "in.ftpd" "proftpd" $install_path/inetd.conf 
				else
					echo "ftp    stream  tcp     nowait  root    /usr/sbin/tcpd  proftpd" >> $install_path/inetd.conf
					echo "" >> $install_path/inetd.conf

			fi
			if [[ -z $auto_flag ]]
				then
					func_edit $install_path/${array_work_dir[3]}/etc/proftpd.conf
			fi
			
			custom_name=${custom_name}ftp_
	fi
	
}

func_add_wget(){ 				#	Downloads wget from vm-help.com

func_check_dir $install_path/${array_work_dir[3]}/sbin

func_download "http://www.vm-help.com/esx/esx3i/Enable_FTP/wget" "wget" "$install_path/${array_work_dir[3]}/sbin" "$1" "wget_"

}

func_add_rsync(){ 			#	Downloads rsync from vm-help.com 

func_check_dir $install_path/${array_work_dir[3]}/sbin

func_download "http://www.vm-help.com/esx/esx3i/Enable_FTP/rsync" "rsync" "$install_path/${array_work_dir[3]}/sbin" "$1" "rsync_"

}

func_add_custom_files(){		#	Add custom files from the custom-esx dir, 


if [[ "$1" != "y" && -z "$auto_flag" ]]
	then
		local menu
		
		func_text_green "Do you like to add custom file from $custom_oem_dir ? \e[00m [y/N]"
		read menu
		
		case $menu in 
		
		"Y" | "y" )
		
		func_text_green "Copy $install_path/$custom_oem_dir/ to $install_path/${array_work_dir[3]}/"
		cp -r $install_path/$custom_oem_dir/*  $install_path/${array_work_dir[3]}/
		func_text_done
		;;
		"N" | "n" | "" | * )
		;;
		esac
		
	else
		func_text_green "Copy $install_path/$custom_oem_dir/ to $install_path/${array_work_dir[3]}/"
		cp -r $install_path/$custom_oem_dir/*  $install_path/${array_work_dir[3]}/
		func_text_done
fi



}

func_auto_usb_device(){	#	$usb_install Sets the USB device that are going to be used in the script

usb_install=$1

}

func_install_cmd(){			#	Check if apt-get/yum is there and if not asks for a new install bin
	
	if [[ "$all_installed" == 0 ]]
		then
			echo
			echo
			func_text_green "	Installing..."
			echo

			if hash apt-get 2>/dev/null
				then
					func_text_green "	apt-get is already installed"
					echo
					sleep 2
				else
					if hash yum 2>/dev/null
						then
							func_text_green "	yum is already installed"
							install_cmd="yum -y -q install"
							echo
							sleep 2
						else
							local ibin
							func_text_red "\n	Standard command is $install_cmd, \n	apt-get can't be found on your system \n	Please specify the install command for your system\n"
							func_text_green "	Type whole command similar to the command above \n	"
							read ibin
							install_cmd="$ibin" 
					fi
			fi
	fi
}

func_pkg_inst(){				#	Loop to find binaries and installed them if need be

local pkgbin

if [[ "$all_installed" == 0 ]]
	then
		for pkgbin in ${!array_cmd_install[@]}
		do	
			if hash ${array_cmd_install["$pkgbin"]} 2>/dev/null
				then 
					func_text_green "	${array_cmd_install["$pkgbin"]}  is already installed"
					echo
					sleep 2
				else
					$install_cmd ${array_cmd_install["$pkgbin"]} 2>/dev/null
					if [ ! $? -eq 0 ]
						then
							echo
							func_text_red "	Script encountered an error during package installation. ${array_cmd_install["$pkgbin"]}   \n	Check errors and retry"
							echo
							exit 1
					fi
					func_text_green "	${array_cmd_install["$pkgbin"]}  is now installed"
					
					array_cmd_install["$pkgbin"]=$( find /bin /sbin -perm +x -name ${array_cmd_install["$pkgbin"]} -type f -print0)

					
					echo
			fi
		done
		sleep 2
		clear
fi



}

func_check() {					#	Checking for files $file_to_use
	

	shopt -s nullglob
	local array_check_files=($2)							#	Creating a array if there is more then one file
		
		if [[ "${#array_check_files[@]}" == 0 ]]
			then
				clear 										#	Clear the screen.
				echo
				func_text_red "	No $1 file.. $3 Exiting"
				echo
				sleep 5
				clear 										#	Clear the screen.
				func_clean
				exit 1
		fi
	shopt -u nullglob
	
	if [[ "${#array_check_files[@]}" -gt 1 ]]				#	If there is more then one file
		then
			array_check_files[100]="Exit"
			func_check_menu ${array_check_files[@]:0}
		else
			file_to_use="${array_check_files[*]}"
	fi
}

func_check_menu() {			#	Checking for files menu
	
	local check_files
	
	clear 							#	Clear the screen.
	
	PS3='Which file are you going to use?  '

	func_text_green "There is more then one ${array_check[0]} file"
	echo

	select check_files 

	do
		if [ -z $check_files ]
			then
				clear 									#	Clear the screen.
				func_check "${array_check[@]:0}"
				clear 									#	Clear the screen.
			else	
				if [ "$check_files" = "Exit" ]
					then
						clear 							#	Clear the screen.
						echo
						func_text_red "Exiting ...."
						echo
						echo
						sleep 2
						func_clean
						clear 							#	Clear the screen.
						exit 0
					else
						file_to_use="$check_files"
				fi
		fi
	break
	done
	clear
}

func_check_iso() {			#	Check if there is more then one iso file and sets the file to be used as $esxi_iso_file 
	
	local array_check
	
	if [[ -z $auto_flag ]]
		then
			cd $install_path
			array_check=(ISO "*.iso")
			func_check "${array_check[@]:0}"
			esxi_iso_file="$file_to_use"
			custom_name=${custom_name}${esxi_version}_
		else
			if [[ $1 ]]								#	If you are using the auto function and haven't set -iso it till stop the script
				then
					esxi_iso_file="$1"
					custom_name=${custom_name}${esxi_version}_
				else
					func_text_red "You have to set the iso file to use -iso=Vmware...iso"
					echo
					sleep 3
					exit
			fi
	fi

}

func_check_oem() {			#	Check if there is more then one oem $esxi_oem_file 


	
	local array_check
	
	if [[ -z $auto_flag ]]
			then
				cd $install_path
				array_check=("OEM" "*oem*.*")
				func_check "${array_check[@]:0}"
				esxi_oem_file="$file_to_use"
			else
				if [[ -z $1 ]]							#	If you are using the auto function and haven't set -iso it till stop the script
					then
						func_text_red "You have to set the oem file you are going to use -oem=oem.tgz"
						echo
						sleep 3
						exit
					else
						esxi_oem_file="$1"
				fi
	fi
	
	func_text_green "Untar $esxi_oem_file to $install_path/${array_work_dir[3]}"
	${array_cmd_install[6]} -xzf $install_path/$esxi_oem_file -C $install_path/${array_work_dir[3]}						#	Untaring the oem.tgz
	func_text_done
	
	
}

func_check_inetd() {		#	Check if there is a inetd file $esx_inetd_file


	
	if [[ "$esxi_version" == "4.1" ]]
		then
			func_download "http://mkesxiaio.googlecode.com/svn/new/inetd.conf" "inetd.conf" "$install_path/" "y"
		else
			func_download "http://mkesxiaio.googlecode.com/svn/trunk/inetd.conf" "inetd.conf" "$install_path/" "y"
	fi
	
	local array_check
	cd $install_path
	array_check=(inetd.conf "*inetd*")
	func_check "${array_check[@]:0}"
	esxi_inetd_file="$file_to_use"
}

func_download() {				#	Used to download files, URL, file , dest , Auto , what to add to the final name

	cd $install_path/${array_work_dir[8]}

	local download
	
	if [[ "$auto_flag" || "$4" == "y" ]]
		then
			func_text_green "Downloading $1 to $3"
			${array_cmd_install[2]} -q $1 2>/dev/null
			func_text_done
			func_check $2 $2 "please check your internet connection and try again"
			mv $2 $3
			custom_name=${custom_name}$5
			
		else
			func_text_green "Do you like to download $1 ? \e[00m [Y/n] "
			read download

	
			case $download in
				
				"Y" | "y" | "" )
				func_text_green "Downloading $1 to $3"
				${array_cmd_install[2]} -q $1 2>/dev/null
				func_text_done
				func_check $2 $2 "please check your Internet connection and try again"
				mv $2 $3
				custom_name=${custom_name}$5
				;;
				
				"N" | "n" )
				;;
				
				*)
				func_text_green "Downloading $1 to $3"
				${array_cmd_install[2]} -q $1 2>/dev/null
				func_check $2 $2 "please check your Internet connection and try again"
				mv $2 $3
				custom_name=${custom_name}$5
				;;
			esac

	fi
}

func_version(){					#	Version ?

	clear
	
	local menu
	local count=0
	
	if [[ -z $auto_flag ]]
		then
			func_text_green  "  For which version of ESXi are you going to create a custom image ?"
			echo
			for index in ${!array_version[@]}
				do
					((count++))
					func_text_green "\n	["$count"] %s" "${array_version["$index"]}";
				done
				echo
			func_text_green "	Select:"
			read menu
		else
			menu=$1
	fi

	case "$menu" in
		"2" | "4.0" ) 
			esxi_version="4.0"
			clear
		;;
		"1" | "3.5" )
			esxi_version="3.5"
			clear
		;;
		"3" | "4.1" )
			esxi_version="4.1"
			clear
		;;
		* )
			if [[ -z $auto_flag ]]
				then
					func_text_red "You need to define the version of ESXi you like to create "
					sleep 4
					clear
					exit 1
				else
					func_text_red "That's not a valid option"
					sleep 1
					clear 					#	Clear the screen.
					func_version			#	Loop the menu
			fi
	esac
	
	func_check_inetd									#	Check and download the correct inetd.conf file
	
}

func_checkRoot() {			#	To check if the script is run as a superuser
    if [ ! $( id -u ) -eq 0 ]
		then
			sudo $0
	fi
}

func_clean(){						#	Cleans up after the script 

	local clean_cd
	local clean_5
	local esx_usb
	local rm_dirs

	clean_cd=$(mount | awk -v mfold="${array_work_dir[0]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_cd" ]																		#	Checking if there is anything mounted to esx-cd
		then
			echo
			func_text_green "U mounting ${array_work_dir[0]}s"
			umount $install_path/${array_work_dir[0]}
			func_text_done
			sleep 5
	fi

	clean_5=$(mount | awk -v mfold="${array_work_dir[4]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_5" ]																		#	Checking if there is anything mounted to esx-5
		then
			echo
			func_text_green "U mounting ${array_work_dir[4]}"
			umount $install_path/${array_work_dir[4]}
			func_text_done
			sleep 5
	fi


	esx_usb=$(mount | awk -v mfold="${array_work_dir[6]}" '$0 ~ mfold {print $3}')

	if [ -n "$clean_usb" ]																		#	Checking if there is anything mounted to esx-usb
		then
			echo
			func_text_green "U mounting ${array_work_dir[6]}"
			umount $install_path/${array_work_dir[6]}
			func_text_done
			sleep 5
	fi

	cd $install_path
	
	shopt -s nullglob
	rm_dirs=(esx-*)
	
	if [[ "${#rm_dirs[@]}" -gt 0 ]]																#	If there is folder left to delete
		then
			func_text_green "Removing working folders (esx-*)"
			rm -R $install_path/esx-*																		#	Cleaning up, removing the folders
			func_text_done
			sleep 5
	fi
	shopt -u nullglob

	chown -R --from=$USER $SUDO_UID:$SUDO_GID $install_path/*

}

func_create_folders() {	#	Create folders

	func_clean

	cd $install_path									#	Change so the start path is correct
		
	clear						 						#	Clear the screen.
		
	func_check_dir $install_path/$save_dir			#	Check if there is all ready a save folder
	func_check_dir $install_path/$custom_oem_dir		#	Check if there is a custom oem folder and creates it if need 
	
	shopt -s nullglob
	
	local array_rm=(esx-*)
	
	echo
	
	if [[ ${#esx_rm[@]} == 0 ]]						#	If there is any working folder left
		then
			func_text_green "Creating folders ${array_work_dir[*]}"
			mkdir ${array_work_dir[*]}
			func_text_done
			sleep 2
			if [[ -n "$install_inst_type" ]] 
				then
					func_set_file_rights
			fi
		else											#	If there is folders it will delete them and start over
			clear 										#	Clear the screen.
			echo
			func_text_red "There was some working dir left, \n deleting them and restarting the script"
			echo
			sleep 4
			func_clean
			func_create_folders

	fi
	shopt -u nullglob
	
	array_folders[8]=custom-esx							#8	Where you can add files you like to be added to the oem file.
}

func_check_dir() {			#	Checks the dir given 
	
	if [ ! -d $1	]; then							#	Check if there is all ready a folder
		func_text_green "Creating $1"
		mkdir -p $1									#	Creates the folder
		func_text_done
		sleep 2
	fi
}

func_add_service(){			#	Calls the add functions for wget,rsync,ftp,sftp and ssh

	local loop=$1

	if [[ -z $auto_flag ]]
		then
			
			local menu

			func_text_green "Do you like to install All[Y] (wget, rsync, ftp, sftp and ssh) or [s]eparate or [n]one ? \e[00m [Y/s/n]"
			read menu
			
			case $menu in
				
				"Y" | "y" | "" )
				func_add_ssh $loop
				func_add_wget $loop
				func_add_rsync $loop
				func_add_sftp $loop
				func_add_ftp $loop
				;;
				
				"S" | "s" )
				func_add_ssh 
				func_add_wget 
				func_add_rsync 
				func_add_sftp
				func_add_ftp 				
				;;

				"N" | "n" )
				echo
				;;
				
				* )
				func_text_red "	That's not a valid option"
				first_time=1
				sleep 1
				clear 					#	Clear the screen.
				func_add_service $loop	#	Loop the menu
				;;
				
			esac
	fi
}

func_edit_file() {			#	Change a files 
	
	func_text_green "Replacing $1 with $2 in $3"
	${array_cmd_install[4]} -s $3 <<< ",s/$1/$2/g"$'\nw'
	func_text_done
	sleep 1
}

func_file_name(){				#	Sets the name on the file / folder $esxi_finish
	
	esxi_finish="$custom_name${esxi_oem_file%*.tgz}.$install_inst_type"
	
}

func_check_old() {			#	Checking for old custom files/folders

if [[ -z $auto_flag ]]
	then

		cd $install_path

		if [[ -d $install_path/$save_dir ]]														#	Check if there is all ready a save folder
			then
				cd $install_path/$save_dir
				local check_old_file="$esxi_finish"
					if [[ -e $check_old_file ]]
						then
							clear 						#	Clear the screen.
							if [[ -z $auto_flag ]]
								then
									echo
									func_text_red " You have all ready made a custom file/folder \n \n $check_old_file"
									echo
									echo
									func_text_red " Do you like to delete that file/folder\n and continue the script or (u)se it again  ?\e[00m [u/y/N] "
									read key
								else
									key="Y"
							fi
							
							case "$key" in
							"Y" | "y" )
								rm -R $check_old_file		#	Deleting the old file
								cd $install_path
								clear 						#	Clear the screen.
								;;
							"N" | "n" | '' )
								echo
								func_text_red " OK good luck with the one you have"
								echo
								func_text_red " You can find the files at \n $install_path/$save_dir"
								echo
								echo
								sleep 3
								clear 					#	Clear the screen.
								func_clean
								exit 0
								;;
							"U" | "u" )
								if [[ "$install_inst_type" == "usb" ]]
									then
										func_usb_finish
										func_clean
										exit
									else
										if [[ "$install_inst_type" == "dd" ]]
											then
												func_dd_finish
												func_clean
												exit
											else
												func_check_old
										fi
								fi
							;;
							* )
								esxi_check_old
								;;
							esac
				fi
		fi
	else
		rm -rf $install_path/$save_dir/$esxi_finish
fi
}

func_edit(){						#	Edit files
	
	local loop=$1
	local orgfile=$1
	local edfile
	local findfile
	
	if [[ -z $auto_flag ]]
		then

			if [[ ! -e $loop ]]
				then
					func_text_red "The file you like to edit can't be found \n	$loop \n Do you like to find the file and then edit it ? \e[00m [y/N] "
					read findfile
					
					case $findfile in
					
						"Y" | "y" | '' )
						loop=$(find $install_path -name ${loop##*/} -type f -print0)
						;;
					
						"N" | "n" )
						;;
						
					esac
				clear
			fi
			
			func_text_green "Do you like to edit $loop ? \e[00m [y/N] "
			read edfile
		
		else
			edfile="N"
	fi
	
	case $edfile in
		
		"Y" | "y" )
			if hash ${array_cmd_install[5]} 2>/dev/null
				then 
					${array_cmd_install[5]} $loop
					clear
				else
					func_text_red "\n \n ${array_cmd_install[5]} is not installed \n Please install it manually  and rerun the script"
			fi
		;;
		
		"N" | "n" | '' )
		;;
		
		*)
			clear
			func_edit $loop
		;;
	esac
	
	
	if [[ "$loop" != "$orgfile" ]]
		then
			func_text_green "Moving $loop to $orgfile"
			cp $loop $orgfile
	fi
	
}

func_set_file_rights(){	#	Change the ownership and permissions for files
	
	if [[ $esxi_version == "3.5" ]]
		then 
			func_text_green "Changing ownership and mod on install.tgz"
			chown -R 201:201 $install_path/${array_work_dir[5]}/install.tgz 										#	Channing the ownership and mod for install.tgz
			chmod 755 $install_path/${array_work_dir[5]}/install.tgz
			func_text_done

			func_text_green "Changing ownership on the files in the ${array_work_dir[5]} folder"				#	Channing the ownership and mod on the files in the build folder
			
			chown -R 201:201 $install_path/${array_work_dir[5]}/*
			chmod 755 $install_path/${array_work_dir[5]}/oem.tgz
			func_text_done
	fi
}

func_check_files(){			#	Check if the files is in the folder
	
	shopt -s nullglob
	local i=($install_path/$1/*)
		if [ -z "$i" ]
			then
				func_text_red " There is no files in $install_path/$1 please check the dir/files"
				echo
				sleep 2
				exit 1
		fi
	shopt -u nullglob;
}

func_move_files(){			#	To move the work file / dir to the save folder

	if [[ ! -e $install_path/$save_dir/$esxi_finish ]]
		then
			func_text_green "Moving $1 to $install_path/$save_dir/$esxi_finish "
			mv -f $1 $install_path/$save_dir/$esxi_finish						#	Moving the DD/dir file to work folder and rename it
			chown $SUDO_UID:$SUDO_GID $install_path/$save_dir/$esxi_finish
			chmod -x $install_path/$save_dir/$esxi_finish
			sleep 2
			func_text_done
			clear 																	#	Clear the screen.
	fi

}

func_redo(){						#	Redo the operation 

local redo=$1
local key

func_text_green "Do you like to create another? \e[00m [y/N] "
	if [[ -z $auto_flag ]]
		then
			read key
		else
			key="N"
	fi

case "$key" in
	"Y" | "y" )
		$redo
		;;
	"N" | "n" | '' )
		;;
	* )
		func_redo $redo
		;;
esac

}

func_kickstart(){				#	If you like to add a kickstart file, it force the system to USB device and you can set ip adress etc 

local array_kickstart=(
"Ipadress"
"Gateway"
"DNS server"
"Netmask"
"Hostname"
)

local kickstart

func_text_red "A kickstart file is used to autoinstall ESXi \nmake sure you know what you are doing \nyou will be able to edit the file later \n"
func_text_green "Do you like to add a kickstart file ? \e[00m [y/N] "
	if [[ -z $auto_flag ]]
		then
			read kickstart
		else
			kickstart="N"
	fi

	case $kickstart in

		"Y" | "y" )
			for ks in ${!array_kickstart[@]}
				do 
					func_text_green "Please type in the ${array_kickstart["$ks"]} for your ESXi system: "
					local input
					read input
					array_kickstart_setting["$ks"]="$input"
				done
		;;
		"N" | "n" | "" )
		return 0
	esac
				

local array_kscfg=(
"vmaccepteula"
"# rootpw cluster	# Remove the first # and change the password if you like it to be autoset"
"# autopart --firstdisk --overwritevmfs	# Remove the first # if you like it to install to the first disk"
"install usb"
"network --bootproto=static --ip=${array_kickstart_setting[0]} --gateway=${array_kickstart_setting[1]} --hostname=${array_kickstart_setting[4]} --device=vmnic0 --nameserver=${array_kickstart_setting[2]} --netmask=${array_kickstart_setting[3]}"
)

func_text_green "Creating the kickstart config file"
printf %s\\n "${array_kscfg[@]}" >> $install_path/${array_work_dir[5]}/ks.cfg
func_text_done

func_text_green "Please make sure the ks.cfg is correct"
echo
sleep 1

func_edit $install_path/${array_work_dir[5]}/ks.cfg

func_text_green "Adding the kickstart to isolinux.cfg"
echo
func_edit_file "vmkboot.gz" "vmkboot.gz ks=usb" "$install_path/${array_work_dir[5]}/isolinux.cfg"


}

func_main_menu(){ 			#	Main menu function 
	
	clear 												# 	Clear the screen.
	
	if [[ $first_time == 0 ]]
		then
			array_main_menu=("${array_main_menu[@]/   	Using/   	Using $esxi_iso_file}")
	fi
	
	local menu
	
	if [[ -z $auto_flag ]]
		then
			for index in ${!array_main_menu[@]}
				do
					func_text_green "	%s\n" "${array_main_menu["$index"]}";	#	Creates the main menu 
				done
			func_text_green " Choose what you like to do: "
			read menu
		else
			if [[ -z $1 ]]													#	If you are using the auto function and haven't set -i it till stop the script
				then
					func_text_red "You have to set type of installation -i=ISO ..."
					echo
					sleep 3
					exit
				else
					menu=$1
			fi
	fi 
	case "$menu" in
		1 | ISO | iso )
			install_inst_type="iso"				#	Setting the installation type to ISO
			func_check_oem $esxi_oem_file		#	Check witch OEM file to use, if the script run in non interactive $esxi_oem_file already set
			func_copy_iso						#	Copy the iso to the hdd
			func_add_service y					#	Adds SSH, FTP, wget, rsync, sftp
			func_file_name						#	Set's the file/folder name
			func_check_old						#	Check if there is any iso/dd/folder created with this custom files
			func_dd_start						#	Extract the DD file
			func_dd_end							#	Uncompress the dd and mount it. Uncompress environ.tgz copy inetd.conf. 
												#	Copy the OEM file and unmount, Compress the dd file and rebuild the install.tgz copy the OEM file
			func_iso_finish						#	Making the ISO file
			func_clean							#	Cleaning up folders
		;;

		2 | USB | usb )
			install_inst_type="usb"	#	Setting the installation type FOLDER
			func_check_oem $esxi_oem_file
			func_copy_iso
			func_add_service y
			func_file_name
			func_check_old
			func_dd_start
			func_dd_end
			func_usb_finish 		#	Moving/rename the esx-build folder to the save folder and copy the files to the USB drive
			func_clean
		;;

		3 | DD | dd )
			install_inst_type="dd"		#	Setting the installation type to DD
			func_check_oem  $esxi_oem_file
			func_copy_iso
			func_add_service y
			func_file_name
			func_check_old
			func_dd_start
			func_dd_end
			func_dd_finish			#	Rename dd file, move it to the save folder and write it to the USB drive
			func_clean
		;;

		4)	#	USB installation without changes
		
			install_inst_type="usb"	#	Setting the installation type to fold
			custom_name="$esxi_iso_file"
			func_copy_iso
			func_file_name
			func_check_old
			func_usb_finish
			func_clean
		;;
		
		5)	#	Boot from USB without changes
		
			install_inst_type="dd"		#	Setting the installation type to DD
			esxi_custom="$esxi_iso_file"
			func_copy_iso
			func_file_name
			func_check_old
			func_dd_start
			func_dd_finish
			func_clean
		;;
		
		6)
			clear 					#	Clear the screen.
			func_clean
			exit 0
		;;

		*)
			func_text_red "	That's not a valid option"
			first_time=1
			sleep 1
			clear 					#	Clear the screen.
			func_main_menu			#	Loop the menu
		;;

	esac


}

func_copy_iso() {				#	Copy the files on the ISO to the build folder
	
	func_text_green "Mounting $install_path/$esxi_iso_file file to $install_path/${array_work_dir[0]}"
	mount -o loop $install_path/$esxi_iso_file $install_path/${array_work_dir[0]} >/dev/null 2>&1	#	Mounting the ISO file to the esx-cd folder
	func_text_done

	func_check_files "esx-cd"
	
	func_text_green "Copy CD to $install_path/${array_work_dir[5]}"
	cp -r -p $install_path/${array_work_dir[0]}/* $install_path/${array_work_dir[5]}							#	Copying files from ISO to the build folder keeping attributes
	func_text_done

	sleep 3		# To make sure that the device isn't busy
	
	func_text_green "U mounting $install_path/${array_work_dir[0]}"
	umount $install_path/${array_work_dir[0]}															#	U mounting the ISO
	func_text_done
	
	func_check_files "esx-build"
	
	if [[ "$custom_name" != "$esxi_iso_file" ]]
		then
			if [[ $esxi_version == "3.5" ]]
				then 
					if [[ -e  "$install_path/${array_work_dir[5]}/oem.tgz" ]]
						then 
							func_text_green	"Removes the oem file from ${array_work_dir[5]}"
							rm $install_path/${array_work_dir[5]}/oem.tgz
							func_text_done
						else
							func_text_red "There is no oem.tgz file please check if you have a ESXi 3.5 iso file"
							sleep 5
							
							clear
							exit
					fi
			fi
	fi
	sleep 2
	clear
}

func_dd_start(){				#	Extracting DD file

	if [[ $esxi_version == "3.5" ]]
		then
			func_text_green "Untar install.tgz to $install_path/${array_work_dir[1]}"
			${array_cmd_install[6]} -xzf $install_path/${array_work_dir[5]}/install.tgz -C $install_path/${array_work_dir[1]}						#	Untaring the installation.tgz file to get the dd file
			func_text_done
			cd $install_path/${array_work_dir[1]}/usr/lib/vmware/installer/

		else
			if [[ $esxi_version == "4.0" ]]
				then
					func_text_green "Untar image.tgz to $install_path/${array_work_dir[1]}"
					${array_cmd_install[6]} -xzf $install_path/${array_work_dir[5]}/image.tgz -C $install_path/${array_work_dir[1]}						#	Untaring the installation.tgz file to get the dd file
					func_text_done
					cd $install_path/${array_work_dir[1]}/usr/lib/vmware/installer/

			fi
	fi
	
	if [[ $esxi_version == "4.1" ]]
		then 
			cd $install_path/${array_work_dir[5]}/
	fi
	
	dd_file=(*.bz2)

	func_text_green "${array_cmd_install[8]} ${dd_file[0]} "
	${array_cmd_install[8]} ${dd_file[0]}				#	Uncompressing the bz2 file
	func_text_done

	dd_file=(*dd)
}

func_dd_end(){					#	Add the customized to the DD file and the build folder

	if [[ $esxi_version == "4.1" ]]
		then 
			cd $install_path/${array_work_dir[5]}/
		else
			cd $install_path/${array_work_dir[1]}/usr/lib/vmware/installer
	fi
	
	dd_file=(*dd)
	
	local sector
	local number
		
	sector=$( ${array_cmd_install[11]} -u -l ${dd_file[0]} 2>/dev/null | awk -v pat=$esx_bytes '$0 ~ pat {print $9}' )			#   Checking the number of sectors
	
	if [[ -z $sector ]]
		then
			sector="512"
	fi
	number=$( ${array_cmd_install[11]} -u -l ${dd_file[0]} 2>/dev/null | awk '/dd5/ {print $2}' ) 									#	Checking where the 5th partition starts



	func_text_green "Mounting $dd_file to $install_path/${array_work_dir[4]}"
	mount -o loop,offset=$(($sector*$number)) $dd_file $install_path/${array_work_dir[4]}/								#	Mounting the 5th partition of the DD file to esx-5
	func_text_done
	
	if [[ ! -e $install_path/${array_work_dir[3]}/etc/inetd.conf ]] ; 
		then
			func_text_green "Copy inetd.conf to $install_path/${array_work_dir[3]}/etc"
			cp -r -p $install_path/inetd.conf $install_path/${array_work_dir[3]}/etc/										#	Copying the custom SSH/FTP enabled inetd.conf file
			func_text_done	
	fi
	
	if [[ -z $auto_flag ]]
		then
		
			func_add_custom_files
			
			func_edit $install_path/${array_work_dir[3]}/etc/inetd.conf
	
			if [[ $esxi_version == "4.0" || $esxi_version == "4.1" ]]
				then
					func_edit $install_path/${array_work_dir[3]}/etc/vmware/pci.ids
				else
					func_edit $install_path/${array_work_dir[3]}/usr/share/hwdata/pci.ids
			fi
			func_edit $install_path/${array_work_dir[3]}/etc/vmware/simple.map
	fi
	
	
	
	
	func_text_green "Rebuilding $install_path/${array_work_dir[5]}/oem.tgz using $install_path/${array_work_dir[3]}"
	cd $install_path/${array_work_dir[3]}
	${array_cmd_install[6]} czf $install_path/${array_work_dir[5]}/oem.tgz *													#	Rebuilding the oem.tgz file
	cd $install_path/
	func_text_done
	sleep 3

	func_text_green "Copy ${array_work_dir[5]}/oem.tgz to ${array_work_dir[4]}/oem.tgz"
	cp $install_path/${array_work_dir[5]}/oem.tgz $install_path/${array_work_dir[4]}/oem.tgz								#	Copy the custom oem file to the mounted dd file
	func_text_done

	sleep 3		# To make sure that the device isn't busy
	
	func_text_green "U mounting $install_path/${array_work_dir[4]}"
	umount $install_path/${array_work_dir[4]}																					#	U mounting the dd file
	func_text_done

	if [[ $install_inst_type != dd ]]
		then 
			if [[ $esxi_version == "4.1" ]]
				then
					cd $install_path/${array_work_dir[5]}/
					func_text_green "Bzip2 the $dd_file"
					${array_cmd_install[7]} $dd_file																			#	Compressing the dd file
					func_text_done
					dd_file=(*.bz2)
					${array_cmd_install[9]} $dd_file > ${dd_file%.bz2}.md5
					func_edit_file "$dd_file" "VMware-VMvisor-big-260247-x86_64.dd.bz2" ${dd_file%.bz2}.md5
			else
					cd $install_path/${array_work_dir[1]}/usr/lib/vmware/installer
					func_text_green "Bzip2 the $dd_file"
					${array_cmd_install[7]} $dd_file																			#	Compressing the dd file
					func_text_done
			fi
			
			if [[ $esxi_version == "3.5" ]]
				then
					func_text_green "Rebuilding install.tgz"
					cd $install_path/${array_work_dir[1]}/
					${array_cmd_install[6]} czf $install_path/${array_work_dir[5]}/install.tgz sbin/ usr/		#	Rebuilding install.tgz
					func_text_done
				else
					if [[ $esxi_version == "4.0" ]]
						then
							func_text_green "Rebuilding image.tgz"
							cd $install_path/${array_work_dir[1]}/
							${array_cmd_install[6]} czf $install_path/${array_work_dir[5]}/image.tgz usr/		#	Rebuilding install.tgz
							func_text_done
					fi
			fi

			func_set_file_rights
	fi 
}

func_iso_finish(){			#	Making the ISO file

	func_set_file_rights
	
	func_text_green "Creating $install_path/$save_dir/$esxi_finish"								#	Creating the ISO file $install_path/save/esxi_custom_oem.iso
	echo
	cd $install_path/${array_work_dir[5]}
	
	if [[ $esxi_version == "4.0" ]]
		then
			sed -i 's/install.tgz/install.tgz --- oem.tgz/g' $install_path/${array_work_dir[5]}/isolinux.cfg
		else
			if [[ $esxi_version == "4.1" ]]
				then
					sed -i 's/install.vgz/install.vgz --- oem.tgz/g' $install_path/${array_work_dir[5]}/isolinux.cfg
				
			fi
	fi	
	
	${array_cmd_install[0]} -o $install_path/$save_dir/$esxi_finish -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -input-charset utf-8 ../${array_work_dir[5]} 2>/dev/null

	clear 												#	Clear the screen.
	func_text_green " You can find the iso file at \n $install_path/$save_dir/$esxi_finish"
	echo
	echo
	sleep 3

}

func_check_usb() {			#	Gather data for the USB menu

	local usb_dev
	local usb_dev_info
	local usb_size
	local usb_name_col
	local usb_name_mfg_col
	
	
	if hash $usb_check_cmd 2>/dev/null
		then
			usb_check_cmd="udevadm"
		else
			usb_check_cmd="udevinfo"
	fi
	
	for i in /sys/block/[sh]d?
		do
			if $usb_check_cmd info -a -p "$i" | grep -qF 'usb'	#	DRIVERS=="usb-storage"																							#	Checking witch device is a USB
				then
					usb_dev_info=("${i##*/}")																																			#	Sets the device
					usb_dev=$(${array_cmd_install[11]} -l /dev/$usb_dev_info | awk '/^\/dev/ {print $1}')																						#	Checks witch partition to use / mount
					array_usb_name_list+=$($usb_check_cmd info -a -p "/sys/block/$usb_dev_info" | awk -F '[{]product[}]=="' 'NF>1{sub(/".*/,"",$2);print $2;exit}') 		#	Get's the product name of the USB
					array_usb_mfg_list+=$($usb_check_cmd info -a -p "/sys/block/$usb_dev_info" | awk -F '[{]manufacturer[}]=="' 'NF>1{sub(/".*/,"",$2);print $2;exit}') #	Get's the manufacturer name of the USB
					usb_size=$(${array_cmd_install[11]} -l "/dev/$usb_dev_info" | awk '/dev/ { print $3;exit }')																				#	The size of the USB in MB
					usb_size_name=$(${array_cmd_install[11]} -l "/dev/$usb_dev_info" | awk '/dev/ { print $4;exit }')
					array_usb_dev_list+=("$usb_dev")																																	#	Creating a array of the USB devices
					array_usb_size_list+=("$usb_size")																																	#	Creating a array of USB Size
					array_usb_size_name_list+=("$usb_size_name")																														#	Creating a array of USB Size type MB/GB
			fi
		done
	shopt -s nullglob
		if [[  "${#array_usb_name_list[*]}" != 0 ]]
			then
				usb_menu_text=("There are one or more USB drive installed")
				usb_menu_question=('Witch USB drive are you going to use ?  ')
			else
				usb_menu_text=("There is no USB drive installed")
				usb_menu_question=('Try to connect a USB drive and use update ! ')
		fi
	shopt -u nullglob
}

func_usb_menu() {				#	Menu for the USB $usb_install

	PS3=$usb_menu_question

	select usb_dev_menu
		do
			if [[ -z $usb_dev_menu ]]
				then 
					unset usb_dev_list[*]
					func_usb_use									#	Calls the menu again if the answer is incorrect
				else 
					if [[ "$usb_dev_menu" == "Exit" ]]				#	If the Select is exit
						then
							clear 									#	Clear the screen.
							echo
							func_text_green " You can find the files at \n $install_path/$save_dir/"
							echo
							echo
							echo
							func_text_red " Exiting ...."
							sleep 2
							echo
							echo
							echo
							func_clean
							echo
							echo
							exit 0
						else
							if [[ "$usb_dev_menu" == "Update" ]]
								then
									unset "array_usb_dev_list"
									unset "array_usb_name_list"
									unset "array_usb_mfg_list"
									unset "array_usb_size_list"
									unset "array_usb_size_name_list"
									func_usb_use
								else
								usb_install="$usb_dev_menu"
							fi
					fi
		
			fi
		clear 							#	Clear the screen.
		break
		done
}

func_usb_use(){					#	Witch USB drive to use menu

	clear 							#	Clear the screen.

	func_check_usb

	func_text_green "$usb_menu_text"
	echo
	for index in ${!array_usb_dev_list[@]};
		do
			printf " %s is %s - %s  %s %s" "${array_usb_dev_list["$index"]}" "${array_usb_name_list["$index"]}" "${array_usb_mfg_list["$index"]}" "${array_usb_size_list["$index"]}" "${array_usb_size_name_list["$index"]}" ;
			echo
			echo
		done
			array_usb_dev_list[9]="Update"
			array_usb_dev_list[10]="Exit"
			func_usb_menu ${array_usb_dev_list[*]}

}

func_usb_finish(){			#	To confirm that the user really like to continue with the USB installation 	$usb_install
														#	Moving the and renaming the USB installation folder
	
	local install
	
	if [[ $esxi_version == "4.0" ]]
		then
			sed -i 's/install.tgz/install.tgz --- oem.tgz/g' $install_path/${array_work_dir[5]}/isolinux.cfg
		else
			if [[ $esxi_version == "4.1" ]]
				then
					sed -i 's/install.vgz/install.vgz --- oem.tgz/g' $install_path/${array_work_dir[5]}/isolinux.cfg
				
			fi
	fi	
	
	func_kickstart											#	To add the kickstart file
	
	func_text_green "Renaming  the file isolinux.cfg to SYSlinux.cfg"
	mv $install_path/${array_work_dir[5]}/isolinux.cfg $install_path/${array_work_dir[5]}/SYSlinux.cfg			#	renaming the isolinux.cfg to SYSlinux.cfg
	func_text_done
	
	func_text_green "Removing isolinux.bin"
	rm -rf $install_path/${array_work_dir[5]}/isolinux.bin
	func_text_done
	
	func_move_files $install_path/${array_work_dir[5]}	#	Rename the build folder
	
	clear 													#	Clear the screen.
	
	if [[ -z $auto_flag ]]
		then
			func_usb_use									#	Getting the usb device to use
	fi
	
	clear 																										#	Clear the screen.
	echo
	func_text_red "Next step will be to make the USB drive bootable \n and copy the installations files to the it.\n	You need to unmount the device manually \n	Need to be fat16 or fat32 \n OBS !!! You need 700 MB free on the USB"
	echo
	func_text_red "Using $usb_install"
	echo
	func_text_red "Do you really like to continue with this ?\e[00m [y/N] "
	
	local install
	
	if [[ -z $auto_flag ]]
		then
			read install
		else
			install="Y"
	fi
	
	case $install in 

			"Y" | "y" )
			
			func_text_green "Making the USB bootable"
			${array_cmd_install[1]} $usb_install 2>/dev/null																							#	Using syslinux to make the USB bootable
			${array_cmd_install[10]} ${usb_install:0:8} set ${usb_install: -1} boot on										#	Add the boot flag to the USB 
			func_text_done

			func_text_green "Mounting the $usb_install to $install_path/${array_work_dir[6]}/ "
			mount -t auto $usb_install $install_path/${array_work_dir[6]} >/dev/null 2>&1									#	mounting the USB device
			func_text_done

			func_text_green "Copy the installation media to the mounted USB"
			cp -r $install_path/$save_dir/$esxi_finish/* $install_path/${array_work_dir[6]}/							#	Copying the files from the installation folder to the USB
			func_text_done

			sleep 3		# To make sure that the device isn't busy
			
			func_text_green "Un mounting the USB drive"
			umount $install_path/${array_work_dir[6]}/																										#	U mounting the usb drive
			func_text_done
			
			echo
			func_text_green "Now your usb ready to install from \njust plug it into the system you like to install ESXi on"
			echo
			echo
			sleep 2
		;;

			"N" | "n" | '' )																							#	If you like to move the files your self
			
			clear 																								#	Clear the screen.
			echo
			func_text_red "The files are in \n $install_path/$save_dir/$esxi_finish folder"
			echo
			sleep 3
			clear 																								#	Clear the screen.
		;;

			* )
		
			func_usb_finish
		;;

	esac

}

func_dd_finish(){				#	To confirm that the user really like to continue with the USB installation 	Moving and renaming the DD ( USB boot file)

	if [[ $esxi_version == "4.1" ]]
		then
			func_move_files $install_path/${array_work_dir[5]}/$dd_file
		else
			func_move_files $install_path/${array_work_dir[1]}/usr/lib/vmware/installer/$dd_file
	fi
	
	if [[ -z $auto_flag ]]
		then
			func_usb_use			#	Getting the usb device to use
	fi

	clear 							#	Clear the screen.
	echo
	func_text_red " Next step will be to make the USB drive bootable. \n It will write the boot image to the USB drive \n ALL files will be lost !!! \n Do not use a USB stick that is under 1GB "
	echo
	func_text_red " Using "$usb_install
	echo
	func_text_red " Do you really like to continue with this ?\e[00m [y/N] "
	
	
	local gogo
	
	if [[ -z $auto_flag ]]
		then
			read gogo
		else
			gogo="Y"
	fi

	case $gogo in

			"Y" | "y" )

			func_text_green "Writing DD image to the usb device $usb_install "
			dd bs=1M if=$install_path/$save_dir/$esxi_finish of=${usb_install%[0-9]} 2>/dev/null
			func_text_done
			sleep 2
			func_redo func_dd_finish
			echo
			func_text_green "The USB stick is now ready to plug in in your server and boot up"
			echo
			;;

			"N" | "n" | '' )																							#	If you like to move the files your self

			func_text_green " Moving the $esx_ddf file to $install_path/$save_dir "
			if [[ $esxi_version == "4.1" ]]
				then
					mv -f $install_path/${array_work_dir[5]}/$dd_file $install_path/$save_dir/$esxi_finish
				else
					mv -f $install_path/${array_work_dir[1]}/usr/lib/vmware/installer/$esx_ddf $install_path/$save_dir/$esxi_finish		#	Moving the DD file to work folder and rename it
			fi
			sleep 2
			func_text_done
			clear 							#	Clear the screen.

			echo
			func_text_red "the $esxi_finish can be found here \n $install_path/$save_dir/$esxi_finish"
			echo
			sleep 3
			clear 																							#	Clear the screen.
			;;

			* )
			
			clear
			func_dd_finish
			;;
	esac
}

func_checkRoot ./$0										#	Starts with a check that you are superuser
func_auto_loop "$@"										#	To make the script noninteracting

if [[ -z $auto_flag ]]
	then
		func_install_cmd								#	Checks if apt-get is installed 
		func_pkg_inst									#	Install the pkg's needed
		func_create_folders								#	Create folders 
		func_version									#	To check with version to use.
		func_check_iso									#	Check if you have any ISO file in the same folder as this script 
		func_main_menu
fi
func_clean												#	Deletes work folders if there is any