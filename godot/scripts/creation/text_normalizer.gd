class_name TextNormalizer
extends RefCounted
static func normalize(text: String) -> String:
 var out = text.to_lower().strip_edges()
 for pair in [["á","a"],["à","a"],["â","a"],["ã","a"],["é","e"],["ê","e"],["í","i"],["ó","o"],["ô","o"],["õ","o"],["ú","u"],["ç","c"]]:
  out = out.replace(pair[0],pair[1])
 var regex = RegEx.new()
 regex.compile("[^a-z0-9 ]")
 out = regex.sub(out," ",true)
 regex.compile(" +")
 return regex.sub(out," ",true).strip_edges()
static func words(text: String) -> PackedStringArray:
 return normalize(text).split(" ",false)
