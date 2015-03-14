As you maybe seen I haven't updated my script for some time.
I haven't looked into adding ESXi5

There is a windows based script that you can find at
http://www.vm-help.com/forum/viewtopic.php?f=24&t=3272

and
http://esxi-customizer.v-front.de/

###Continued linux script###
https://code.google.com/p/esxbuilder/


To all VMware-VMvisor-Installer-4.1.0.update1-348481.x86\_64.iso this is the latest version of the file supported in the script. Make sure to download it from vmware.com


Looks like there is a bug in syslinux 4.x that could be a problem, working on a workaround. Solution is to downgrade to 3.x but I haven't got around to change the script

Update 4.3.1 another bug fixes more of a ops from my part

If you like to manually download them you can find them
http://mkesxiaio.googlecode.com/svn/new/inetd.conf  (4.1 file )
http://mkesxiaio.googlecode.com/svn/trunk/inetd.conf (4.0/3.5 file )
There is no way to go around not having internet when you have this version of the script

A bash script to create a custom installation image for ESXi 3.5/4.0/4.1

The script is tested on a live Ubunu and CentOS CD.








Make ESXi all in one.

More info can be found in the How-To ( see the right side info )

Like to contact me post on the above forum or email at my gmail address varazir