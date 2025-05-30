<div align="center">

# 【 end_4's Hyprland Dotfiles for Fedora 】

 Automated setup for a Hyprland desktop environment on **Fedora Linux**  


</div>

---

## ⚠️ Fedora Only

This script is intended for **Fedora**.  
For the Arch version, visit: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

> ✅ **Tested on Fedora 42**

---

##  Preview

![Screenshot_2025-05-30_02 56 51](https://github.com/user-attachments/assets/ae859013-0537-4f51-afd6-64545777aeea)

---

## Installation

### First read the notes section, this is not optional.

Run the automatic installer:

```bash
bash <(curl -s https://raw.githubusercontent.com/EisregenHaha/fedora-hyprland/main/setup.sh)
```

Then **reboot** and select the **Hyprland (uwsm)** session to log in.

---

## Updating

To update the configs:

1. Make sure you have read the Notes
2. Run the script again.
3. Select **option 2 (Update dotfiles)** in the menu.

---

## Notes

### Regarding Updates
> Place any custom Hyprland config changes in `.config/hypr/custom`.  
> These files are **not overwritten** by the update process. Otherwise you **will** lose your configuration changes after updating.  
> This is also where resolution, keyboard, cursor, and input settings now live.
  
### For Nvidia users:
- Uncomment the lines found in ~/.config/hypr/custom/env.conf

### Keybinds
- Default keybinds: Parts similar to Windows and GNOME. Hit Super+/ for a list
<details> 
       <summary>Here's an image, just in case...</summary>
    
       ![image](https://github.com/user-attachments/assets/c09531c9-3b55-493a-880f-7e044cd9dca0)

</details>

### Archive (not needed)
- Original (outdated) discussion: [#840](https://github.com/end-4/dots-hyprland/discussions/840)
---

## Thanks

- [@Kamion008](https://github.com/Kamion008) – Fedora version  
- [@nullptroma](https://github.com/nullptroma) – Original OpenSUSE script

                        
## stars because i like big numbers
[![Stargazers over time](https://starchart.cc/EisregenHaha/fedora-hyprland.svg?variant=adaptive)](https://starchart.cc/EisregenHaha/fedora-hyprland)

                    
