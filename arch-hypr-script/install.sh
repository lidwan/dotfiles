#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# Determine the absolute path of the directory where the script resides
# This allows robust access to accompanying files (allPackages.txt, etc.)
# regardless of where the script is called from or if cd is used internally.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Function to install yay if it's not already installed
install_yay() {
    echo -e "${CYAN}Before proceeding, we'll need to install 'yay', if it's not already installed.${NC}"
    echo -e "${CYAN}Do you want to install yay and proceed with the setup? (y/n)${NC}"
    read -r install_yay_choice # Renamed variable to avoid conflict

    # Default to 'y' if input is empty
    if [ -z "$install_yay_choice" ]; then
        install_yay_choice="y"
    fi

    if [[ "$install_yay_choice" != "y" ]]; then
        echo -e "${YELLOW}You chose not to install yay. Exiting setup...${NC}"
        exit 0
    fi

    echo -e "${YELLOW}Updating system before potentially installing yay...${NC}"
    # Ensure base-devel is installed for makepkg
    sudo pacman -S --needed --noconfirm base-devel git || { echo -e "${RED}Failed to install base-devel/git. Exiting.${NC}"; exit 1; }
    sudo pacman -Syu --noconfirm || { echo -e "${RED}Failed to update system. Exiting.${NC}"; exit 1; }

    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}Installing yay...${NC}"
        # Use a temporary directory for cloning and building
        TMP_DIR=$(mktemp -d)
        if [ ! -d "$TMP_DIR" ]; then
            echo -e "${RED}Failed to create temporary directory. Exiting.${NC}"
            exit 1
        fi
        # Store current directory to return to, though cd ~ is used later
        # This is more of a fallback if other cd commands fail before cd ~
        ORIGINAL_DIR=$(pwd)
        git clone https://aur.archlinux.org/yay.git "$TMP_DIR" || { echo -e "${RED}Failed to clone yay repository. Exiting.${NC}"; rm -rf "$TMP_DIR"; cd "$ORIGINAL_DIR" || exit 1; exit 1; }
        cd "$TMP_DIR" || { echo -e "${RED}Failed to enter yay directory. Exiting.${NC}"; rm -rf "$TMP_DIR"; cd "$ORIGINAL_DIR" || exit 1; exit 1; }
        makepkg -si --noconfirm || { echo -e "${RED}Failed to build and install yay. Exiting.${NC}"; cd ~; rm -rf "$TMP_DIR"; exit 1; } # Go to home on failure before exit
        cd ~ # Go back to home directory before removing temp dir
        rm -rf "$TMP_DIR" || { echo -e "${RED}Failed to clean up temporary yay directory. Proceeding without cleanup.${NC}"; }
        echo -e "${GREEN}yay successfully installed.${NC}"
    else
        echo -e "${GREEN}yay is already installed.${NC}"
    fi
}

