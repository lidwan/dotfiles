# dotfiles
## SFL steps i took to achieve encrypted dual bootArch linux and windows 11
## Install Arch first using archinstall on whole partion ( make sure to select evreything right)
## choose luks encryption on / and home, gnome as a base, NM, firefox, make user, ect.
## install timeshift and make a backup after running sudo pacman -Syyu
## install yay then go through hyprland installtion using this script: github: https://github.com/mylinuxforwork/dotfiles or run directly: bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/setup.sh) or if updated or smthn use the files in this repo (zip file)
## then (carefully) copy cofig files from this repo to ur .config folder
## install packeges from installedpkg.txt file if needed
## install rofi theme from here: https://github.com/adi1090x/rofi or from loacl copy (rofithemeloaclcp)
## setup sleep with hypridle // install it and cp configs // setup mullvad from au // ufw firewall?
## install qt6-wayland for obs to work, install grim & slurp for screenshot to work 
## don't forget that some packeges may misbehave after a linux kernal update and not rebooting so make sure to reboot (this took me 2 hours+ to remmember, i installed mullvad after updating the kernal and not rebooting... it didn't work obv).
## now download the latest gparted ios if not already on ventoy usb, in gparted unlock luks partions and resise accordinly, leave empty space no need to make partion win11 can take care of that, now install windows 11 on empty parion and when done install veracrypt and encrypt whole windows partion
## make sure to reboot freq because windows loves to fail when doing too many updates and not rebooting
## install this for audio: https://sourceforge.net/projects/equalizerapo/ or from local (win11 folder)
## win11 folder also has a couple of important programs install em. For a vpn, install hotspotshield or windscribe or 1.1.1.1 wrap just to circumvent local censorship then install <insert your current vpn provider, mullvad> 
## install the driver in win11 folder for fingerprint, if still using magicbook 14 2020.
## DONE!
# I USE ARCH BTW ;)
