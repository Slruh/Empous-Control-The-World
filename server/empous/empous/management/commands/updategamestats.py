from django.core.management.base import BaseCommand, CommandError
from empous.models import EmpousUser

class Command(BaseCommand):
    args = ''
    help = 'This command updates the computed stats for each user. This includes the game list, wins, losses, and draws. This will NOT perform push notifications.'

    def handle(self, *args, **options):
		users = EmpousUser.objects.all()
		for user in users:
			user.game_updated(do_push=False);