# MAGI

<p align="center">
  <strong>A floating MAGI bar for Omarchy.</strong><br>
  Three cyberpunk HUD islands. Hover to expand them into menus.
</p>

<p align="center">
  <img src="preview.png" width="640" alt="MAGI islands: NERV, MAGI, SYS">
</p>

MAGI **is** the bar. It replaces `omarchy.bar` with three floating HUD islands — left, center, right — instead of one slab. Your existing layout (menu, workspaces, clock, network, tray, …) is grouped into those chips. Hover an island and it grows into a clickable menu. `Super + D` pins the center MAGI panel.

No sudo. No extra daemon.

## Install

```sh
omarchy plugin add https://github.com/Gedankenn/magi.git --enable
omarchy bar use io.github.gedankenn.magi
```

That last command makes MAGI the active bar (`bar.id` in `shell.json`). `omarchy bar use omarchy.bar` puts the stock bar back.

## What you get

| Island | Hover expands into |
| --- | --- |
| Center **MAGI** | Dashboard: Balthasar weather, Melchior meters, Casper media |
| Left **NERV** | Session: lock, logout, reboot, shutdown |
| Right **SYS** | Status: CPU/RAM, night light, stay-awake, DND, next wallpaper |

The island chrome stays put; the plate grows down and wider so the extra buttons live inside it. Move the pointer off and it collapses.

## Shortcuts

| Input | Action |
| :---: | --- |
| Pointer on an island | Expand that island into its menu |
| `Super + D` | Pin / unpin the MAGI dashboard |
| Escape (while pinned) | Release the dashboard |
| `r` | Refresh weather and meters |

Bind it yourself if you skipped the default:

```sh
# in ~/.config/hypr/bindings.lua
o.bind("SUPER + D", "MAGI dashboard", "omarchy-shell io.github.gedankenn.magi toggle")
```

## Configure

MAGI reads the same `bar.layout` as the stock bar, including custom QML modules (`type: qml` in `~/.config/omarchy/bar/modules/<id>.qml`). Move widgets with the usual commands:

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
