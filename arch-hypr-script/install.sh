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

# Function to install AUR packages
install_aur_packages() {
    echo "Do you want to install AUR packages? (y/n)"
    read -r install_aur

    if [ -z "$install_aur" ]; then 
            install_aur="y"
    fi

    if [[ "$install_aur" == "y" ]]; then
        # Update system and install official Arch packages
        sudo yay -Syu --noconfirm
        
        # Install AUR packages
        while read -r aur_package; do
            if ! yay -Qi "$aur_package" > /dev/null; then
                echo "Installing $aur_package from AUR..."
                yay -S --noconfirm "$aur_package"
            else
                echo "$aur_package is already installed."
            fi
        done < allPackages.txt
    else
        echo "Skipping AUR packages installation."
    fi
}

# Function to install Flatpaks
install_flatpaks() {
    echo "Do you want to install Flatpak applications? (y/n)"
    read -r install_flatpak

    if [ -z "$install_flatpak" ]; then 
            install_flatpak="y"
    fi

    if [[ "$install_flatpak" == "y" ]]; then
        # Install Flatpak if not installed
        if ! command -v flatpak &> /dev/null; then
            echo "Flatpak not found, installing..."
            sudo pacman -S --noconfirm flatpak
        else
            echo "Flatpak is already installed"
        fi

        # Add Flathub repository if not added
        if ! flatpak remotes | grep -q flathub; then
            echo "Adding Flathub repository..."
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            echo "Flathub repository already added"
        fi

        # Install Flatpak applications from flatpaksFSR.txt
        if [ -f "flatpaksFSR.txt" ]; then
            echo "Installing Flatpak applications from flatpaksFSR.txt..."
            while IFS= read -r flatpak_package; do
                flatpak install -y flathub "$flatpak_package"
            done < flatpaksFSR.txt
        else
            echo "flatpaksFSR.txt not found. Skipping Flatpak installation."
        fi
    else
        echo "Skipping Flatpak installation."
    fi
}

# Function to apply config files
apply_config_files() {
    echo "Do you want to apply config files? (y/n)"
    read -r apply_config

    if [ -z "$apply_config" ]; then 
            apply_config="y"
    fi

    if [[ "$apply_config" == "y" ]]; then
        echo "Backing up old configuration files..."

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

    else
        echo "Skipping configuration files."
    fi
}

#Install yay
install_yay

# Install AUR packages
install_aur_packages

# Install Flatpaks
install_flatpaks

# Apply configuration files
apply_config_files

echo "Setup complete!"
