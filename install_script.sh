#!/bin/bash

#Install the basic hyprland install from the arch install script

# Define the list of packages to install
sudo pacman -S --noconfirm git firefox bluez bluez-utils networkmanager polkit-kde-agent waybar gtk3 

sudo pacman -S --noconfirm wl-clipboard rofi udiskie python-pywal swaybg xdg-desktop-portal-hyprland qt6-wayland qt5-wayland

sudo pacman -S --noconfirm firefox blueman mako file-roller thunar thunar-archive-manager neovim

sudo pacman -S --noconfirm papirus-icon-theme noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd

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
sudo pacman -Rns go

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Please install yay first."
    exit 1
fi

# Install hyprshot using yay
echo "installing hyprshot for screenshots"
yay -S hyprshot

#Install hypridle using yay
echo "installing hypridle for idle-management"
yay -S hypridle

echo "installing hyprlock for lock-screen"
yay -S hyprlock

# Go to ~/del directory
echo "pwd ~/del"
cd ~/del || exit

# Clone the repository
echo "cloning pranav's repository"
git clone https://github.com/pranav244872/configuring-wm.git || exit

# Move into the repository directory
cd configuring-wm || exit
echo "pwd ~/del/configuring-wm"

cp -r ~/del/configuring-wm/.config/* ~/.config/
echo "Folders copied successfully."
echo "succesfully copied dotfiles"

#Giving permissions for scripts to execute
cd /home/pranav/.config/hypr || exit
echo "pwd ~/.config/hypr"
chmod +x startup.sh
#In waybar
cd /home/pranav/.config/waybar || exit
echo "pwd ~/.config/waybar"
cd scripts/bluetooth || exit
chmod +x bluetooth.sh
cd /home/pranav/.config/waybar || exit
echo "pwd ~/.config/waybar"
cd scripts/launcher || exit
chmod +x launcher.sh
cd /home/pranav/.config/waybar || exit
echo "pwd ~/.config/waybar"
cd scripts/network || exit
chmod +x rofi-wifi.sh
cd /home/pranav/.config/waybar || exit
echo "pwd ~/.config/waybar"
cd scripts/powermenu || exit
chmod +x powermenu.sh


sudo systemctl enable bluetooth.service
echo "enabled bluetooth service"

echo "Check the last line of this file"
## Remember to https://www.reddit.com/r/linuxquestions/comments/t7ze3c/thunar_open_file_in_neovim/
