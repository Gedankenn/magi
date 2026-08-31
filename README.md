# MAGI

<p align="center">
  <strong>Edge drawers for Omarchy.</strong><br>
  The bar hides. The pointer finds the edge. MAGI slides in.
</p>

<p align="center">
  <img src="preview.png" width="640" alt="MAGI dashboard sliding from the top edge: Balthasar weather, Melchior meters, Casper media">
</p>

Caelestia-style hover drawers, as an Omarchy plugin. Your existing bar widgets stay. MAGI only parks the bar off-screen and brings it back — plus three floating cards — when the cursor hits a screen edge.

No sudo. No extra daemon.

## Install

```sh
omarchy plugin add https://github.com/Gedankenn/magi.git --enable
```

Then reload if the shell does not pick it up on its own:

```sh
omarchy-shell shell rescanPlugins
```

## What you get

| Edge | What appears |
| --- | --- |
| Top (thin orange line) | Stock Omarchy bar slides back. Linger ~280ms for the MAGI dashboard (weather, CPU/RAM/disk, media). |
| Left | NERV session card: lock, logout, reboot, shutdown |
| Right | Casper utilities: live CPU/RAM, night light, stay-awake, DND |

Move the pointer off the card and it slides away. The bar parks again after a short delay.

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

Optional keys on the plugin entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "io.github.gedankenn.magi",
  "autoHideBar": true,
  "top": true,
  "left": true,
  "right": true,
  "dashDelay": 280,
  "hideDelay": 420,
  "sensorSize": 4
}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `autoHideBar` | `true` | Park the Omarchy bar until the top edge is hit. |
| `top` / `left` / `right` | `true` | Enable that edge. |
| `dashDelay` | `280` | Ms to linger on the top edge before the dashboard drops. |
| `hideDelay` | `420` | Ms after leave before the bar parks again. |
| `sensorSize` | `4` | Hit-strip thickness in px. |

Set `autoHideBar` to `false` if you want the drawers but a persistent bar.

## Remove

```sh
omarchy plugin remove io.github.gedankenn.magi
```

Removing it restores a persistent bar on the next shell reload.

## License

[MIT](LICENSE) © Fabio Slika Stella
