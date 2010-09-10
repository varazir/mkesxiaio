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
esx-download									#8	Where I download all files needed during the script
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
"   	Using"													#2	Iso file going to be used
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
"     Extra support "								#0
" "													#1
"	1)	FTP support"								#3	If there are going to be FTP support enabled
"	2)	SFTP support"								#4	If there are going to be sFTP support enabled
"	3)	SSH support"								#5	If there are going to be SSH support enabled
"	4)	SSH + FTP support"							#6	If there are going to be FTP and SSH support enabled
"	5)	SSH + sFTP support"							#7	If there are going to be sFTP and SSH support enabled
"	6)	FTP + sFTP support"							#8	If there are going to be sFTP and FTP support enabled
"	7)	SSH + FTP + sFTP support"					#9	If there are going to be FTP and SSH support enabled
"	8)	Continue without any of them"				#10	Exit the ssh/ftp menu without doing anything
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
-v							#1	Version you are going to make
--ssh						#2	If you like to enable SSH
--sftp						#3	If you like to download and enable sftp
--ftp						#4	If you like to download and enable ftp
--wget						#5	If you like downloading wget from vm-help.com
--rsync						#6	If you like downloading rsync from vm-help.com
--iso						#7	Need to be set when runing the script non interactiv
--oem						#8	You need to set the oem file you ar egoing to use
-c							#9	If you have more files in the custom-esx directory
-d							#10	USB device 
-i							#11	Installtion typ
-h							#12	Help
)

array_auto_func=(			#	The function that is called in the func_auto_loop , it's indexed with array_auto_flag
func_auto_set_flag			#0
func_version				#1
func_add_ssh				#2
func_add_sftp				#3
func_add_ftp				#4
func_add_wget				#5
func_add_rsync				#6
func_check_iso				#7
func_check_oem				#8
func_auto_add_custom_files	#9
func_auto_usb_device		#10
func_main_menu				#11
func_help_info				#12
)

array_auto_help_text=(		#	The help text 
"		Need to be there to run the script non interactiv"
"		Version you are going to create 3.5 , 4.0 or 4.1 eg. -v=4.1 "
"		If you like to enable SSH, OBS with 4.1 you do not need to enable SSH"
"	If you like to enable SFTP, You can read more here http://thebsdbox.co.uk/?p=224"
"		If you like to enable FTP, downloaded from http://www.vm-help.com"
"	Downloading wget and rsync from vm-help.com."
"	Downloading rsync from vm-help.com."
"		The name of the iso file you are going to use -iso=vmware.iso"
"		Set the name of the oem file you like to use --oem=oem.tgz"
"		If you have more files in the custom-esx folder."
"		If you are creating a USB installtion or boot, -d=/dev/  . ONLY used with -i=USB, -i=DD"
"		Installtion typ ISO USB(install from USB) DD (Boot from USB), -i=ISO, -i=DD or -i=USB"
"		This help"
)

#	Variables 

install_path="$PWD"										#	Work path
custom_name="VMware_func_custom_"						#	The name of the custom made file/directory
save_dir="save"											#	The directory where the custom file/directories  will be  saved
custom_oem_dir="custom-esx"								#	Add files in custom-esx that is going to be in the oem.tgz file.
install_cmd="apt-get -qq -y --force-yes install"		#	The command string used to install 
usb_check_cmd="udevadm"
first_time=0

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
	func_text_green "	e.g. $0 -a -v=4.0 -e -i=ISO --ssh"
	echo
	echo
	func_clean											#	Deletes work folders if there is any
	exit
	
	

}

