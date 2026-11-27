@echo off
setlocal
cd /d "%~dp0"

python manage.py migrate
if errorlevel 1 exit /b 1

python manage.py runserver 127.0.0.1:8000
