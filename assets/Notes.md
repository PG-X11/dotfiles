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
