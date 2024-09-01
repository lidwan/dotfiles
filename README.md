# dotfiles
## SFL steps i took to achieve encrypted dual bootArch linux and windows 11
## Install Arch first using archinstall on whole partion ( make sure to select evreything right)
## choose luks encryption on / and home, gnome as a base, NM, firefox, make user, ect.
## install timeshift and make a backup after running sudo pacman -Syyu
## install yay then go through hyprland installtion using this script: github: https://github.com/mylinuxforwork/dotfiles or run directly: bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/setup.sh) or if updated or smthn use the files in this repo (zip file)
## then (carefully) copy cofig files from this repo to ur .config folder
## install packeges from installedpkg.txt file if needed
## install rofi theme from here: https://github.com/adi1090x/rofi or from loacl copy (rofithemeloaclcp)
## setup sleep with hypridle // install it and cp configs // setup mullvad from aur // ufw firewall?
## install qt6-wayland for obs to work, install grim & slurp for screenshot to work 
## don't forget that some packeges may misbehave after a linux kernal update and not rebooting so make sure to reboot (this took me 2 hours+ to remmember, i installed mullvad after updating the kernal and not rebooting... it didn't work obv).
## now download the latest gparted ios if not already on ventoy usb, in gparted unlock luks partions and resise accordinly, leave empty space no need to make partion win11 can take care of that, now install windows 11 on empty parion and when done install veracrypt and encrypt whole windows partion
## make sure to reboot freq because windows loves to fail when doing too many updates and not rebooting
## install this for audio: https://sourceforge.net/projects/equalizerapo/ or from local (win11 folder)
## win11 folder also has a couple of important programs install em. For a vpn, install hotspotshield or windscribe or 1.1.1.1 wrap just to circumvent local censorship then install <insert your current vpn provider, mullvad> 
## install the driver in win11 folder for fingerprint, if still using magicbook 14 2020.
## Now that windows is up and running lets fix Grub so we can boot back into arch, also let's install a grub theme.
## boot from a live arch iso, run "sudo cryptsetup luksOpen <ROOT PARTION> cryptroot" to unlock the root partion then mount it with "sudo mount /dev/mapper/cryptroot /mnt", do the same with the boot partion (change "cryptroot" to cryptroot2 or whatever), chroot onto ur arch system with "sudo chroot /mnt", run this "grub-install <NnvmeDriveName>" then run "grub-mkconfig -o /boot/grub/grub.cfg" exit unmount and reboot.
## when you turn on your laptop it should go into grub but it won't have win11 as an option so you have to edit the config to turn on os-prober, install it "yay -S os-prober" then edit the config file at "/etc/default/grub" and uncomment the os-prober thingy then update grub with "grub-mkconfig -o /boot/grub/grub.cfg"  and boom grub should work just fine. Note that if you want to change the name an option install grub-customizer in gnome env and edit it there.
## get grub theme from here: https://github.com/vinceliuice/grub2-themes orrr download the theme and config file for grub from this repo. dont forget "grub-mkconfig -o /boot/grub/grub.cfg" to regen. grub
## install ly as your dm becuase y not :), run "yay -S ly, sudo systemctl disable gdm (or insert curr dm name here), sudo systemctl enable ly" then reboot.
## DONE!
# Auto Install Script:
# arch-hypr-script
# A script to get my arch linux hyprland setup up and running quickly 
## (including grub theme, firefox extention configs) TB done manualy upon completion.
## the script  will install yay then install all the pkgs in pkg.txt then backup .config and cp config files and cp .bashrc too
## pkg list & config files to be updated often - run "yay -Qq > pkgs.txt"
## manu sudo cp systemd files for update timer and stuff to work
## grub theme, firefox extention configs TB done manualy upon completion.
# I USE ARCH BTW ;)
