function isPlainObject(value) {
  return !!value && typeof value === "object" && !Array.isArray(value)
}

function normalizePosition(value) {
  var next = String(value || "").trim()
  return /^(top|bottom)$/.test(next) ? next : "top"
}

function entrySettings(entry) {
  if (!isPlainObject(entry)) return {}
  var copy = {}
  for (var key in entry) {
    if (key === "id") continue
    copy[key] = entry[key]
  }
  return copy
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (isPlainObject(entry) && entry.id) return String(entry.id)
  return ""
}

function entryIndex(entries, name) {
  if (!Array.isArray(entries)) return -1
  for (var i = 0; i < entries.length; i++) {
    if (entryId(entries[i]) === name) return i
  }
  return -1
}

function pickPanelSlot(candidates, focusedName) {
  var list = candidates || []
  if (!list.length) return null
  for (var i = 0; i < list.length; i++) {
    if (list[i] && list[i].opened) return list[i]
  }
  if (focusedName) {
    for (var j = 0; j < list.length; j++) {
      if (list[j] && list[j].screenName === focusedName) return list[j]
    }
  }
  return list[0]
}

if (typeof module !== "undefined") {
  module.exports = {
    isPlainObject: isPlainObject,
    normalizePosition: normalizePosition,
    entrySettings: entrySettings,
    entryId: entryId,
    entryIndex: entryIndex,
    pickPanelSlot: pickPanelSlot
  }
}
