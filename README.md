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

![Screenshot](https://github.com/user-attachments/assets/c824d283-de7a-4730-a310-d6b468a71689)

---

## Installation

Run the automatic installer (recommended):

```bash
bash <(curl -s https://raw.githubusercontent.com/EisregenHaha/fedora-hyprland/main/setup.sh)
```

Then **reboot** and select the **Hyprland (uwsm)** session to log in.

---

## Updating

To update the configs:

1. Run the script again.
2. Select **option 2 (Update dotfiles)** in the menu.

> Place any custom Hyprland config changes in `.config/hypr/custom`.  
> These files are **not overwritten** by the update process.  
> This is also where resolution, keyboard, cursor, and input settings now live.

---

## Notes
  
- Original (outdated) discussion: [#840](https://github.com/end-4/dots-hyprland/discussions/840)

### For Nvidia users:
- Uncomment the lines found in ~/.config/hypr/custom/env.conf
---

## Thanks

- [@Kamion008](https://github.com/Kamion008) – Fedora version  
- [@nullptroma](https://github.com/nullptroma) – Original OpenSUSE script
