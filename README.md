# MPV config files

<img src="https://raw.githubusercontent.com/cyl0/ModernX/main/preview.png"/>

## Shaders

- **[FSRCNN](https://github.com/igv/FSRCNN-TensorFlow/releases)**  
Prescaler based on layered convolutional networks. [FSRCNNX-Enhance](https://github.com/HelpSeeker/FSRCNN-TensorFlow/releases/tag/1.1_distort) for anime.
    
-   **[SSimDownscaler, SSimSuperRes, Krig, Adaptive Sharpen, etc.](https://gist.github.com/igv)**
    
    -   SSimDownscaler: Perceptually based downscaler. More information is [here](https://graphics.ethz.ch/~cengizo/imageDownscaling.htm).
    -   SSimSuperRes: The aim of this shader is to make corrections to the image upscaled by mpv built-in scaler (removes ringing artifacts, restores original sharpness, etc).
    -   Krig: Chroma scaler that uses luma information for high quality upscaling.
 
 - **[ACNet](https://github.com/TianZerL/ACNetGLSL/releases/tag/v1.0.0)**  
ACNet is a CNN algorithm, implemented by [Anime4KCPP](https://github.com/TianZerL/Anime4KCPP), it aims to provide both high-quality and high-performance.

## Scripts

- **[autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua)**  
Automatically load playlist entries before and after the currently playing file, by scanning the directory.

- **[remember-volume](https://gist.github.com/blackarcher21/162dc1bef708e90082c6c4f9500c1997)**  
Remembers last sesion volume.

- **[copy-paste-URL](https://github.com/yassin-l/copy-paste-url)**  
Paste URLs directly from clipboard into mpv.

- **[open-file-dialog](https://github.com/rossy/mpv-open-file-dialog)**  
(Windows) Launches a regular Windows file open dialog for loading videos.

- **[autoloop](https://github.com/zc62/mpv-scripts/blob/master/autoloop.lua)**  
Automatically loops files that are under a given duration (default 5 seconds).

- **[ModernX](https://github.com/cyl0/ModernX)**  
A modern OSC UI replacement for MPV that retains the functionality of the default OSC.
