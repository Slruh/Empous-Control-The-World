from django.http import HttpResponse, HttpResponseBadRequest
from api.models import Game
from utils import dictify_games
from empous.models import EmpousUser
from iospush.models import IosPushDevice
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password
from tokenapi.tokens import token_generator
from tokenapi.decorators import token_required
from django.views.decorators.csrf import csrf_exempt, csrf_protect
from django.conf import settings
from django.db.models import Q
from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.core.mail import EmailMessage
from django.db import transaction
from api.signals import game_updated
from datetime import date, timedelta
from django.utils import timezone


import urllib
import string
import random
import sys
import base64
import json

EMPOUS_ID = "380531958645299"
MIN_EMPOUS_BUILD = 0
MIN_LIGHT_BUILD = 0

class StatusCodes:
    SUCCESS              = {'result': 0}
    USERNAME_NEEDED      = {'result': 1, 'message': "You need to supply a username to create an account."}
    APP_VERSION_OUTDATED = {'result': 2, 'message': "Your version of Empous is too outdated. You must update your version before playing."}
    USERNAME_TAKEN       = {'result': 3, 'message': "The username you have chosen is already taken by another player."}
    BAD_CREDENTIALS      = {'result': 4, 'message': "You username and/or password is incorrect."}
    FB_NOT_INSTALLED     = {'result': 5, 'message': "You have not authorized Empous to access your facebook account."}
    EMPOUS_CODE_ERROR    = {'result': 6, 'message': "The application ID returned from Facebook does not belong to Empous or you have not authorized Empous."} 
    FIELDS_MISSING       = {'result': 7, 'message': "All fields are required."}
    USERNAME_AVAILABLE   = {'result': 8}
    USERNAME_UNAVAILABLE = {'result': 9}
    TOKEN_INVALID        = {'result': 10, 'message':"The token is invalid"}
    USER_DOESNT_EXIST    = {'result': 11, 'message':"There is no user"}
    CANT_PLAY_MORE_GAMES = {'result': 12, 'message':"The user can't play in any more games"}

"""
    Called when a user logs into the game.
"""
@csrf_exempt
def new_user(request):
    facebook_token = request.POST.get('facebookToken',None)
    desired_username = request.POST.get('username',None)
    password = request.POST.get('password',None)
    first_name = request.POST.get('first_name',None)
    last_name = request.POST.get('last_name',None)
    email = request.POST.get('email', None)
    ios_token = request.POST.get('iostoken',None)
    empous_build = int(request.POST.get('build',-1))
    using_lite_version = request.POST.get('isEmpousLite', "1")
    can_play_with_continents = request.POST.get('canPlayWithContinents', "0")

    #Check to see if the empous build is supplied is greater than the minimum version
    if using_lite_version == "0":
        if empous_build < MIN_EMPOUS_BUILD:
            return HttpResponse(json.dumps(StatusCodes.APP_VERSION_OUTDATED), mimetype='application/json') 
    else: 
        if empous_build < MIN_LIGHT_BUILD:
            return HttpResponse(json.dumps(StatusCodes.APP_VERSION_OUTDATED), mimetype='application/json') 
    
    #Handle facebook or empous login
    if facebook_token:
        return handle_facebook_user(ios_token,facebook_token, desired_username, empous_build, using_lite_version, can_play_with_continents) 
    else:
        return handle_empous_user(ios_token, desired_username, password, first_name,last_name, email, empous_build, using_lite_version, can_play_with_continents)

