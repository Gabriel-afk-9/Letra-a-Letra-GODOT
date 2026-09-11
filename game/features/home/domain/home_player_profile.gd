extends RefCounted
class_name HomePlayerProfile

# Perfil exibido na Home, montado a partir do GET /user/me
# (GetMyProfileResponse). Sem valores mockados: campos ausentes na
# resposta assumem zero.

var nickname: String = ""
var level: int = 0
var xp: int = 0
var coins: int = 0
var gems: int = 0
var wins: int = 0
var streak: int = 0
var matches: int = 0
var ranking_points: int = 0
var has_banner: bool = false
var equipped_avatar: String = ""
var equipped_frame: String = ""
var equipped_banner: String = ""


static func from_user(user: User) -> HomePlayerProfile:
	var profile := HomePlayerProfile.new()
	if user == null:
		return profile
	profile.nickname = user.nickname
	profile.level = user.level
	profile.xp = user.experience
	profile.coins = user.coins
	profile.gems = user.gems
	profile.wins = user.total_wins
	profile.streak = user.win_streak
	profile.matches = user.total_matches
	profile.ranking_points = user.ranking_points
	profile.has_banner = user.has_banner
	profile.equipped_avatar = user.equipped_avatar
	profile.equipped_frame = user.equipped_frame
	profile.equipped_banner = user.equipped_banner
	return profile


func xp_compact() -> String:
	return "%d XP" % xp
