import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})
  property bool active: false
  property string room: ""
  property string transport: "Unknown"
  property string title: "Nothing playing"
  property string artist: ""
  property string album: ""
  property int volume: 0
  property bool muted: false
  property string lastError: ""

  readonly property string sonoshPath: String(setting("sonoshPath", "sonosh") || "sonosh")
  readonly property string configuredRoom: String(setting("room", "") || "")
  readonly property string configuredIP: String(setting("ip", "") || "")
  readonly property bool busy: commandProcess.running

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function command(action, args) {
    var parts = [sonoshPath].concat(action)
    if (configuredIP !== "") parts.push("--ip", configuredIP)
    else if (configuredRoom !== "") parts.push("--name", configuredRoom)
    return parts.concat(args || [])
  }

  function refresh() {
    if (statusProcess.running) return
    statusProcess.command = command(["status"], ["--format", "json"])
    statusProcess.running = true
  }

  function run(action, args) {
    if (commandProcess.running) return
    lastError = ""
    commandProcess.command = command(action, args)
    commandProcess.running = true
  }

  function togglePlayback() {
    var wasPlaying = Model.isPlaying(transport)
    transport = wasPlaying ? "PAUSED_PLAYBACK" : "PLAYING"
    run([wasPlaying ? "pause" : "play"])
  }

  function changeVolume(delta) {
    volume = Math.max(0, Math.min(100, volume + delta))
    run(["volume", "set"], [String(volume)])
  }

  function applyStatus(raw) {
    var result = Model.parseStatus(raw)
    if (!result.ok) {
      lastError = result.error
      return
    }

    room = result.status.room
    transport = result.status.transport
    title = result.status.title
    artist = result.status.artist
    album = result.status.album
    volume = result.status.volume
    muted = result.status.muted
    lastError = ""
  }

  onActiveChanged: if (active) refresh()
  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: root.active
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    running: false
    stdout: StdioCollector { id: statusOut; waitForEnd: true }
    stderr: StdioCollector { id: statusErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) root.applyStatus(statusOut.text)
      else root.lastError = String(statusErr.text || "sonosh status failed").trim()
    }
  }

  Process {
    id: commandProcess
    running: false
    stderr: StdioCollector { id: commandErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.lastError = String(commandErr.text || "Sonos command failed").trim()
      root.refresh()
    }
  }
}