"""
    This also handles invited facebook users, but inviting a facebook user has been disabled in the current version.
"""
def handle_facebook_user(iostoken, facebook_token, desired_username, empous_build, using_lite_version, can_play_with_continents):
    #Loggin in via Facebook token
    graph_app = "https://graph.facebook.com/app?access_token="+facebook_token
    fb_response_app = urllib.urlopen(graph_app)
    app_response = json.loads(fb_response_app.read())
    
    #Check to see if query was successful and if this is an Empous Token
    if app_response.has_key('id') and app_response['id'] == EMPOUS_ID:
        graph_url = "https://graph.facebook.com/me?fields=installed,id,first_name,last_name,email,username&access_token="+facebook_token
        fb_response = urllib.urlopen(graph_url)
        responseText = fb_response.read()
        response = json.loads(responseText)

        if response.has_key('installed'):

            #Check if the facebook user exists already. If they don't the username must be specified in order to create the user.
            if EmpousUser.objects.filter(facebook_id=response['id']).exists() or desired_username:

                #Check to see if email is provided...some people block this
                email = response.get('email','')
                
                #Get the user by facebook ID or create one if doesn't exit
                user, userCreated = EmpousUser.objects.get_or_create(
                    facebook_id=response['id'],
                    defaults={
                        'password':generate_password(),
                        'invited':False,
                        'username':desired_username,
                        'first_name':response['first_name'],
                        'last_name':response['last_name'],
                        'email':email,
                        'last_seen_build':empous_build
                    }
                )
    
                #If a user was invited then update the information
                # Make sure they supplied a username 
                if user.invited:
                    if desired_username:
                        user.invited = False
                        user.username = desired_username
                        user.first_name = response['first_name']
                        user.last_name = response['last_name']
                        user.email = email
                        user.last_seen_build = empous_build
                        user.save()
                    else:
                        return HttpResponse(json.dumps(StatusCodes.USERNAME_NEEDED),mimetype='application/json')


                #Check to see if the iostoken was specified for push notifications
                if iostoken:
                    device, wasCreated = IosPushDevice.objects.get_or_create(ios_token=iostoken)
                    user.ios_device = device
                    user.save()

                #Check app version - only care if not using the lite_version
                if using_lite_version == "0":
                    user.using_lite_version = False
                    user.save()

                #Check to see if the user is playing with a new version of Empous that supports continents
                if can_play_with_continents == "1":
                    user.can_play_with_continents = True
                    user.save()

                #Get the facebook friends of the user and add them to the users list of friends
                friends_url = "https://graph.facebook.com/me/friends?fields=installed,name,first_name,last_name&access_token=" + facebook_token
                fb_response = urllib.urlopen(friends_url)
                responseText = fb_response.read()
                response = json.loads(responseText)
                friends = response['data']

                #Friends now contains a list of dictionaries the keys are 
                #"first_name","last_name","name","id" where id is the facebook id
                #may have the key "installed" if they have empous. These are the ones we care about.
                for friend in friends:
                    if "installed" in friend:
                        try:
                            #Get the empous user id using the facebook id
                            empous_player = EmpousUser.objects.get(facebook_id=friend['id'])
                            user.friends.add(empous_player)

                            #Notify your friend that you have empous now.
                            if userCreated:
                                empous_player.send_push_message("Your Facebook friend, %s (%s), has joined Empous" % (user.first_name, user.username), user.playable_games)

                        except EmpousUser.DoesNotExist:
                            #This can happen when the user installed empous but I wiped the DB and they haven't reconnected
                            empous_player = invite_user(friend['id'],friend['first_name'],friend['last_name'])
                            user.friends.add(empous_player)

                #save the user, generate a token,       
                user.save()
                token = token_generator.make_token(user)
                return HttpResponse(json.dumps({'result': 0, 'token':token, 'empous_id':user.id, 'username':user.username, 'first_name':user.first_name, 'matchmaking_enabled':user.matchmaking_enabled}), mimetype='application/json')
            else:
                return HttpResponse(json.dumps(StatusCodes.USERNAME_NEEDED), mimetype='application/json')
        else:
            return HttpResponse(json.dumps(StatusCodes.FB_NOT_INSTALLED), mimetype='application/json')
    else:
        return HttpResponse(json.dumps(StatusCodes.EMPOUS_CODE_ERROR), mimetype='application/json') 

