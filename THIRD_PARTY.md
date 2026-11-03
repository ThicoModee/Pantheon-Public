# Third-party assets

## Lucide interface icons

Source: https://icon-sets.iconify.design/lucide/

API data: `Lib/vendor/lucide/icons.json`. SVG bodies are copied without hand-edited paths into `ui/icons.js`.

Author: Lucide Contributors. License: ISC, with upstream notices retained in `Lib/vendor/lucide/LICENSE`.

## Pantheon assets and macro base

Original macro images and helmet icon are from `ThicoModee/Pantheon-Public`, base commit `fd1d46ea0ae812468ef7cbceb40fc8b0bc0a58d3`. Macro images are byte-identical copies; the helmet PNG is a format conversion of the original ICO.

The outdated macro scripts have been removed. Bundled FindText and GDI+ helpers retain their upstream author and license notices in `Lib/vendor/FindText.ahk` and `Lib/vendor/Gdip_All.ahk`.

## AHK WebView2 wrapper

thqby/ahk2_lib, pinned to `559839b58353e31ec90796d1c2609c8f40b721f2`.

Wrapper/Promise/ComVar/JSON: `Lib/vendor/LICENSE` and source notices. Microsoft loader: `Lib/vendor/WEBVIEW2-NOTICE.md`.

UI reference: [LeniLilac/expeditions-macro](https://github.com/LeniLilac/expeditions-macro). The hub independently implements the screenshot placement workflow and layout; no source code or media from that repository is included.
