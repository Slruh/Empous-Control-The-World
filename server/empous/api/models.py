from django.db import models
from empous.models import EmpousUser
import time
from django.db.models import signals

class Game(models.Model):
	def __unicode__(self):
		return str(self.id)
	
	def serialized_filename(instance, filename):
		return 'maps/%d-%f.em' % (instance.id,time.time())

	def serialized_screenshot(instance, filename):
		return 'screenshots/%d-%f.png' % (instance.id,time.time())

	def saveAndPossiblyPush(instance, sendPushMessages=False):
		#Save the instance
		instance.save()

		#Update the game stats and push if necessary
		for user in instance.players.all():
			user.game_updated(sendPushMessages)
		
		
	json_serialized_game = models.TextField()
	screenshot_file = models.FileField(upload_to=serialized_screenshot)

	created = models.DateTimeField(auto_now_add=True)
	last_updated = models.DateTimeField(auto_now=True)
	last_nudge = models.DateTimeField(auto_now=True, null=True)

	#Player Foreign Keys
	creating_player = models.ForeignKey(EmpousUser, related_name='created_games', blank=True, null=True)
	current_player = models.ForeignKey(EmpousUser,related_name='currentplayer', blank=True, null=True)
	victor = models.ForeignKey(EmpousUser,related_name='victories', blank=True, null=True)
	drawn_player = models.ForeignKey(EmpousUser, blank=True, null=True)
	players = models.ManyToManyField(EmpousUser,related_name='games')

