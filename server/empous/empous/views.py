from django.http import HttpResponse
from django.template.loader import get_template
from django.shortcuts import render_to_response
from django.template import Context, RequestContext
from empous.models import EmpousUser
from django.utils import simplejson as json
from django.http import HttpResponseRedirect

def home(request):
	return HttpResponseRedirect("http://www.hurleyprog.com/empous/")

def support(request):
	return HttpResponseRedirect("http://www.hurleyprog.com/empous-support/")

def push(request):
	user_id = request.GET.get('user')
	message = request.GET.get('message')

	if user_id:
		empous_player = EmpousUser.objects.get(id=user_id)

		empous_player.send_push_message(message)

		return HttpResponse(json.dumps({'Success':'Push Sent'}), mimetype='application/json')

	else:
		return HttpResponse(json.dumps({'error':'No User Id'}), mimetype='application/json')

def push_all(request):
	message = request.GET.get('message')

	for user in EmpousUser.objects.all():
		user.send_push_message(message)
	
	return HttpResponse(json.dumps({'Success':'Push Sent'}), mimetype='application/json')

def health_check(request):
	return HttpResponse("<html><body>I'm Alive!</body></html>")