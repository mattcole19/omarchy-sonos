# Sonos for Omarchy

A deliberately small Omarchy Quattro plugin prototype: a bar icon opens a
now-playing panel for one Sonos room, with playback and volume controls.

## Requirements

The plugin delegates all Sonos communication to [sonosh](https://github.com/shlomiuziel/sonosh):

```bash
go install github.com/shlomiuziel/sonosh/cmd/sonosh@latest
sonosh discover
```

Set a default room for `sonosh`, or configure the **Sonos room** setting in the
plugin after installation. For substantially faster controls, set the speaker's
fixed LAN address in **Speaker IP address**; this skips network discovery.

## Test locally

```bash
omarchy plugin validate .
omarchy plugin add "$PWD" --enable
omarchy bar move io.github.mcole.sonos --section right
```

Left-click the bar icon to open the panel. Right-click toggles play/pause.

## Current scope

- Now-playing title, artist, album, transport state, volume, and mute state
- Play/pause, previous, next, volume up/down, and manual refresh
- One room at a time, selected with a plugin setting or sonosh's default room

Grouping, room selection, queues, favorites, search, and artwork are intentionally
outside this prototype.