"""
    Handles creating an Empous account
"""
@csrf_exempt
def handle_empous_user(iostoken, username, password, first_name, last_name, email, empous_build, using_lite_version, can_play_with_continents):
    #Make sure there is something defined all the arguments
    if not (username and password and first_name and last_name and email):
        return HttpResponse(json.dumps(StatusCodes.FIELDS_MISSING), mimetype='application/json')

    #Make sure the username does not exists first
    if User.objects.filter(username__iexact=username).exists():
        return HttpResponse(json.dumps({'error':'Username is not available'}), mimetype='application/json') 
    
    user, wasCreated = EmpousUser.objects.get_or_create(
        username=username.lower(),
        defaults={
            'password':make_password(password),
            'invited':False,
            'first_name':first_name,
            'last_name':last_name,
            'last_seen_build':empous_build,
            'username':username,
            'email':email
        }
    )

    #Check to see if the iostoken was specified for push notifications
    if iostoken:
        device, wasCreated = IosPushDevice.objects.get_or_create(ios_token=iostoken)
        user.ios_device = device
        user.save()

    #Check app version - only care if not using the lite_version
    if using_lite_version == "0":
        user.using_lite_version = False
        user.save()

    #Check to see if the user is playing with a new version of Empous that supports continents
    if can_play_with_continents == "1":
        user.can_play_with_continents = True
        user.save()

    #Create a token for the user
    token = token_generator.make_token(user)
    return HttpResponse(json.dumps({'result': 0, 'token':token, 'empous_id':user.id, 'username':user.username, 'first_name':user.first_name, 'matchmaking_enabled':user.matchmaking_enabled}), mimetype='application/json')

def invite_user(facebook_id, first_name, last_name):
    user, created = EmpousUser.objects.get_or_create(facebook_id=facebook_id,defaults={'username':facebook_id,'first_name':first_name,'last_name':last_name,'password':generate_password(),'invited':True})
    return user

@csrf_exempt
def generate_token(request):
    username_or_email = request.POST.get('username_or_email')

    #Check to see if we can find a valid user 
    try:
        empous_user = User.objects.get(Q(username__iexact=username_or_email)|Q(email__iexact=username_or_email))
        token_gen = PasswordResetTokenGenerator()

        reset_token = token_gen.make_token(empous_user)
        reset_message = "A password reset token has been requested for your account. Your token is : %s" % reset_token
        email = EmailMessage("Empous: Password Reset Token", reset_message, to=[empous_user.email], from_email="support@empous.com")
        email.send()

        return HttpResponse(json.dumps({'response_message':'A token has been emailed to "%s"' % empous_user.email}), mimetype='application/json')

    except User.DoesNotExist:
        return HttpResponse(json.dumps({'response_message':'Could not find an empous user with a username or email of "%s"' % username_or_email}), mimetype='application/json')

@csrf_exempt
def reset_password(request):
    token = request.POST.get('token')
    username_or_email = request.POST.get('username_or_email')
    password = request.POST.get('password')

    try:
        empous_user = User.objects.get(Q(username__iexact=username_or_email)|Q(email__iexact=username_or_email))
        token_gen = PasswordResetTokenGenerator()
        if token_gen.check_token(empous_user, token):
            empous_user.set_password(password)
            empous_user.save()
            return HttpResponse(json.dumps(StatusCodes.SUCCESS), mimetype='application/json')
        else:
            return HttpResponse(json.dumps(StatusCodes.TOKEN_INVALID), mimetype='application/json')

    except User.DoesNotExist:
        return HttpResponse(json.dumps(StatusCodes.USER_DOESNT_EXIST), mimetype='application/json')

@token_required
def invite_by_username_or_email(request):
    invited_username_or_email = request.POST.get('username',None)
    inviting_user = request.POST.get('user',None)
    inviting_user = EmpousUser.objects.get(id=inviting_user)

    if not invited_username_or_email:
        return HttpResponse(json.dumps({'error':'No player with the username'}), mimetype='application/json')

    try:
        invited_user = EmpousUser.objects.get(Q(username__iexact=invited_username_or_email)|Q(email__iexact=invited_username_or_email))
        if invited_user:
            if invited_user == inviting_user:
                return HttpResponse(json.dumps({'error':"You can't invite yourself"}), mimetype='application/json')

            inviting_user.friends.add(invited_user)
            inviting_user.save()

            return HttpResponse(json.dumps({'success':inviting_user.dict_friends(),'invited_user':"%s %s (%s)" % (invited_user.first_name, invited_user.last_name, invited_user.username)}), mimetype='application/json') 
    except EmpousUser.DoesNotExist:
        pass

    return HttpResponse(json.dumps({'error':'No player with the username'}), mimetype='application/json')