function func_auto_flag() {							#	To grep the flags used when running the script noninteractiv 
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

function func_auto_set_flag(){ 						#	Sets the auto flag, installs bin, creates folders

auto_flag=1

func_apt-get									#	Checks if apt-get is installed 
func_pkg_inst									#	Install the pkg's needed
func_create_folders								#	Create folders 

}

function func_add_ssh(){ 								#	Adds ssh support for 3.5 and 4.0 

if [[ "$1" != "y" ]]
	then
		local menu
		
		func_text_green "Do you like to add ssh? \e[00m [Y/n]"
		read meny
		
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

function func_add_sftp(){ 								#	Adds sftp support

func_check_dir $install_path/${array_work_dir[3]}/sbin	#	Check if there is all ready a sbin folder

func_download "http://thebsdbox.co.uk/wp-content/uploads/2010/08/sftp-server.tar.gz" "sftp-server.tar.gz" $install_path/ $1

${array_pkg_install[6]} -xzf $install_path/sftp-server.tar.gz -C $install_path/${array_work_dir[3]}/sbin

}

function func_add_ftp(){ 								#	Adds FTP suuport

	func_check_dir $install_path/${array_work_dir[3]}/sbin	#	Check if there is all ready a sbin folder
	func_check_dir $install_path/${array_work_dir[3]}/etc		#	Check if there is all ready a etc folder

	func_text_green "Downloading ProFtpd to $install_path/${array_work_dir[7]}"
	func_download http://www.vm-help.com/esx/esx3i/ftp/proftpd.zip proftpd.zip $install_path/${array_work_dir[7]} $1
	
	cd $install_path/${array_work_dir[7]}
	
	${array_pkg_install[3]} -qq proftpd.zip 2>>/dev/null
	func_text_done
	
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
			func_edit_file "^#ftp" "ftp" $install_path/$1/etc/inetd.conf
			func_edit_file "in.ftpd" "proftpd" $install_path/$1/etc/inetd.conf 
		else
			echo "ftp    stream  tcp     nowait  root    /usr/sbin/tcpd  proftpd" >> $install_path/$1/etc/inetd.conf
			echo "" >> $install_path/$1/etc/inetd.conf

	fi
	if [[ -z $auto_flag ]]
		then
			func_edit $install_path/$1/etc/proftpd.conf
	fi
	
	custom_name=${custom_name}ftp_

}

function func_add_wget(){ 								#	Downloads wget from vm-help.com

echo "wget"

}

function func_add_rsync(){ 							#	Downloads rsync from vm-help.com 

echo "rsync"

}

function func_auto_add_custom_files(){ 

echo "custom"

}

function func_auto_usb_device(){ 

echo $1

}

function func_auto_install_type(){ 

echo $1

}

function func_apt-get(){								#	Check if apt-get is there and if not asks for a new install bin

local ibin

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
		func_text_red "\n	Standard command is $install_cmd, \n	apt-get can't be found on your system \n	Please specify the install command for your system\n"
		func_text_green "	Type whole command similar to the command above \n	"
		read ibin
		install_cmd="$ibin" 
fi
}

function func_pkg_inst(){								#	Loop to find binaries and installed them if need be

local pkgbin

for pkgbin in ${array_pkg_install[*]}
do	
	if hash $pkgbin 2>>/dev/null
		then 
			func_text_green "	$pkgbin is already installed"
			echo
			sleep 2
		else
			$install_cmd $pkgbin 2>>/dev/null
			if [ ! $? -eq 0 ]
				then
					echo
					func_text_red "	Script encountered an error during package installation.  \n	Check errors and retry"
					echo
					exit 0
			fi
			func_text_green "	$pkgbin is now installed"
			echo
			sleep 2
	fi
done
sleep 2
clear
}

function func_check() {								#	Checking for files $file_to_use
	
	cd $install_path
	shopt -s nullglob
	local array_check_files=($2)							#	Creating a array if there is more then one file
		
		if [[ ${#array_check_files[@]} == 0 ]]
			then
				clear 										#	Clear the screen.
				echo
				func_text_red "	No $1 file..  Exiting"
				echo
				sleep 5
				clear 										#	Clear the screen.
				func_clean
				exit 0
		fi
	shopt -u nullglob
	
	if [ "${#array_check_files[@]}" -gt 1 ]					#	If there is more then one file
		then
			array_check_files[100]="Exit"
			func_check_menu ${array_check_files[@]:0}
		else
			file_to_use="${array_check_files[*]}"
	fi
}

function func_check_menu() {							#	Checking for files menu
	
	local check_files
	
	clear 							#	Clear the screen.
	
	PS3='With file are you going to use ?  '

	func_text_green "There are more then one ${array_check[0]} file"
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

function func_check_iso() {							#	Check if there is more then one iso file and sets the file to be used as $esx_iso_file 
	
	local array_check
	
	if [[ -z $auto_flag ]]
		then	
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

function func_check_oem() {							#	Check if there is more then one oem $esx_oem_file 
	
	local array_check
	
	if [[ -z $auto_flag ]]
			then	
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
	
	
	
	
}

function func_check_inetd() {							#	Check if there is a inetd file $esx_inetd_file
	
	if [[ "$esxi_version" == "4.1" ]]
		then
			func_download "http://mkesxiaio.googlecode.com/svn/new/inetd.conf" "inetd.conf" "$install_path/" "y"
		else
			func_download "http://mkesxiaio.googlecode.com/svn/trunk/inetd.conf" "inetd.conf" "$install_path/" "y"
	fi
	
	local array_check
	
	array_check=(inetd.conf "*inetd*")
	func_check "${array_check[@]:0}"
	esxi_inetd_file="$file_to_use"
}

function func_download() {								#	Used to download files, URL, file , dest , Auto 

cd $install_path/${array_work_dir[8]}

	local download
	
	if [[ "$auto_flag" || "$4" == "y" ]]
		then
			${array_pkg_install[2]} -q $1 2>>/dev/null
			mv $2 $3
		else
			func_text_green "Do you like to download $2 ? \e[00m [Y/n] "
			read download
	fi
	
	case $download in
		
		"Y" | "y" )
		${array_pkg_install[2]} -q $1 2>>/dev/null
		mv $2 $3
		;;
		
		"N" | "n" )
		#			func_text_green "Continue without downloading the file $1"
		;;
		
		*)
		${array_pkg_install[2]} -q $1 2>>/dev/null
		mv $2 $3
		;;
	esac

	
}

function func_version(){								#	Version ?

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
					func_text_green "\n	[$count] %s" "${array_version[index]}";
				done
				echo
			func_text_green "	Select:"
			read menu
		else
			menu=$1
	fi
			
	if [[ -z $menu ]]
		then 
			func_text_red "You need to define the version of ESXi you like to create "
			sleep 4
			clear
			exit
	fi

	case "$menu" in
		2 | 4.0 ) 
			esxi_version="4.0"
			clear
		;;
		1 | 3.5 )
			esxi_version="3.5"
			clear
		;;
		3 | 4.1 )
			esxi_version="4.1"
			clear
		;;
		* )
			func_text_red "That's not a valid option"
			sleep 1
			clear 					#	Clear the screen.
			func_version			#	Loop the menu
		;;
	esac
	
	func_check_inetd									#	Check and download the correct inetd.conf file
	
}

