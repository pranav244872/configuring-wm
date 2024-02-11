#!/bin/bash
# Define the list of packages to install
sudo pacman -S --noconfirm git firefox bluez bluez-utils networkmanager hyprland kitty mako polkit-kde-agent waybar gtk3
sudo pacman -S --noconfirm less file qt5-wayland lf neovim wl-clipboard rofi udiskie python-pywal swaybg papirus-icon-theme noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd
sudo pacman -S --noconfirm xdg-desktop-portal-hyprland blueman
sudo pacman -S --noconfirm qt6-wayland
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
cp ~/del/configuring-wm/scripts/colors.sh ~/scripts/
cd ~/scripts
chmod +x colors.sh
echo "gave executable permissions to colors.sh script"

cp -r ~/del/configuring-wm/.config/* ~/.config/

sudo systemctl enable bluetooth.service
echo "Folders copied successfully."
echo "succesfully copied dotfiles"
