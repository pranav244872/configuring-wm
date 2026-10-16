# Hyprland Rice Configuration and Installation

Welcome to my Hyprland Rice configuration repository! This project showcases my desktop customization setup using various configuration files and an installation script.

 OS: Arch Linux (btw)  
 WM: Hyprland  
 Colorscheme: pywal  
 Font: JetBrains Mono Nerd  
 Text editor: Neovim  
 Top Bar: quickshell (own UI — replaces waybar)  
 App Launcher: quickshell drawer (`SUPER+F` — replaces Rofi)  
 Powermenu: quickshell (planned — replaces Rofi)  
 OSD / screenshots / calendar: quickshell (`PRINT` screenshots, desktop calendar)  
 MPV: bare config + vendored uosc (old modernz/thumbfast setup removed 2026-10)  
 Terminal: kitty  
 Firefox theme: pywalfox  
 Idle daemon: hypridle  
 Screen lock: hyprlock  
 Display Manager: SDDM  

## 2026 rebuild notes

Bare setup: quickshell replaces waybar / rofi / mako / swayosd / hyprshot
(see `.config/quickshell`, keybinds `SUPER+F` launcher · `PRINT` screenshots).
mpv rebuilt bare with vendored uosc; old configs kept nowhere — this repo tracks
the live setup (`diff -rq .config/<app> ~/.config/<app>` should print nothing).

## Examples
![image](https://github.com/pranav244872/configuring-wm/assets/137860111/bab3ae7d-281c-4643-9ca2-43249bd89c58)
![image](https://github.com/pranav244872/configuring-wm/assets/137860111/135f7812-e161-4875-af6c-0b710972f9df)
![image](https://github.com/pranav244872/configuring-wm/assets/137860111/02bedce6-0e14-4094-99ec-49e77e712c19)
![image](https://github.com/pranav244872/configuring-wm/assets/137860111/769a61eb-d65a-43b5-a666-0ecbd8ec5eb1)
![image](https://github.com/pranav244872/configuring-wm/assets/137860111/f1afcf28-8174-4485-ab65-0c2bdab6e531)