function func_main_menu(){ 							#	Main menu function 
	
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
					func_text_green "	%s\n" "${array_main_menu[index]}";	#	Creates the main menu 
				done
			func_text_green " Choose what you like to do: "
			read menu
		else
			if [[ -z $1 ]]													#	If you are using the auto function and haven't set -i it till stop the script
				then
					func_text_red "You have to set type of installtion -i=ISO ..."
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
			func_check_oem $esxi_oem_file		#	Check witch OEM file to use, if the script run in non interactiv $esxi_oem_file allready set
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
			func_copy_cd
			func_add_service y
			func_file_name
			func_check_old
			func_dd_start
			func_dd_end
			func_usb_finish 		#	Moving/rename the esx-build folder to the save folder and copy the files to the USB drive
			func_clean
		;;

		3 | DD | dd )
			inatall_type="dd"		#	Setting the installation type to DD
			func_check_oem  $esxi_oem_file
			func_copy_cd
			func_add_service y
			func_file_name
			func_check_old
			func_dd_start
			func_dd_end
			func_dd_finish			#	Rename dd file, move it to the save folder and write it to the USB drive
			func_clean
		;;

		4)	#	USB installation without changes
		
			install_type="usb"	#	Setting the installation type to fold
			custom_name="$esxi_iso_file"
			func_copy_cd
			func_file_name
			func_check_old
			func_usb_finish
			func_clean
		;;
		
		5)	#	Boot from USB without changes
		
			install_type="dd"		#	Setting the installation type to DD
			esxi_custom="$esxi_iso_file"
			func_copy_cd
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

function func_checkRoot() {							#	To check if the script is run as a superuser
    if [ ! $( id -u ) -eq 0 ]
		then
			sudo $0
	fi
}

function func_clean(){									#	Cleans up after the script 

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

	if [[ -u "$custom_name" ]]
		then
			chown --from=$USER $SUDO_UID:$SUDO_GID $install_path/*
	fi
}

function func_create_folders() {						#	Create folders

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
			if [[ -n "$install_type" ]] 
				then
					set_file_rights
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

function func_check_dir() {							#	Checks the dir given 
	
	if [ ! -d $1	]; then							#	Check if there is all ready a folder
		func_text_green "Creating $1"
		mkdir -p $1									#	Creates the folder
		func_text_done
		sleep 2
	fi
}

function func_add_service(){

	local loop=$1

	if [[ -z $auto_flag ]]
		then
			
			local menu

			func_text_green "Do you like to install All[Y] (wget, rsync, ftp, sftp and ssh) or seperate[n] ? \e[00m [Y/n]"
			read menu
			
			case $menu in
				
				"Y" | "y" | "" )
				func_add_ssh
				func_add_wget $1
				func_add_rsync $1
				func_add_sftp $1
				func_add_ftp $1
				;;
				
				"N" | "n" )
				func_add_ssh 
				func_add_wget 
				func_add_rsync 
				func_add_sftp 
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

function func_edit_file() {							#	Change a files 
	
	func_text_green "Replacing $1 with $2 in $3"
	${array_pkg_install[4]} -s $3 <<< ",s/$1/$2/g"$'\nw'
	func_text_done
	sleep 1
}

func_checkRoot ./$0										#	Starts with a check that you are superuser
func_clean
func_auto_loop "$@"										#	To make the script nonintractiv

if [[ -z $auto_flag ]]
	then
		func_apt-get									#	Checks if apt-get is installed 
		func_pkg_inst									#	Install the pkg's needed
		func_create_folders								#	Create folders 
fi

func_version											#	To check with version to use.
func_check_iso											#	Check if you have any ISO file in the same folder as this script 
func_main_menu
func_clean												#	Deletes work folders if there is any