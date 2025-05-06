#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# Function to install yay if it's not already installed
install_yay() {
    echo -e "${CYAN}Before proceeding, we'll need to install 'yay', if it's not already installed.${NC}"
    echo -e "${CYAN}Do you want to install yay and proceed with the setup? (y/n)${NC}"
    read -r install_yay

    # Default to 'y' if input is empty
    if [ -z "$install_yay" ]; then
        install_yay="y"
    fi

    if [[ "$install_yay" != "y" ]]; then
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
        git clone https://aur.archlinux.org/yay.git "$TMP_DIR" || { echo -e "${RED}Failed to clone yay repository. Exiting.${NC}"; rm -rf "$TMP_DIR"; exit 1; }
        cd "$TMP_DIR" || { echo -e "${RED}Failed to enter yay directory. Exiting.${NC}"; rm -rf "$TMP_DIR"; exit 1; }
        makepkg -si --noconfirm || { echo -e "${RED}Failed to build and install yay. Exiting.${NC}"; cd ~; rm -rf "$TMP_DIR"; exit 1; }
        cd ~ # Go back to home directory before removing
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

    # Default to 'y' if input is empty
    if [ -z "$install_aur" ]; then
        install_aur="y"
    fi

    if [[ "$install_aur" == "y" ]]; then
        if ! command -v yay &> /dev/null; then
             echo -e "${RED}yay command not found. Cannot install AUR packages. Please run the script again and allow yay installation.${NC}"
             return 1 # Return non-zero status to indicate failure
        fi

        echo -e "${YELLOW}Updating system databases via yay...${NC}"
        # Use Syu to update official repos and AUR packages in one go later if desired,
        # but Sy is fine for just updating databases before installing specifics.
        yay -Sy || { echo -e "${RED}Failed to update databases via yay. Exiting.${NC}"; exit 1; }

        if [ -f "allPackages.txt" ]; then
             echo -e "${YELLOW}Processing AUR packages from allPackages.txt...${NC}"
             while IFS= read -r aur_package || [[ -n "$aur_package" ]]; do
                 # Skip empty lines or lines starting with #
                 [[ -z "$aur_package" || "$aur_package" =~ ^# ]] && continue

                 if ! yay -Qi "$aur_package" &> /dev/null; then
                     echo -e "${YELLOW}Installing $aur_package from AUR...${NC}"
                     yay -S --noconfirm "$aur_package" || { echo -e "${RED}Failed to install $aur_package. Continuing with next package.${NC}"; }
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
    echo -e "${CYAN}Do you want to install Flatpak applications from flatpaksFSR.txt? (y/n)${NC}"
    read -r install_flatpak

    # Default to 'y' if input is empty
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
             # Use sudo for system-wide installation, or --user for user-specific
             flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || { echo -e "${RED}Failed to add Flathub repository. Skipping Flatpak installation.${NC}"; return 1; }
        else
             echo -e "${GREEN}Flathub repository is already added.${NC}"
        fi

        if [ -f "flatpaksFSR.txt" ]; then
             echo -e "${YELLOW}Installing Flatpak applications from flatpaksFSR.txt...${NC}"
             while IFS= read -r flatpak_package || [[ -n "$flatpak_package" ]]; do
                 # Skip empty lines or lines starting with #
                 [[ -z "$flatpak_package" || "$flatpak_package" =~ ^# ]] && continue

                 echo -e "${YELLOW}Installing $flatpak_package...${NC}"
                 # Use -y for non-interactive installation
                 flatpak install -y flathub "$flatpak_package" || { echo -e "${RED}Failed to install $flatpak_package. Continuing with next Flatpak.${NC}"; }
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
    echo -e "${CYAN}Do you want to apply config files (backup ~/.config, copy new .config and .bashrc)? (y/n)${NC}"
    read -r apply_config

    # Default to 'y' if input is empty
    if [ -z "$apply_config" ]; then
        apply_config="y"
    fi

    if [[ "$apply_config" == "y" ]]; then
        CONFIG_SOURCE_DIR="../.config" # Assuming the .config dir to copy is one level up
        BASHRC_SOURCE="./.bashrc"      # Assuming the .bashrc to copy is in the current dir

        # Check if source files/dirs exist
        if [ ! -d "$CONFIG_SOURCE_DIR" ]; then
            echo -e "${RED}Source configuration directory '$CONFIG_SOURCE_DIR' not found. Skipping .config copy.${NC}"
        else
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_DIR="$HOME/.config.backup_$TIMESTAMP"

            if [ -d "$HOME/.config" ]; then
                 echo -e "${YELLOW}Backing up current configuration files to $BACKUP_DIR...${NC}"
                 # Use -a to preserve attributes, be verbose with -v if needed
                 cp -a "$HOME/.config" "$BACKUP_DIR" || { echo -e "${RED}Failed to back up configuration files. Aborting config application.${NC}"; return 1; }
            else
                 echo -e "${YELLOW}No existing ~/.config directory found. Skipping backup.${NC}"
            fi

            echo -e "${YELLOW}Copying new configuration files from $CONFIG_SOURCE_DIR to ~/.config/...${NC}"
            # Ensure target directory exists
            mkdir -p "$HOME/.config"
            # Copy contents of source into target
            cp -ar "$CONFIG_SOURCE_DIR/." "$HOME/.config/" || { echo -e "${RED}Failed to copy configuration files. Check permissions and paths.${NC}"; return 1; }
            echo -e "${GREEN}.config files applied successfully.${NC}"
        fi

        if [ ! -f "$BASHRC_SOURCE" ]; then
             echo -e "${RED}Source file '$BASHRC_SOURCE' not found. Skipping .bashrc copy.${NC}"
        else
             # Backup existing .bashrc if it exists
             if [ -f "$HOME/.bashrc" ]; then
                  echo -e "${YELLOW}Backing up existing ~/.bashrc to ~/.bashrc.backup_$TIMESTAMP...${NC}"
                  cp -a "$HOME/.bashrc" "$HOME/.bashrc.backup_$TIMESTAMP" || { echo -e "${RED}Failed to back up .bashrc. Aborting .bashrc copy.${NC}"; return 1; }
             fi
             echo -e "${YELLOW}Copying new .bashrc to ~/.bashrc...${NC}"
             # Copying .bashrc usually doesn't require sudo unless modifying root's bashrc
             cp "$BASHRC_SOURCE" "$HOME/.bashrc" || { echo -e "${RED}Failed to copy .bashrc. Check permissions.${NC}"; return 1; }
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

    # Default to 'y' if input is empty
    if [ -z "$apply_theme" ]; then
        apply_theme="y"
    fi

    if [[ "$apply_theme" == "y" ]]; then
        # Check if gsettings command exists
        if ! command -v gsettings &> /dev/null; then
            echo -e "${RED}'gsettings' command not found. Cannot set theme. Is 'glib2' installed? Skipping.${NC}"
            # Check if running Wayland or X11 - gsettings might need DISPLAY or WAYLAND_DISPLAY
            if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
                 echo -e "${YELLOW}Note: You might need to run this script from within a graphical session for gsettings to work.${NC}"
            fi
            return 1 # Indicate failure
        fi

        echo -e "${YELLOW}Applying 'Arc-Dark' GTK theme via gsettings...${NC}"
        gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
        
        # Check the exit status of the gsettings command
        if [ $? -eq 0 ]; then
             echo -e "${GREEN}GTK theme set to 'Arc-Dark' successfully.${NC}"
        else
             echo -e "${RED}Failed to set GTK theme using gsettings.${NC}"
             echo -e "${YELLOW}Ensure the 'Arc-Dark' theme (e.g., package 'arc-gtk-theme') is installed.${NC}"
             echo -e "${YELLOW}Also ensure you are running this within a graphical user session (not just TTY).${NC}"
             # We don't exit the script here, just report the error.
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
