function stringValue(value) {
  return value === undefined || value === null ? "" : String(value)
}

function numberValue(value, fallback) {
  var parsed = Number(value)
  return isFinite(parsed) ? parsed : fallback
}

function emptyStatus() {
  return {
    room: "",
    transport: "Unknown",
    title: "Nothing playing",
    artist: "",
    album: "",
    volume: 0,
    muted: false
  }
}

// sonosh nests the current device and transport fields. The fallbacks keep the
// widget compatible with earlier flat JSON output too.
function parseStatus(raw) {
  var status = emptyStatus()
  var parsed

  try {
    parsed = JSON.parse(String(raw || ""))
  } catch (error) {
    return { ok: false, error: "Could not read sonosh status" }
  }

  var track = parsed.nowPlaying || parsed.now_playing || parsed.track || {}
  var device = parsed.device || {}
  var transport = parsed.transport || {}
  status.room = stringValue(device.name || parsed.room || parsed.room_name || parsed.name)
  status.transport = stringValue(transport.State || transport.state || parsed.transport_state || parsed.transportState || parsed.state || "Unknown")
  status.title = stringValue(track.title || parsed.title || "Nothing playing")
  status.artist = stringValue(track.artist || parsed.artist)
  status.album = stringValue(track.album || parsed.album)
  status.volume = Math.max(0, Math.min(100, Math.round(numberValue(parsed.volume, 0))))
  status.muted = parsed.muted === true || parsed.mute === true

  return { ok: true, status: status }
}

function isPlaying(transport) {
  return String(transport).toUpperCase() === "PLAYING"
}

function transportLabel(transport) {
  var value = String(transport).replace(/_/g, " ").toLowerCase()
  return value.length === 0 ? "Unknown" : value.charAt(0).toUpperCase() + value.slice(1)
}
