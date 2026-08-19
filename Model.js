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
    source: "",
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
  var position = parsed.position || {}
  status.room = stringValue(device.name || parsed.room || parsed.room_name || parsed.name)
  status.transport = stringValue(transport.State || transport.state || parsed.transport_state || parsed.transportState || parsed.state || "Unknown")
  status.title = stringValue(track.title || parsed.title || "Nothing playing")
  status.artist = stringValue(track.artist || parsed.artist)
  status.album = stringValue(track.album || parsed.album)
  status.source = sourceName(track.uri || position.TrackURI)
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

function sourceName(uri) {
  var value = String(uri || "").toLowerCase()
  if (value.indexOf("spotify") !== -1) return "Spotify"
  if (value.indexOf("x-rincon-stream") !== -1) return "Line-in"
  if (value.indexOf("x-sonosapi-stream") !== -1) return "Radio"
  if (value.indexOf("x-sonos-htastream") !== -1) return "TV"
  return value === "" ? "" : "Sonos"
}

function isIPv4(value) {
  var parts = String(value || "").split(".")
  if (parts.length !== 4) return false
  for (var i = 0; i < parts.length; i++) {
    if (!/^\d{1,3}$/.test(parts[i])) return false
    var octet = Number(parts[i])
    if (octet < 0 || octet > 255) return false
  }
  return true
}

function parseGroups(raw) {
  var parsed
  try {
    parsed = JSON.parse(String(raw || ""))
  } catch (error) {
    return { ok: false, error: "Could not read Sonos rooms" }
  }

  var rooms = []
  var devices = []
  var seenDevices = {}
  var groups = parsed.groups || []
  for (var i = 0; i < groups.length; i++) {
    var group = groups[i] || {}
    var members = group.members || []
    for (var j = 0; j < members.length; j++) {
      var member = members[j] || {}
      var ip = stringValue(member.ip)
      var name = stringValue(member.name)
      if (isIPv4(ip) && name !== "" && !seenDevices[ip]) {
        devices.push({ name: name, ip: ip })
        seenDevices[ip] = true
      }
      if (member.isVisible === false || !isIPv4(ip) || name === "") continue
      rooms.push({
        name: name,
        ip: ip,
        members: members.filter(function(candidate) { return isIPv4(candidate.ip) && candidate.name })
          .map(function(candidate) { return { name: stringValue(candidate.name), ip: stringValue(candidate.ip) } })
      })
    }
  }
  return { ok: true, rooms: rooms, devices: devices }
}