"""
    Called to login a user using empous credentials
"""
@csrf_exempt
def login_empous_user(request):
    username_or_email = request.POST.get('username_or_email',None)
    password = request.POST.get('password',None)
    token = request.POST.get('token',None)
    user = request.POST.get('user',None)
    empous_build = request.POST.get('build',-1)
    ios_token = request.POST.get('iostoken', None)
    using_lite_version = request.POST.get('isEmpousLite', "1")
    can_play_with_continents = request.POST.get('canPlayWithContinents', "0")

    #Check to see if the empous build is supplied is greater than the minimum version
    if empous_build < MIN_EMPOUS_BUILD:
        return HttpResponse(json.dumps(StatusCodes.APP_VERSION_OUTDATED), mimetype='application/json')

    #Check to see if the token is valid, if it is get a new one
    try:
        user = EmpousUser.objects.get(pk=user)
        if token_generator.check_token(user, token):

            #Check app version - only care if not using the lite_version
            if using_lite_version == "0":
                user.using_lite_version = False
                user.save()

            #Check to see if the user is playing with a new version of Empous that supports continents
            if can_play_with_continents == "1":
                user.can_play_with_continents = True
                user.save()

            #Check to see if the iostoken was specified for push notifications
            if ios_token:
                device, wasCreated = IosPushDevice.objects.get_or_create(ios_token=iostoken)
                user.ios_device = device
                user.save()

            #Generate a new token for the user
            token = token_generator.make_token(user)
            return HttpResponse(json.dumps(dict(StatusCodes.SUCCESS.items() + user.dictify(token).items())), mimetype='application/json')
    
    except User.DoesNotExist:
        pass

    if username_or_email and password:
        try:
            empous_user = EmpousUser.objects.get(Q(username__iexact=username_or_email)|Q(email__iexact=username_or_email))

            #Check app version - only care if not using the lite_version
            if using_lite_version == "0":
                empous_user.using_lite_version = False
                empous_user.save()

            #Check to see if the user is playing with a new version of Empous that supports continents
            if can_play_with_continents == "1":
                empous_user.can_play_with_continents = True
                empous_user.save()

            #Check to see if the iostoken was specified for push notifications
            if ios_token:
                device, wasCreated = IosPushDevice.objects.get_or_create(ios_token=iostoken)
                user.ios_device = device
                user.save()

            if password and authenticate(username=empous_user.username, password=password):
                #Get a token for the user
                token = token_generator.make_token(empous_user)
                return HttpResponse(json.dumps(dict(StatusCodes.SUCCESS.items() + empous_user.dictify(token).items())), mimetype='application/json')
        except EmpousUser.DoesNotExist:
            pass

    return HttpResponse(json.dumps(StatusCodes.BAD_CREDENTIALS), mimetype='application/json')

"""
    Checks to see if a username is available.
    Note that the lookup is case insensitive
"""
@csrf_exempt
def check_username_free(request):
    desired_username = request.POST.get('username', None)

    if desired_username and User.objects.filter(username__iexact=desired_username.lower()).exists():
        return HttpResponse(json.dumps(StatusCodes.USERNAME_UNAVAILABLE), mimetype='application/json') 

    return HttpResponse(json.dumps(StatusCodes.USERNAME_AVAILABLE), mimetype='application/json') 

"""
    Gets all the friends for a given player
"""
@token_required
def get_friends_for_user(request):
    user_id = request.POST.get('user',None)
    user = EmpousUser.objects.get(id=user_id)
    return HttpResponse(json.dumps({'success':user.dict_friends()}), mimetype='application/json') 

@token_required
def can_create_games(request):
    user_id = request.POST.get('user',None)
    user = EmpousUser.objects.get(id=user_id)

    if user.can_play_more_games():
        return HttpResponse(json.dumps(StatusCodes.SUCCESS), mimetype='application/json')
    else:
        return HttpResponse(json.dumps(StatusCodes.CANT_PLAY_MORE_GAMES), mimetype='application/json')

