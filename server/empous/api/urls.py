from django.conf.urls import patterns, include, url

urlpatterns = patterns('',
	url(r'join/$','api.views.new_user'), #Creates and logs in a user
	url(r'login/$','api.views.login_empous_user'), #logs in an empous user
	url(r'generatetoken/$', 'api.views.generate_token'),
	url(r'resetpassword/$', 'api.views.reset_password'),
	url(r'invite/$','api.views.invite_by_username_or_email'), 
	url(r'check/$','api.views.check_username_free'), 
	url(r'friends/$','api.views.get_friends_for_user'),#Returns all the empous users a player has played with or are FB friends with
	url(r'create/$','api.views.create_game'),
	url(r'update/$','api.views.update_game'),
	url(r'complete/$','api.views.completed_game'),
	url(r'gamelist/$','api.views.game_list'),
	url(r'numplayablegames/$','api.views.number_playable_games'),
	url(r'completelist/$','api.views.last_5_completed_games'),
	url(r'cancreategame/$','api.views.can_create_games'),
	url(r'changematchmaking/$','api.views.change_matchmaking'),
	url(r'randomplayer/$','api.views.random_empous_player')
)