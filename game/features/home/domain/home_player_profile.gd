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
	return profile


func xp_compact() -> String:
	return "%d XP" % xp
