from django.db.models import signals
from django.dispatch import dispatcher
import sys

def game_updated(sender, instance, signal, *args, **kwargs):
	"""
	Runs through the users associated with a game and updates them
	"""
	for user in instance.players.all():
		doPush = True
		if user == instance.current_player:
			doPush = False

		user.game_updated(doPush)

