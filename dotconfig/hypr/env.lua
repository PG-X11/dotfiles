-- Core graphics -- CAREFUL - KEEP ONLY ONE COMMENTED OUT AND OTHER NOT COMMENTED,
-- RESTART SESSION FOR CHANGES TO APPLY !
-- NVIDIA GPU --
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("VDPAU_DRIVER", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_SYNC_TO_VBLANK", "0")
-- hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")
hl.env("AQ_DRM_DEVICES", "/dev/dri/dgpu:/dev/dri/igpu")
-- Causes issues
-- hl.env("GBM_BACKEND", "nvidia-drm") -- this makes nvidia render everything
-- hl.env("DRI_PRIME", "1") -- an X11 concept IDK if it works on xwayland apps

-- INTEL GPU --
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/igpu:/dev/dri/dgpu")
-- hl.env("LIBVA_DRIVER_NAME", "i965")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "intel")
-- hl.env("GBM_BACKEND", "dri")
-- hl.env("WLR_NO_HARDWARE_CURSORS", "0")



-- Wayland session settings
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- Cursor settings
hl.env("XCURSOR_SIZE", "26")
hl.env("HYPRCURSOR_SIZE", "26")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
-- PATH
hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. os.getenv("HOME") .. "/.local/share/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin")

-- KDE / Dolphin compatibility
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Qt / GTK application enhancements
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Browser and Electron apps
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- SDL / Clutter Wayland support
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
