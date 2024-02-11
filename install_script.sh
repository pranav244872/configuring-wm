#!/bin/bash

# Define the list of packages to install
sudo pacman -S --noconfirm git firefox bluez bluez-utils networkmanager hyprland kitty mako wireplumber polkit-kde-agent waybar gtk3
sudo pacman -S --noconfirm less file qt5-wayland lf neovim wl-clipboard rofi udiskie python-pywal swaybg papirus-icon-theme noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd

# Create a directory called 'del' in the home directory
mkdir ~/del
echo "Created a directory called del in home"

# Create Downloads folder in the home directory
mkdir -p ~/Downloads
echo "Created a directory called downloads"

# Create Pictures folder in the home directory
mkdir -p ~/Pictures
echo "Created a directory called Pictures"

# Create Wallpapers folder within Pictures
mkdir -p ~/Pictures/Wallpapers
echo "Created a directory called Pictures --> Wallpapers"
# Creating Screenshots folder within Pictures
mkdir -p ~/Pictures/Screenshots
echo "Created a directory called Pictures --> Screenshot"
# Change directory to 'del'
cd ~/del || exit
echo "pwd --> del"
# Clone the Yay AUR helper repository
git clone https://aur.archlinux.org/yay.git
echo "cloning yay.git repository"
# Change directory to 'yay'
cd yay || exit
echo "pwd --> ~/del/yay"
# Build and install Yay using makepkg
echo "building yay"
makepkg -si
# Enable and start Pipewire and WirePlumber services using systemctl
echo "Enable and start Pipewire and WirePlumber services using systemctl"
sudo systemctl --user --now enable pipewire wireplumber
# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Please install yay first."
    exit 1
fi

# Install hyprshot using yay
echo "installing hyprshot for screenshots"
yay -S hyprshot

# Go to ~/del directory
echo "pwd ~/del"
cd ~/del || exit

# Clone the repository
echo "cloning pranav's repository"
git clone https://github.com/pranav244872/configuring-wm.git || exit

# Move into the repository directory
cd configuring-wm || exit
echo "pwd ~/del/configuring-wm"

# Copy .bashrc from the repository to the home directory
cp ~/del/configuring-wm/.bashrc ~/.bashrc
echo "copied .bashrc from pranavs repo to system repo"
# Display a message indicating success
echo "Successfully copied .bashrc from configuring-wm to ~/.bashrc"

# Making a scripts folder in home
mkdir -p ~/scripts
echo "Successfully created a scripts folder"
# Copying the scripts folder from configuring-wm to ~/scripts
cp ~/del/configuring-wm/colors.sh ~/scripts/

# Making config files
# Source directory
dir_a="~/del/configuring-wm/.config"
# Destination directory
dir_b="~/.config"
# Copy folders from directory A to directory B
echo "Copying config files from $dir_a to $dir_b..."
# Loop through each folder in directory A
for folder in "$dir_a"/*; do
    # Extract folder name
    folder_name=$(basename "$folder")
    # Check if folder exists in directory B
    if [ -d "$dir_b/$folder_name" ]; then
        # Remove existing folder in directory B
        rm -rf "$dir_b/$folder_name"
    fi
    # Copy folder from directory A to directory B
    cp -r "$folder" "$dir_b"
    echo "Copied $folder_name"
done

echo "Folders copied successfully."
echo "succesfully copied dotfiles"
