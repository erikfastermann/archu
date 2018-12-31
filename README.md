# Archu - 'Arch your way'
A hackable and easy install of Arch Linux

written by Erik Fastermann

Based on <https://wiki.archlinux.org/index.php/installation_guide> and <https://wiki.archlinux.de/title/Anleitung_f%C3%BCr_Einsteiger>.

## Usage
1. Boot from an Arch installation medium.
2. If you are not using the US Keyboard layout, e.g.:
```
loadkeys de
```
3. Check your Internet connection with:
```
ping -c4 google.com
```
For Wifi use:
```
wifi-menu
```
4. Download and execute the script.
```
curl -LO fastermann.de/archu.sh
bash archu.sh
```
5. After the script ran successfully, you will be prompted for a new root password. Then unplug the installation media and:
``` 
reboot
```

## Configuration
You can change the config at the beginning of the script. More details can be found there.

The default settings are for Germany.

## Modification
Archu breaks out every feature in separate functions. Therefore it's easily hackable.

## Planned features
- Setting the Hardware clock
- Customize Fstab for SSD's etc.
- Drive-Encryption
- Adding a user + password
- Deploying your own Dot files
- Parsing a custom list of programs for Pacstrap
- X11-Deployment and configs
- Using Parted for partitioning
- Fastest mirror with Reflector
