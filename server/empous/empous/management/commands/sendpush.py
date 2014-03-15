from django.core.management.base import BaseCommand, CommandError
from empous.models import EmpousUser
from django.db.models import Q

class Command(BaseCommand):
    args = 'usernameOrEmail message'
    help = 'This commands lets you send a push message to a player by email or username'

    def handle(self, *args, **options):
        if len(args) != 2:
            self.stdout.write('Not enough arguments')
            return 

        username = args[0]
        message = args[1]
        try:
            user = EmpousUser.objects.get(Q(username__iexact=username)|Q(email__iexact=username))
            if user.ios_device:
                user.send_push_message(message)
                self.stdout.write('Message sent')
            else:
                self.stdout.write('User has not enabled push notifications')
                
        except EmpousUser.DoesNotExist:
            self.stdout.write('Could not find a user by username or email')

