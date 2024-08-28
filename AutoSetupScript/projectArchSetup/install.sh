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

# Step 1: Install yay
install_yay

# Step 2: Update the system and install official Arch packages
sudo pacman -Syu --noconfirm

# Step 3: Install packages from the official repositories
while read -r package; do
    if ! pacman -Qi $package > /dev/null; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm $package
    else
        echo "$package is already installed."
    fi
done < packages.txt

# Step 4: Install AUR packages using yay
while read -r aur_package; do
    if ! yay -Qi $aur_package > /dev/null; then
        echo "Installing $aur_package from AUR..."
        yay -S --noconfirm $aur_package
    else
        echo "$aur_package is already installed."
    fi
done < aur-packages.txt

# Step 5: backing up existing configuration files
cp -r ~/.config ~/.config.backup

# Step 6: Copy configuration files
echo "Copying configuration files..."
cp -r dotfiles/.config/* ~/.config/
systemctl --user daemon-reload

# Step 7: Copy .bashrc file
if [ -f dotfiles/.bashrc ]; then
    cp dotfiles/.bashrc ~/.bashrc
    echo ".bashrc copied to home directory."
else
    echo ".bashrc not found in dotfiles."
fi

echo "Setup complete!"
