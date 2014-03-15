from django.db import models
from django.contrib.auth.models import User
from iospush.models import IosPushDevice
from utils import dictify_games
from django.utils import simplejson as json
from django.conf import settings


class EmpousUser(User):
    def __unicode__(self):
        return str(self.first_name)
        
    def game_updated(self, do_push=True):
        current_playable_games = self.playable_games
        new_count = self.games.filter(current_player=self.id).exclude(victor__isnull=False).exclude(drawn_player__isnull=False).count()
        all_current_games = self.games.all().exclude(victor__isnull=False).exclude(drawn_player__isnull=False)

        self.playable_games = new_count
 
        if new_count > current_playable_games and do_push:
            if self.ios_device:
                if new_count == 1:
                    self.send_push_message("It's your turn in " + str(new_count) + " game.", new_count)
                else:
                    self.send_push_message("It's your turn in " + str(new_count) + " games.", new_count)

        self.generate_current_games_json(all_current_games)
        self.update_win_loss_draw()
        self.save()

    def update_win_loss_draw(self):
        self.wins = self.games.filter(victor=self.id).count()
        self.losses = self.games.exclude(victor__isnull=True).exclude(victor=self.id).count()
        self.draws = self.games.filter(drawn_player=self.id).count()

    def generate_current_games_json(self, games):
        game_dict = dictify_games(games,self)
        self.current_games_json = json.dumps({'gamelist':game_dict})

    def send_push_message(self, message, badge=0):
        if self.ios_device:
            self.ios_device.sendPushMessage(message,badge,"push.caf", self.using_lite_version)

    def can_play_more_games(self):
        return (not self.using_lite_version) or self.number_of_active_games() < settings.NUM_LITE_VERSION_GAMES

    def dict_friends(self):
        friends = {}
        for friend in self.friends.order_by('first_name','last_name').all():
            friends[friend.id] = friend.dictify_no_token()
            
        return friends

    def dictify_no_token(self):
        return {
            'empous_id': self.id,
            'username': self.username,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'can_play_more': self.can_play_more_games(),
            'matchmaking_enabled': self.matchmaking_enabled,
            'can_play_with_continents': self.can_play_with_continents
        }

    def number_of_active_games(self):
        return self.games.all().exclude(victor__isnull=False).exclude(drawn_player__isnull=False).count()

    def dictify(self, token):
        return {'empous_id':self.id, 'username':self.username, 'first_name':self.first_name, 'token':token, 'matchmaking_enabled': self.matchmaking_enabled}

    """
    facebook_id - the facebook id of the User
    invited - true if they have been invited by another user but haven't installed EmpousUser
    playable_games - the number of games where this player needs to make a move
    ios_device - the most recent ios device they used to connect with (used for push notifications)
    """
    facebook_id = models.BigIntegerField(null=True, unique=True)
    invited = models.BooleanField(default=True)
    matchmaking_enabled = models.BooleanField(default=False)
    using_lite_version = models.BooleanField(default=True)
    can_play_with_continents = models.BooleanField(default=False)
    playable_games = models.IntegerField(default=0)
    ios_device = models.ForeignKey(IosPushDevice,blank=True, null=True)
    current_games_json = models.TextField(blank=True,null=True)
    wins = models.IntegerField(default=0)
    losses = models.IntegerField(default=0)
    draws = models.IntegerField(default=0)
    friends = models.ManyToManyField('self',related_name='friends')
    last_seen_build = models.IntegerField(null=True,blank=True)

