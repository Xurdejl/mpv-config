<h1 align="center">~ 🌑 𝓜𝓟𝓥 𝓒𝓸𝓭𝓮𝔁 🌑 ~</h1>

<h3 align="center"><samp>&gt;  Just a set of scripts and configs, because default settings are boring.</samp></h3>

<p align="center"><samp>「 These are my personal opinionated MPV settings. 」</samp></p>

![img](https://i.imgur.com/RGkqkXa.png)

## 🌨️ Shaders

- **[FSRCNN](https://github.com/igv/FSRCNN-TensorFlow/releases)** - Prescaler based on layered convolutional networks.

- **[SSimDownscaler, SSimSuperRes, Krig, Adaptive Sharpen, etc.](https://gist.github.com/igv)**
  - **[SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10)** - Perceptually based downscaler.
  - **[SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b)** - The aim of this shader is to make corrections to the image upscaled by mpv built-in scaler (removes ringing artifacts, restores original sharpness, etc).
  - **[Krig](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)** - Chroma scaler that uses luma information for high quality upscaling.

## 🔮 Scripts

- **[hayase-osc](./scripts/hayase-osc.lua)** - Custom OSC skin inspired by [hayase.watch](https://hayase.watch)'s UI _(forked from [ModernZ](https://github.com/Samillion/ModernZ))_.

- **[evafast](https://github.com/po5/evafast)** - Fast-forwarding and seeking on a single key, with quality of life features like a slight slowdown when subtitles are shown.

- **[silentskip](./scripts/silentskip.lua)** - Skip intro/ending with silence detection fallback via hotkey.

- **[thumbfast](https://github.com/po5/thumbfast)** - High-performance on-the-fly thumbnailer script for mpv.

- **[webm](https://github.com/ekisu/mpv-webm)** - Quickly create video clips.

## 💜 References

- [MPV Manual](https://mpv.io/manual/stable/)
- [I am Scum's Guide](https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/)
