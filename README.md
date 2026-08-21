# Sonos for Omarchy

Control a Sonos room from the Omarchy Quattro bar. The plugin shows the active
source and now-playing metadata, controls playback and volume, and lists the
rooms and bonded devices discovered on your local network.

## Requirements

- Omarchy Quattro
- [sonosh](https://github.com/shlomiuziel/sonosh), the local Sonos CLI backend
- `curl`, included with Omarchy

Install `sonosh` with Go:

```sh
go install github.com/shlomiuziel/sonosh/cmd/sonosh@latest
sonosh discover
```

The plugin discovers and selects the first visible Sonos room automatically.
Use the room list in its panel to switch rooms.

If `sonosh` is not on Omarchy's graphical-session `PATH`, set its absolute path
in **Setup > Plugins > Sonos**, or have an agent run:

```sh
omarchy bar set io.github.mcole.sonos sonoshPath "$(command -v sonosh)"
```

## Install

```sh
omarchy plugin add https://github.com/mattcole19/omarchy-sonos.git --enable
```

Omarchy asks where to place the widget. Its default is the right bar section;
move it later with:

```sh
omarchy bar move io.github.mcole.sonos --section right
```

## Configure

No room configuration is needed after installation. Optionally set **Sonos
room** to choose a particular default. For the fastest controls, set **Speaker
IP address** to the room coordinator's stable LAN IP. This skips SSDP discovery.
Reserve that address in your router before relying on it long-term.

The panel lists the full Sonos group topology, including bonded devices such as
Sub and surround speakers. Select a visible room to control it.

## Use

- Left-click the `S` bar icon to open the panel.
- Right-click it to toggle play/pause.
- Drag the volume slider, then release to send one volume command.
- Use the room list to switch the target room.

## Update and Remove

```sh
omarchy plugin update io.github.mcole.sonos
omarchy plugin remove io.github.mcole.sonos
```

The plugin does not install or manage `sonosh`; remove that separately if it is
no longer needed.

## Security and Privacy

The plugin runs as unsandboxed QML in Omarchy's long-lived shell process. It
executes the `sonosh` path you configure and makes local HTTP requests only to
validated IPv4 addresses reported by Sonos group discovery. It does not collect,
store, or transmit account credentials. Review the source before installation.

## Development

```sh
omarchy plugin validate .
qmllint Panel.qml Service.qml
```

Test the normal install flow from a separate Omarchy profile or machine using
the GitHub install command above.
