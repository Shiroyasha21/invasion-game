extends Node

# TEMPORARY on-screen debug logger for tracking down the phone-only
# no-enemies bug. Remove this autoload (and its HUD label) once fixed.

signal logged(line: String)

const MAX_LINES := 14

var lines: Array[String] = []


func log_line(text: String) -> void:
	var line := "[%5.1fs] %s" % [Time.get_ticks_msec() / 1000.0, text]
	lines.append(line)
	if lines.size() > MAX_LINES:
		lines.pop_front()
	emit_signal("logged", line)


func get_text() -> String:
	return "\n".join(lines)
