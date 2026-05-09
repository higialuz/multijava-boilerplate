from django.contrib import admin
from django.urls import path, re_path
from django.http import JsonResponse, FileResponse, Http404
from django.conf import settings
import os
import mimetypes

REACT_BUILD = os.path.join(settings.BASE_DIR.parent, 'frontend', 'build')

def api_health(request):
    return JsonResponse({"status": "ok", "message": "multijava API is running"})

def serve_react(request, path=''):
    file_path = os.path.join(REACT_BUILD, path) if path else None
    if file_path and os.path.isfile(file_path):
        content_type, _ = mimetypes.guess_type(file_path)
        return FileResponse(open(file_path, 'rb'), content_type=content_type)
    index = os.path.join(REACT_BUILD, 'index.html')
    return FileResponse(open(index, 'rb'), content_type='text/html')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', api_health),
    re_path(r'^(?P<path>.*)$', serve_react),
]
