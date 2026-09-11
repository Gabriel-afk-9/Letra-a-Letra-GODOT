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
	p_total_matches: int = 0
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
		int(data.get("total_matches", 0))
	)
	
func is_valid() -> bool:
	return not email.is_empty()

func copy() -> User:
	return User.new(
		id, email, nickname, level, experience,
		coins, gems, total_wins, win_streak, total_matches
	)
