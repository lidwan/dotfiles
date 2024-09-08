#!/bin/bash

# Function to install yay if it's not already installed
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Installing yay..."
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        echo "yay is already installed."
    fi
}

#Install yay
install_yay

#Update the system and install official Arch packages
sudo yay -Syu --noconfirm

#Install AUR packages using yay
while read -r aur_package; do
    if ! yay -Qi $aur_package > /dev/null; then
        echo "Installing $aur_package from AUR..."
        yay -S --noconfirm $aur_package
    else
        echo "$aur_package is already installed."
    fi
done < allPackages.txt


#backing up existing configuration files
cp -r ~/.config ~/.config.backup

#Copy configuration files
echo "Copying configuration files..."
cp -r ../.config/hypr ~/.config/
cp -r ../.config/alacritty ~/.config/
cp -r ../.config/ml4w ~/.config/
cp -r ../.config/ml4w-hyprland-settings ~/.config/
cp -r ../.config/rofi ~/.config/
cp -r ../.config/rofi.lidwan ~/.config/
cp -r ../.config/systemd ~/.config/
cp -r ../.config/waybar ~/.config/

cp ../.config/mimeapps.list ~/.config/
cp ../.config/pavucontrol.ini ~/.config/
cp ../.config/QtProject.conf ~/.config/
cp ../.config/rygel.conf ~/.config/
cp ../.config/user-dirs.dirs ~/.config/
cp ../.config/user-dirs.locale ~/.config/
cp ../.config/.gsd-keyboard.settings-ported ~/.config/


sudo cp .bashrc ~/.bashrc


echo "Setup complete!"
