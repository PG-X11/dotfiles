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
} ```
