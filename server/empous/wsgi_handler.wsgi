import os
import sys
 
path = '/srv/www/empous-website/empous/'
if path not in sys.path:
    sys.path.insert(0, '/srv/www/empous-website/empous/')
 
os.environ['DJANGO_SETTINGS_MODULE'] = 'empous.settings'
 
import django.core.handlers.wsgi
application = django.core.handlers.wsgi.WSGIHandler()
