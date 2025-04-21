<div align="center">
    <h1>【 end_4's Hyprland dotfiles for Fedora】</h1>
    <h3></h3>
</div>

These scripts will automatically install the dependencies and configuartions for the dotfiles for Fedora.
Currently Tested on Fedora 42

![image](https://github.com/user-attachments/assets/c824d283-de7a-4730-a310-d6b468a71689)

```bash
# clone the repo
git clone https://github.com/EisregenHaha/fedora-hyprland

# change directories 
cd fedora-hyprland

# install dependencies
sudo bash fedora/install.sh

#install fonts
bash fedora/fonts.sh

# install other dependencies and setup virtual python environment
bash manual-install-helper.sh

# copy the configs
cp -R .config ~/.config
cp -R .local ~/.local
 ```

some fixes for polkit and gammastep/nightlight are noted in this discussion https://github.com/end-4/dots-hyprland/discussions/840


credits go to :

[@Kamion008](https://github.com/Kamion008) (fedora version)
[@nullptroma](https://github.com/nullptroma) (original opensuse script)