"""
    Called to create a new Empous game
"""
@token_required
@csrf_exempt
def create_game(request):
    json_state = request.POST.get('json_state', None)
    screenshot_file = request.FILES.get('screenshot_file',None)
    players = request.POST.get('players',None)
    players = json.loads(players)
    if players and json_state and screenshot_file:

        #Get the creating player
        creating_player = EmpousUser.objects.get(id=players[0])

        #Create a new game
        game = Game.objects.create()
        game.current_player = creating_player
        game.creating_player = creating_player
        game.json_serialized_game = json_state;

        #Verify that each user exists
        for player in players:
            try:
                user = EmpousUser.objects.get(id=player)
                game.players.add(user)
            except EmpousUser.DoesNotExist:
                return HttpResponse(json.dumps({'error':'Could not find a user'}), mimetype='application/json')

        #Save the screen shots
        game.screenshot_file = screenshot_file

        #If you get here, then all the users exist in the system add are added
        game.saveAndPossiblyPush()

        #Record the game id in the json and save again
        game_state = json.loads(json_state)
        game_state['game_id'] = game.id
        game.json_serialized_game = json.dumps(game_state)
        game.saveAndPossiblyPush()

        return HttpResponse(json.dumps({'game_id':game.id,'players':players}),mimetype='application/json')

    return HttpResponse(json.dumps({'error':'Missing arguments'}), mimetype='application/json') 
        
"""
    Called both to asynchronously update the game and update the turns
    The player number is used to discard out of order requests due to network communication
"""
@token_required
@csrf_exempt
def update_game(request):
    game_id = request.POST.get('game_id',None)
    player = request.POST.get('player',None)
    json_state = request.POST.get('json_state', None)
    screenshot_file = request.FILES.get('screenshot_file',None)
    
    if game_id and json_state and screenshot_file and player:
        with transaction.commit_manually():
            try:
                #Get the game using the id 
                game = Game.objects.select_for_update().get(id=game_id)
        
                #Verify that the current player matches the db, otherwise this request is out of 
                #order and should be discarded
                empous_player = EmpousUser.objects.get(id=player)
                if game.current_player == empous_player:
    
                    #Open the json state and get the current player use it to update the db
                    game_state = json.loads(json_state)
                    next_player_id = game_state['current_player_turn']
                    next_empous_player = EmpousUser.objects.get(id=next_player_id)
                    game.current_player = next_empous_player
        
                    game.screenshot_file = screenshot_file
                    game.json_serialized_game = json_state;
                    game.saveAndPossiblyPush(True)
                    transaction.commit()

                    return HttpResponse(json.dumps({'success':'Game updated'}), mimetype='application/json') 
                else:
                    transaction.rollback()
                    return HttpResponse(json.dumps({'error':'Discarding update, you are not the current player'}), mimetype='application/json')
    
            except Game.DoesNotExist:
                transaction.rollback()
                return HttpResponse(json.dumps({'error':'Game does not exist'}), mimetype='application/json') 
            except EmpousUser.DoesNotExist:
                transaction.rollback()
                return HttpResponse(json.dumps({'error':'Empous User does not exist'}), mimetype='application/json') 
    else:
        return HttpResponse(json.dumps({'error':'Missing necessary arguemnts'}), mimetype='application/json') 

"""
    Called when a game is over and a player has won, this is a synchronous request
"""
@token_required
def completed_game(request):
    game_id = request.POST.get('game_id',None)
    winning_player = request.POST.get('winning_player',None)
    json_state = request.POST.get('json_state', None)
    screenshot_file = request.FILES.get('screenshot_file',None)
    
    if game_id and winning_player and json_state and screenshot_file:
        with transaction.commit_manually():
            try:
                #Get the game using the id 
                game = Game.objects.select_for_update().get(id=game_id)
    
                #Get the account for the new current player 
                empous_player = EmpousUser.objects.get(id=winning_player)
    
                for player in game.players.all():
                    if player != empous_player:
                        player.send_push_message(str(empous_player.first_name) + " has defeated you.", player.playable_games)
    
                game.victor = empous_player
                game.current_player = empous_player
                game.screenshot_file = screenshot_file
                game.json_serialized_game = json_state;
                game.saveAndPossiblyPush()
                
                transaction.commit()
                return HttpResponse(json.dumps({'success':'Game finished'}), mimetype='application/json') 
            except Game.DoesNotExist:
                transaction.rollback()
                return HttpResponse(json.dumps({'error':'Game does not exist'}), mimetype='application/json') 
            except EmpousUser.DoesNotExist:
                transaction.rollback()
                return HttpResponse(json.dumps({'error':'Empous User does not exist'}), mimetype='application/json') 
    else:
        return HttpResponse(json.dumps({'error':'Missing necessary arguemnts'}), mimetype='application/json') 

