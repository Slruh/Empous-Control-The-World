from django.core.management.base import BaseCommand, CommandError
from api.models import Game
from django.utils import timezone
from utils import join_with_commas_with_and

class Command(BaseCommand):
    args = ''
    help = 'This command will run through all unfinished (no victor/no drawn player) and check to see if someone has taken more than 3 days to take a turn.'

    def handle(self, *args, **options):
        self.stdout.write("Starting the check for draws...")
        games = Game.objects.exclude(victor__isnull=False).exclude(drawn_player__isnull=False)
        for game in games:
            current_player = game.current_player

            now = timezone.now()

            #Check to see if the last updated time is >=5 days
            diffLastUpdated = now - game.last_updated
            if diffLastUpdated.days >= 5:
                self.stdout.write('Game with id "%d" will be drawn.' % game.id)

                #Mark the current player as the drawn player
                game.drawn_player = current_player
                game.save()

                #Send push notifications
                enemies = self.get_enemies_for_game(game, current_player)
                current_player.send_push_message("You have forfeited your game with " + join_with_commas_with_and(enemies), current_player.playable_games)

                for enemy in enemies:
                    enemy.send_push_message(current_player.first_name + " has forfeited a game with you", enemy.playable_games)
                continue

            diffLastNudged = now - game.last_nudge
            if diffLastNudged.days >= 1:                
                #Enemies without the current player
                enemies = self.get_enemies_for_game(game, current_player)

                #Create the nudge message
                message = join_with_commas_with_and(enemies)
                if len(enemies) == 1:
                    message = message + " is "
                else:
                    message = message + " are "
                message = message + "waiting for you to take your turn."

                if diffLastUpdated.days >= 4:
                    message = message + " Last chance."

                current_player.send_push_message(message, current_player.playable_games)
                Game.objects.filter(pk=game.id).update(last_nudge=timezone.now())
                self.stdout.write('Game with id "%d" nudged with message %s' % (game.id, message))
                continue

        self.stdout.write("Done.")

    def get_enemies_for_game(self, game, current_player):
        enemies = []
        for empous_user in game.players.all():
            if empous_user != current_player:
                enemies.append(empous_user.first_name)
        return enemies









