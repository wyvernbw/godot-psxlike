<h1 align="center">Godot <code>psxlike</code></h1>

<div align="center">
  <img style="image-rendering: pixelated;" src="./preview.gif" alt="Preview of PSX rendering">
  
  Accurate PS1 rendering for Godot 4+
</div>

Read the article explaining the approach: [https://calinp.eu/blog/psx-type-rendering/](https://calinp.eu/blog/psx-type-rendering/)

Notable Features:
- Accurate vertex snapping 
- Custom lighting system
- Flat triangle depth buffer
- Affine Texture Mapping
- Accurate and granular (per-model) dither
- Color modulation fog and Silent Hill style fog

## Usage

1. Clone the repo
2. Copy the `addons/psxlike` folder to your `addons` folder
3. Enable the plugin in Project Settings and reload the project
4. Use the `psx_opaque` or `psx_transparent` materials from the `psxlike` folder
5. add any lights that you want to interact with the renderer to the `psx_light` group
