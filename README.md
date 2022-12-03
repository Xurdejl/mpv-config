# MPV config files

<img src="https://raw.githubusercontent.com/cyl0/ModernX/main/preview.png"/>

## Shaders

- **[ACNet](https://github.com/TianZerL/ACNetGLSL/releases/tag/v1.0.0)** - ACNet is a CNN algorithm, implemented by [Anime4KCPP](https://github.com/TianZerL/Anime4KCPP), it aims to provide both high-quality and high-performance.

- **[FSRCNN](https://github.com/igv/FSRCNN-TensorFlow/releases)** - Prescaler based on layered convolutional networks.
    
-   **[SSimDownscaler, SSimSuperRes, Krig, Adaptive Sharpen, etc.](https://gist.github.com/igv)**
    
    -   **[SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10)** - Perceptually based downscaler.
    -   **[SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b)** - The aim of this shader is to make corrections to the image upscaled by mpv built-in scaler (removes ringing artifacts, restores original sharpness, etc).
    -   **[Krig](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)** - Chroma scaler that uses luma information for high quality upscaling.

## Scripts

- **[ModernX](https://github.com/cyl0/ModernX)** - A modern OSC UI replacement for MPV that retains the functionality of the default OSC.

- **[autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)** - Automatically load playlist entries before and after the currently playing file, by scanning the directory.

- **[remember-volume](https://gist.github.com/blackarcher21/162dc1bef708e90082c6c4f9500c1997)** - Remembers last sesion volume.

- **[copy-paste-URL](https://github.com/yassin-l/copy-paste-url)** - Paste URLs directly from clipboard into mpv.

- **[autoloop](https://github.com/zc62/mpv-scripts/blob/master/autoloop.lua)** - Automatically loops files that are under a given duration (default 5 seconds).

- **[open-file-dialog](https://github.com/rossy/mpv-open-file-dialog)** - Launches a regular Windows file open dialog for loading videos (Windows).

- **[track-list](https://github.com/dyphire/mpv-scripts/blob/main/track-list.lua)** - Interractive track-list menu. (needs [mpv-scroll-list](https://github.com/CogentRedTester/mpv-scroll-list/blob/master/scroll-list.lua))
