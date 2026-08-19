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
  property string source: ""
  property int volume: 0
  property bool muted: false
  property var rooms: []
  property var deviceModels: ({})
  property var modelQueue: []
  property string loadingIP: ""
  property string targetIP: ""
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
    if (targetIP !== "") parts.push("--ip", targetIP)
    else if (configuredIP !== "") parts.push("--ip", configuredIP)
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

  function refreshRooms() {
    if (groupsProcess.running) return
    groupsProcess.command = [sonoshPath, "group", "status", "--all", "--format", "json"]
    groupsProcess.running = true
  }

  function selectRoom(selectedRoom) {
    targetIP = selectedRoom.ip
    room = selectedRoom.name
    refresh()
  }

  function deviceLabel(device) {
    var model = deviceModels[device.ip] || ""
    return model === "" || model === device.name ? device.name : device.name + " (" + model + ")"
  }

  function loadNextModel() {
    if (modelProcess.running || modelQueue.length === 0) return
    var device = modelQueue.shift()
    if (deviceModels[device.ip] !== undefined) {
      loadNextModel()
      return
    }
    loadingIP = device.ip
    modelProcess.command = ["curl", "--fail", "--silent", "--max-time", "2", "--max-filesize", "65536", "http://" + device.ip + ":1400/xml/device_description.xml"]
    modelProcess.running = true
  }

  function togglePlayback() {
    var wasPlaying = Model.isPlaying(transport)
    transport = wasPlaying ? "PAUSED_PLAYBACK" : "PLAYING"
    run([wasPlaying ? "pause" : "play"])
  }

  function setVolume(value) {
    volume = Math.max(0, Math.min(100, Math.round(value)))
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
    source = result.status.source
    volume = result.status.volume
    muted = result.status.muted
    lastError = ""
  }

  onActiveChanged: if (active) { refresh(); refreshRooms() }
  Component.onCompleted: { refresh(); refreshRooms() }

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

  Process {
    id: groupsProcess
    running: false
    stdout: StdioCollector { id: groupsOut; waitForEnd: true }
    stderr: StdioCollector { id: groupsErr; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode !== 0) return
      var result = Model.parseGroups(groupsOut.text)
      if (!result.ok) return
      rooms = result.rooms
      modelQueue = result.devices
      loadNextModel()
    }
  }

  Process {
    id: modelProcess
    running: false
    stdout: StdioCollector { id: modelOut; waitForEnd: true }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        var match = String(modelOut.text).match(/<modelName>([^<]+)<[/]modelName>/)
        if (match) {
          var next = {}
          for (var key in deviceModels) next[key] = deviceModels[key]
          next[loadingIP] = match[1].replace(/^Sonos\s+/, "")
          deviceModels = next
        }
      }
      loadingIP = ""
      loadNextModel()
    }
  }
}
