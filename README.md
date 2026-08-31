# MAGI

<p align="center">
  <strong>A floating MAGI bar for Omarchy.</strong><br>
  Always on. Drawers still slide in from the edges.
</p>

<p align="center">
  <img src="preview.png" width="640" alt="MAGI dashboard sliding from the top edge: Balthasar weather, Melchior meters, Casper media">
</p>

MAGI **is** the bar. It replaces `omarchy.bar` with a floating pill that stays on screen, like Caelestia. Your existing layout (menu, workspaces, clock, network, tray, …) lives inside that pill. Hover the top gap for the MAGI dashboard; the side edges open the NERV session and Casper utility drawers.

No sudo. No extra daemon.

## Install

```sh
omarchy plugin add https://github.com/Gedankenn/magi.git --enable
omarchy bar use io.github.gedankenn.magi
```

That last command makes MAGI the active bar (`bar.id` in `shell.json`). `omarchy bar use omarchy.bar` puts the stock bar back.

## What you get

| Edge | What appears |
| --- | --- |
| Top (above the pill) | MAGI dashboard (weather, CPU/RAM/disk, media) |
| Left | NERV session card: lock, logout, reboot, shutdown |
| Right | Casper utilities: live CPU/RAM, night light, stay-awake, DND |

Move the pointer off a drawer and it slides away. The bar stays put.

## Shortcuts

| Input | Action |
| :---: | --- |
| Pointer on a screen edge | Reveal that drawer |
| `Super + D` | Pin / unpin the MAGI dashboard |
| Escape (while pinned) | Release the dashboard |
| `r` | Refresh weather and meters |
| Space | Play / pause |

Bind it yourself if you skipped the default:

```sh
# in ~/.config/hypr/bindings.lua
o.bind("SUPER + D", "MAGI dashboard", "omarchy-shell io.github.gedankenn.magi toggle")
```

## Configure

MAGI reads the same `bar.layout` as the stock bar. Move widgets with the usual commands:

```sh
omarchy bar move omarchy.clock --section center
omarchy bar set omarchy.clock format "HH:mm"
```

Put MAGI in charge with:

```json
"bar": {
  "id": "io.github.gedankenn.magi",
  "position": "top",
  "layout": { "left": [], "center": [], "right": [] }
}
```

## Remove

```sh
omarchy bar use omarchy.bar
omarchy plugin remove io.github.gedankenn.magi
```

## License

[MIT](LICENSE) © Fabio Slika Stella
