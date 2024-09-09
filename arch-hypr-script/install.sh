#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# Function to install yay if it's not already installed
install_yay() {
    sudo pacman -Syu --noconfirm

    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}Installing yay...${NC}"
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        echo -e "${GREEN}yay is already installed.${NC}"
    fi
}

# Function to install AUR packages
install_aur_packages() {
    echo -e "${CYAN}Do you want to install AUR packages? (y/n)${NC}"
    read -r install_aur

    if [ -z "$install_aur" ]; then 
        install_aur="y"
    fi

    if [[ "$install_aur" == "y" ]]; then
        echo -e "${YELLOW}Updating system and installing AUR packages...${NC}"
        sudo yay -Sy

        if [ -f "allPackages.txt" ]; then
            while read -r aur_package; do
                if ! yay -Qi "$aur_package" > /dev/null; then
                    echo -e "${YELLOW}Installing $aur_package from AUR...${NC}"
                    yay -S --noconfirm "$aur_package"
                else
                    echo -e "${GREEN}$aur_package is already installed.${NC}"
                fi
            done < allPackages.txt
        else
            echo -e "${RED}allPackages.txt not found. Skipping AUR packages installation.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping AUR packages installation.${NC}"
    fi
}

# Function to install Flatpaks
install_flatpaks() {
    echo -e "${CYAN}Do you want to install Flatpak applications? (y/n)${NC}"
    read -r install_flatpak

    if [ -z "$install_flatpak" ]; then 
        install_flatpak="y"
    fi

    if [[ "$install_flatpak" == "y" ]]; then
        if ! command -v flatpak &> /dev/null; then
            echo -e "${YELLOW}Installing Flatpak...${NC}"
            sudo pacman -S --noconfirm flatpak
        else
            echo -e "${GREEN}Flatpak is already installed.${NC}"
        fi

        if ! flatpak remotes | grep -q flathub; then
            echo -e "${YELLOW}Adding Flathub repository...${NC}"
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            echo -e "${GREEN}Flathub repository is already added.${NC}"
        fi

        if [ -f "flatpaksFSR.txt" ]; then
            echo -e "${YELLOW}Installing Flatpak applications from flatpaksFSR.txt...${NC}"
            while IFS= read -r flatpak_package; do
                flatpak install -y flathub "$flatpak_package"
            done < flatpaksFSR.txt
        else
            echo -e "${RED}flatpaksFSR.txt not found. Skipping Flatpak installation.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping Flatpak installation.${NC}"
    fi
}

# Function to apply config files
apply_config_files() {
    echo -e "${CYAN}Do you want to apply config files? (y/n)${NC}"
    read -r apply_config

    if [ -z "$apply_config" ]; then 
        apply_config="y"
    fi

    if [[ "$apply_config" == "y" ]]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="$HOME/.config.backup_$TIMESTAMP"

        echo -e "${YELLOW}Backing up current configuration files to $BACKUP_DIR...${NC}"
        cp -r ~/.config "$BACKUP_DIR"

        echo -e "${YELLOW}Copying new configuration files...${NC}"
        cp -r ../.config/* ~/.config/

        sudo cp .bashrc ~/.bashrc
        echo -e "${GREEN}Configuration files applied successfully.${NC}"
    else
        echo -e "${YELLOW}Skipping configuration files.${NC}"
    fi
}

# Install yay
install_yay

# Install AUR packages
install_aur_packages

# Install Flatpaks
install_flatpaks

# Apply configuration files
apply_config_files

echo -e "${GREEN}Setup complete!${NC}"
