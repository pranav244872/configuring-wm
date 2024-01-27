## Setting Up Arch
boot iso:
### run:
rfkill unblock wlan  
iwctl  
station wlan0 connect pranav17  
pacman -Sy archlinux-keyring  
archinstall  
### Note: Do a minimum install  with system-md boot  
### Additional packages:  
git  
chromium  
vlc  
qbittorrent  
bluez  
networkmanager  
nano  
hyprland  
kitty  
mako  
wireplumber  
polkit-kde-agent  
waybar  
gtk3  
less  
file  
qt5-wayland
### Installing yay:
install yay
### installing ranger:
sudo pacman -S ranger
### change .bashrc and .bash_profile:  
add:  
export VISUAL=nvim  (no spaces between = )  
export EDITOR=nvim  
### install cmake:  
sudo pacman -S cmake
### installing neovim:
sudo pacman -S neovim
sudo pacman -S xclip

### configuring waybar to do some magic (didnt work)
If you want to use the workspaces module, first, copy the configuration files from /etc/xdg/waybar/ into ~/.config/waybar/. Then, in ~/.config/waybar/config replace all the references to sway/workspaces with hyprland/workspaces.  
uncomment the workspaces thing(after running as root)  

### configuring pipewire and wireplumber for screensharing
run:  
systemctl --user --now enable pipewire wireplumber
sudo pacman -S xdg-desktop-portal-hyprland
sudo pacman -S grim slurp
sudo pacman -S xdg-desktop-portal-hyprland-git  
pacman -Q | grep xdg-desktop-portal-(if any there remove)  
add the following in hyprland config:  
exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP  

### Configuring an app launcher:  
sudo pacman -S rofi
mkdir ~/.config/rofi
there copied this: https://github.com/sonnybox/yt-files/blob/main/SIMPLE%20LAUNCHER/config.rasi

### Changed the hyprland config files according to ver 1.0.0

### automatic mounting of usbs in hyprland
sudo pacman -S udiskie
Head over to your ~/.config/hypr/hyprland.conf and add the following lines:  
exec-once = udiskie &

### installing network manager applet and blueman
sudo pacman -S network-manager-applet
sudo pacman -S blueman

### created timeshift at this point 2024/01/27 23:49:23

### updating all to ver 1.1.1
