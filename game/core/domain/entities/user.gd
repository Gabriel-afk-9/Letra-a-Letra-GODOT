class_name User

var id: String
var email: String
var nickname: String
var level: int = 0
var experience: int = 0
var coins: int = 0
var gems: int = 0
var total_wins: int = 0
var win_streak: int = 0
var total_matches: int = 0
var ranking_points: int = 0
var has_banner: bool = false
var equipped_avatar: String = ""
var equipped_frame: String = ""
var equipped_banner: String = ""

func _init(
	p_id: String,
	p_email: String,
	p_nickname: String,
	p_level: int = 0,
	p_experience: int = 0,
	p_coins: int = 0,
	p_gems: int = 0,
	p_total_wins: int = 0,
	p_win_streak: int = 0,
	p_total_matches: int = 0,
	p_ranking_points: int = 0,
	p_has_banner: bool = false,
	p_equipped_avatar: String = "",
	p_equipped_frame: String = "",
	p_equipped_banner: String = ""
):
	id = p_id
	email = p_email
	nickname = p_nickname
	level = p_level
	experience = p_experience
	coins = p_coins
	gems = p_gems
	total_wins = p_total_wins
	win_streak = p_win_streak
	total_matches = p_total_matches
	ranking_points = p_ranking_points
	has_banner = p_has_banner
	equipped_avatar = p_equipped_avatar
	equipped_frame = p_equipped_frame
	equipped_banner = p_equipped_banner

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"email": email,
		"nickname": nickname,
		"level": level,
		"experience": experience,
		"coins": coins,
		"gems": gems,
		"total_wins": total_wins,
		"win_streak": win_streak,
		"total_matches": total_matches,
		"ranking_points": ranking_points,
		"has_banner": has_banner,
		"equipped_avatar": equipped_avatar,
		"equipped_frame": equipped_frame,
		"equipped_banner": equipped_banner,
	}

static func from_dictionary(data: Dictionary) -> User:
	return User.new(
		str(data.get("id", "")),
		str(data.get("email", "")),
		str(data.get("nickname", "")),
		int(data.get("level", 0)),
		int(data.get("experience", 0)),
		int(data.get("coins", 0)),
		int(data.get("gems", 0)),
		int(data.get("total_wins", 0)),
		int(data.get("win_streak", 0)),
		int(data.get("total_matches", 0)),
		int(data.get("ranking_points", 0)),
		bool(data.get("has_banner", false)),
		str(data.get("equipped_avatar", "")),
		str(data.get("equipped_frame", "")),
		str(data.get("equipped_banner", ""))
	)
	
func is_valid() -> bool:
	return not email.is_empty()

func copy() -> User:
	return User.new(
		id, email, nickname, level, experience,
		coins, gems, total_wins, win_streak, total_matches,
		ranking_points, has_banner,
		equipped_avatar, equipped_frame, equipped_banner
	)
