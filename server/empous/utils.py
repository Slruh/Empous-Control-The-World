#Takes in a list of games 
def dictify_games(games, empous_user):
	game_list = dict()
	for game in games:
		game_stats = dict()

		game_stats["id"] = game.id

		if game.victor == empous_user:
			game_stats['isVictor'] = "yes"
		else:
			game_stats['isVictor'] = "no"

		if game.current_player == empous_user:
			game_stats['isTurn'] = "yes"
		else:
			game_stats['isTurn'] = "no"
		
		game_stats['current_player'] = game.current_player.first_name  
		#Go through the enemies to give more info
		players = list()
		for player in game.players.all():
			if player != empous_user:
				players.append(player.first_name)

		game_stats['enemies'] = players

		game_stats['screenshot_url'] = game.screenshot_file.url
		game_stats['json_state'] = game.json_serialized_game

		game_list[game.id] = game_stats
	return game_list

def join_with_commas_with_and(string_list):
	if len(string_list) == 1:
		return "".join(string_list)
	elif len(string_list) == 2:
		return " and ".join(string_list)
	else:
		joined_string = ", ".join(string_list[:-1])
		joined_string = joined_string + ", and " + string_list[-1] 
		return joined_string