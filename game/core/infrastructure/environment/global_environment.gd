extends Node

const DEFAULT_API_BASE_URL = "http://127.0.0.1:8080"
const DEFAULT_WS_BASE_URL = "ws://127.0.0.1:8080/ws/game"

# Mantidos por compatibilidade — use api_base_url()/ws_base_url() que respeitam env/ProjectSettings
const API_BASE_URL = DEFAULT_API_BASE_URL
const WS_BASE_URL = DEFAULT_WS_BASE_URL

static func api_base_url() -> String:
	# Prioridade: env API_URL > ProjectSettings application/api_base_url > default
	if OS.has_environment("API_URL"):
		var env_api := OS.get_environment("API_URL").strip_edges()
		if not env_api.is_empty():
			return env_api
	var ps_api = ProjectSettings.get_setting("application/api_base_url", DEFAULT_API_BASE_URL)
	var ps_api_str := str(ps_api).strip_edges()
	if not ps_api_str.is_empty():
		return ps_api_str
	return DEFAULT_API_BASE_URL

static func ws_base_url() -> String:
	if OS.has_environment("WS_URL"):
		var env_ws := OS.get_environment("WS_URL").strip_edges()
		if not env_ws.is_empty():
			return env_ws
	var ps_ws = ProjectSettings.get_setting("application/ws_base_url", DEFAULT_WS_BASE_URL)
	var ps_ws_str := str(ps_ws).strip_edges()
	if not ps_ws_str.is_empty():
		return ps_ws_str
	return DEFAULT_WS_BASE_URL

# Provider futuro para Fase 3 opção A — mantém DEBUG_RAW_WS:=true hoje,
# permite desligar via env sem editar código: DEBUG_WS=0
static func is_debug_ws_enabled() -> bool:
	if OS.has_environment("DEBUG_WS"):
		return OS.get_environment("DEBUG_WS") != "0"
	return true