# Function to install AUR packages
install_aur_packages() {
    echo -e "${CYAN}Do you want to install AUR packages from allPackages.txt? (y/n)${NC}"
    read -r install_aur

    if [ -z "$install_aur" ]; then
        install_aur="y"
    fi

    if [[ "$install_aur" == "y" ]]; then
        if ! command -v yay &> /dev/null; then
            echo -e "${RED}yay command not found. Cannot install AUR packages. Please ensure yay was installed.${NC}"
            return 1
        fi

        echo -e "${YELLOW}Updating system databases via yay...${NC}"
        yay -Sy || { echo -e "${RED}Failed to update databases via yay. Exiting.${NC}"; exit 1; }

        # Define the path to allPackages.txt relative to the script's location
        local aur_packages_file="$SCRIPT_DIR/allPackages.txt"

        if [ -f "$aur_packages_file" ]; then
            echo -e "${YELLOW}Processing AUR packages from $aur_packages_file...${NC}"
            while IFS= read -r aur_package || [[ -n "$aur_package" ]]; do
                [[ -z "$aur_package" || "$aur_package" =~ ^# ]] && continue

                if ! yay -Qi "$aur_package" &> /dev/null; then
                    echo -e "${YELLOW}Installing $aur_package from AUR...${NC}"
                    yay -S --noconfirm "$aur_package" || { echo -e "${RED}Failed to install $aur_package. Continuing with next package.${NC}"; }
                else
                    echo -e "${GREEN}$aur_package is already installed.${NC}"
                fi
            done < "$aur_packages_file"
        else
            echo -e "${RED}$aur_packages_file not found. Skipping AUR packages installation.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping AUR packages installation.${NC}"
    fi
}

# Function to install Flatpaks
install_flatpaks() {
    echo -e "${CYAN}Do you want to install Flatpak applications from flatpaksFSR.txt? (y/n)${NC}"
    read -r install_flatpak

    if [ -z "$install_flatpak" ]; then
        install_flatpak="y"
    fi

    if [[ "$install_flatpak" == "y" ]]; then
        if ! command -v flatpak &> /dev/null; then
            echo -e "${YELLOW}Installing Flatpak...${NC}"
            sudo pacman -S --noconfirm --needed flatpak || { echo -e "${RED}Failed to install Flatpak. Skipping Flatpak setup.${NC}"; return 1; }
        else
            echo -e "${GREEN}Flatpak is already installed.${NC}"
        fi

        if ! flatpak remote-list | grep -q flathub; then
            echo -e "${YELLOW}Adding Flathub repository...${NC}"
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || { echo -e "${RED}Failed to add Flathub repository. Skipping Flatpak installation.${NC}"; return 1; }
        else
            echo -e "${GREEN}Flathub repository is already added.${NC}"
        fi

        # Define the path to flatpaksFSR.txt relative to the script's location
        local flatpaks_file="$SCRIPT_DIR/flatpaksFSR.txt"

        if [ -f "$flatpaks_file" ]; then
            echo -e "${YELLOW}Installing Flatpak applications from $flatpaks_file...${NC}"
            while IFS= read -r flatpak_package || [[ -n "$flatpak_package" ]]; do
                [[ -z "$flatpak_package" || "$flatpak_package" =~ ^# ]] && continue

                echo -e "${YELLOW}Installing $flatpak_package...${NC}"
                flatpak install -y flathub "$flatpak_package" || { echo -e "${RED}Failed to install $flatpak_package. Continuing with next Flatpak.${NC}"; }
            done < "$flatpaks_file"
        else
            echo -e "${RED}$flatpaks_file not found. Skipping Flatpak installation.${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping Flatpak installation.${NC}"
    fi
}

# Function to apply config files
apply_config_files() {
    echo -e "${CYAN}Do you want to apply config files (backup ~/.config, copy new .config and .bashrc)? (y/n)${NC}"
    read -r apply_config

    if [ -z "$apply_config" ]; then
        apply_config="y"
    fi

    if [[ "$apply_config" == "y" ]]; then
        # Paths to source config files/directories, relative to the SCRIPT_DIR
        # Assumes .config is one level up from script dir, and .bashrc is in script dir
        local config_source_path="$SCRIPT_DIR/../.config"
        local bashrc_source_path="$SCRIPT_DIR/.bashrc" # Assumes .bashrc is in the same directory as the script

        # --- Apply .config ---
        if [ ! -d "$config_source_path" ]; then
            echo -e "${RED}Source configuration directory '$config_source_path' not found. Skipping .config copy.${NC}"
        else
            local timestamp=$(date +%Y%m%d_%H%M%S)
            local backup_dir_config="$HOME/.config.backup_$timestamp"

            if [ -d "$HOME/.config" ]; then
                echo -e "${YELLOW}Backing up current configuration files from ~/.config to $backup_dir_config...${NC}"
                cp -a "$HOME/.config" "$backup_dir_config" || { echo -e "${RED}Failed to back up ~/.config. Aborting .config application.${NC}"; return 1; }
            else
                echo -e "${YELLOW}No existing ~/.config directory found. Skipping backup.${NC}"
            fi

            echo -e "${YELLOW}Copying new configuration files from $config_source_path to ~/.config/...${NC}"
            mkdir -p "$HOME/.config"
            # Copy contents of source into target. The trailing slash on source is important for cp -a.
            cp -ar "$config_source_path/." "$HOME/.config/" || { echo -e "${RED}Failed to copy configuration files from $config_source_path. Check permissions and paths.${NC}"; return 1; }
            echo -e "${GREEN}.config files applied successfully.${NC}"
        fi

        # --- Apply .bashrc ---
        if [ ! -f "$bashrc_source_path" ]; then
            echo -e "${RED}Source file '$bashrc_source_path' not found. Skipping .bashrc copy.${NC}"
        else
            local timestamp=$(date +%Y%m%d_%H%M%S) # Re-use or re-generate timestamp if needed for .bashrc
            local backup_file_bashrc="$HOME/.bashrc.backup_$timestamp"

            if [ -f "$HOME/.bashrc" ]; then
                echo -e "${YELLOW}Backing up existing ~/.bashrc to $backup_file_bashrc...${NC}"
                cp -a "$HOME/.bashrc" "$backup_file_bashrc" || { echo -e "${RED}Failed to back up .bashrc. Aborting .bashrc copy.${NC}"; return 1; }
            fi
            echo -e "${YELLOW}Copying new .bashrc from $bashrc_source_path to ~/.bashrc...${NC}"
            cp "$bashrc_source_path" "$HOME/.bashrc" || { echo -e "${RED}Failed to copy .bashrc from $bashrc_source_path. Check permissions.${NC}"; return 1; }
            echo -e "${GREEN}.bashrc applied successfully.${NC}"
        fi

    else
        echo -e "${YELLOW}Skipping configuration files application.${NC}"
    fi
}

# Function to apply GTK theme using gsettings
apply_gnome_theme() {
    echo -e "${CYAN}Do you want to set the GTK theme to 'Arc-Dark'? (Requires the theme to be installed) (y/n)${NC}"
    read -r apply_theme

    if [ -z "$apply_theme" ]; then
        apply_theme="y"
    fi

    if [[ "$apply_theme" == "y" ]]; then
        if ! command -v gsettings &> /dev/null; then
            echo -e "${RED}'gsettings' command not found. Cannot set theme. Is 'glib2' installed? Skipping.${NC}"
            if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
                echo -e "${YELLOW}Note: You might need to run this script from within a graphical session for gsettings to work.${NC}"
            fi
            return 1
        fi

        echo -e "${YELLOW}Applying 'Arc-Dark' GTK theme via gsettings...${NC}"
        gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}GTK theme set to 'Arc-Dark' successfully.${NC}"
        else
            echo -e "${RED}Failed to set GTK theme using gsettings.${NC}"
            echo -e "${YELLOW}Ensure the 'Arc-Dark' theme (e.g., package 'arc-gtk-theme') is installed.${NC}"
            echo -e "${YELLOW}Also ensure you are running this within a graphical user session (not just TTY).${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping GTK theme setting.${NC}"
    fi
}


# --- Main Execution ---

# Install yay
install_yay || exit 1 # Exit if yay install fails critically

# Install AUR packages (like themes, apps)
install_aur_packages

# Install Flatpaks
install_flatpaks

# Apply configuration files (.config, .bashrc)
apply_config_files

# Apply GNOME GTK theme
apply_gnome_theme

echo -e "${GREEN}Setup complete!${NC}"

