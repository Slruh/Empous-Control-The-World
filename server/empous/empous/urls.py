from django.conf.urls import patterns, include, url
from django.conf import settings  

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    # Examples:
    url(r'^health/$','empous.views.health_check',name='health'),
    url(r'^$','empous.views.home', name='home'),
    url(r'^support$','empous.views.support', name='support'),
    url(r'^push/$','empous.views.push'),
    url(r'^pushall/$','empous.views.push_all'),
    url(r'^api/',include('api.urls')),
    url(r'^admin/', include(admin.site.urls)),
    url(r'', include('tokenapi.urls'))
)

if settings.DEBUG:
	urlpatterns += patterns('', (r'^media/(?P<path>.*)$', 'django.views.static.serve', {'document_root': settings.MEDIA_ROOT}),)
