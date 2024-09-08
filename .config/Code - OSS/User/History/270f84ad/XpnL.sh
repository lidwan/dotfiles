#!/bin/bash

# Step 2: Update the system and install official Arch packages
sudo yay -Syu --noconfirm


# Step 5: backing up existing configuration files
cp -r ~/.config ~/.config.backup

# Step 6: Copy configuration files
echo "Copying configuration files..."
cp -r ../.config/hypr ~/.config/
cp -r ../.config/alacritty ~/.config/
cp -r ../.config/ml4w ~/.config/
cp -r ../.config/ml4w-hyprland-settings ~/.config/
cp -r ../.config/rofi ~/.config/
cp -r ../.config/rofi-lidwan ~/.config/
cp -r ../.config/systemd ~/.config/
cp -r ../.config/waybar ~/.config/

cp ../.config/mimeapps.list ~/.config/
cp ../.config/pavucontrol.ini ~/.config/
cp ../.config/QtProject.conf ~/.config/
cp ../.config/rygel.conf ~/.config/
cp ../.config/user-dirs.dirs ~/.config/
cp ../.config/user-dirs.locale ~/.config/
cp ../.config/.gsd-keyboard.settings-ported ~/.config/

sudo cp -r ../etc-systemd-system/system /etc/systemd
systemctl --user daemon-reload


sudo cp .bashrc ~/.bashrc


echo "Setup complete!"