"""
    Get the list of games for the player with the supplied token
"""
@token_required
@csrf_exempt
def game_list(request):
    #Using the user id get the game list
    user_id = request.POST.get('user')
    empous_user = EmpousUser.objects.get(id=user_id)

    #The if should always pass
    if empous_user.current_games_json:
        return HttpResponse(empous_user.current_games_json, mimetype='application/json')
    else:
        #Create a dictionary with all the game and whether it is the users term
        game_dict = dictify_games(empous_user.games.all().filter(victor__isnull=True),empous_user)

        return HttpResponse(json.dumps({'gamelist':game_dict}), mimetype='application/json') 

"""
    Get the last 5 completed games for a player
"""
@token_required
@csrf_exempt
def last_5_completed_games(request):
        #Using the user id get the game list
    user_id = request.POST.get('user')
    empous_user = EmpousUser.objects.get(id=user_id)

    #Create a dictionary with all the game and whether it is the users term
    game_dict = dictify_games(empous_user.games.all().filter(victor__isnull=False).order_by('-last_updated')[:5],empous_user)

    return HttpResponse(json.dumps({'gamelist':game_dict}), mimetype='application/json') 

"""
    Returns the number of playable games for a player
"""
@token_required
def number_playable_games(request):
    #Using the user id get the game list
    user_id = request.POST.get('user')
    empous_user = EmpousUser.objects.get(id=user_id)

    num_games = empous_user.playable_games

    return HttpResponse(json.dumps({'num_games':num_games}), mimetype='application/json') 

"""
    Generates a random password needed to create users
"""
def generate_password():
    #Generate a random password for now
    char_set = string.ascii_uppercase + string.digits
    passwordTmp = ''.join(random.sample(char_set,12))   
    return passwordTmp

@token_required
def change_matchmaking(request):
    user_id = request.POST.get('user')

    matchmaking_setting = request.POST.get('matchmaking_enabled', "0")
    matchmaking_enabled = False

    if (matchmaking_setting == "1"): 
        matchmaking_enabled = True

    empous_user = EmpousUser.objects.get(id=user_id)
    empous_user.matchmaking_enabled = matchmaking_enabled
    empous_user.save()

    return HttpResponse(json.dumps(StatusCodes.SUCCESS), mimetype='application/json')

@token_required
def random_empous_player(request):
    user_id = request.POST.get('user')

    # Criteria for random match, 
    # Must have logged in within the past 2 days
    # Must be enabled for random matchmaking
    # Must not be the player making the request
    # Must have game slots available if playing lite version

    possible_players = EmpousUser.objects.filter(last_login__gte=timezone.now() - timedelta(1)).filter(matchmaking_enabled=True).exclude(id=user_id)
    if len(possible_players) == 0:
        return HttpResponse(json.dumps(StatusCodes.USER_DOESNT_EXIST), mimetype='application/json')
    else:
        #Filter out lite players that have maxed out their games
        possible_players_filtered = [player for player in possible_players if player.can_play_more_games() and player.number_of_active_games() < 10]

        if len(possible_players_filtered) == 0:
            return HttpResponse(json.dumps(StatusCodes.USER_DOESNT_EXIST), mimetype='application/json')

        random_player = random.choice(possible_players_filtered)
        return HttpResponse(json.dumps(dict(StatusCodes.SUCCESS.items() + random_player.dictify_no_token().items())), mimetype='application/json')

        
    
