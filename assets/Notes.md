------------------
2026 9/11 (Really)
- To fix format and MIME type issue on geckolib based browsers
download the package ffmpeg4.4 and restart the browsers

- Pump more power to gpu (basically) by enabling this service

``` sudo systemctl enable --now nvidia-powerd.service ```

- Just a note (usecase to specific I'll probably know when to use)
``` cat /usr/share/glvnd/egl_vendor.d/10_nvidia.json                         
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
} 
```
- installing ```libbsd``` is good for launcing some native linux games, fixed deadcells for me 
- its also good to have ```mesa``` package and ```libglvnd```, duh its libgl, and ```sdl2``` package
- running some steam games from a different steam library (like ~/Games for me) some games fail to search their libraries since they are programmed to one path which is where steam would usually be (./local/share/steam...), so I had to manually adjust laucnher.sh for some games 

- a stupid bug happend on hyprland where no every app requests a maximize state on launch which ruins my script for launching apps, the fix for now is to just install the latest version of hyprland from git, however, I'll the ```hyprland``` package in the /packages folder in needed, because this will be fixed in hyprland 0.57 when it releases, or when 56.3 comes out (if they ever do release that) and after that I'll switch to lua (dear god I have to learn it and i have school and stuff), anyways for now when installing the dotfiles, remove the package and then install after that you can install the latest hyprland by cloning it, its also nice to check if there is a ```hyprland-git``` in the aur I might do that. OUT

- hyprland sucks, end of argument, like I think its intended for you to stick to one version of it and keep it blocked, I will stop updating this bullshit from now on, I am gonna switch to nixOS too since its better than arch, I am sad.., even the github solution fixed it since they did not merge it, I'll have to use the 
