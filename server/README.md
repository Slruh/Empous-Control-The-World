#Running Django Locally For Developement

#Installing Empous Webserver Using Mod_wsgi on Production Server

##Prereqs
Make sure you have python 2.7.3 installed and are running on Ubuntu server

##Installing Apache2
```
sudo apt-get update
sudo apt-get install apache2
sudo apt-get install libapache2-mod-wsgi
```

##Installing Django and Other Needed Modules

```
sudo apt-get install python-django
sudo apt-get install python-mysqldb
sudo apt-get install python-setuptools
sudo easy_install pip
sudo pip install django-storages
sudo pip install boto --upgrade
```

##Checkout the Code
On the server create the 'www' directory.

```
sudo mkdir /srv/www/
cd /srv/www/
```

The code is on github `git clone https://github.com/Slruh/Empous-Control-The-World.git`. Clone the repo with the following command:

```
sudo git clone git clone https://github.com/Slruh/Empous-Control-The-World.git empous-website
```

You need to change settings.py in the empous folder to point to the database you want to use. Defaults to a local sqlite3 directory.

Empous also uses a static directory and media directory. Create them with the following command.

```
sudo mkdir empous-static
sudo mkdir empous-media
sudo chgrp -R www-data /srv/www/
sudo chmod -R g+w /srv/www/
```

Now go to `cd /etc/apache2/sites-available/`. In this directory you should run `emacs empous`, or use your favorite editor to create the file.
In this new file add the following:

```
<VirtualHost *:80>
    ServerAdmin youremail@domain.com
    ServerName www.domain.com
    ServerAlias domain.com
    # Django settings

    Alias /static/ /srv/www/empous-static/
    Alias /media/ /srv/www/empous-media/

    <Directory /srv/www/empous-website/empous/>
        Order allow,deny
        Allow from all
    </Directory>

    WSGIDaemonProcess www.domain.com user=www-data group=www-data processes=5 threads=1
    WSGIProcessGroup www.domain.com
    WSGIScriptAlias / /srv/www/empous-website/empous/wsgi_handler.wsgi

</VirtualHost>
```

Run the following commands to activate the site
```
sudo a2ensite empous
sudo rm /etc/apache2/sites-enabled/000-default
sudo service apache2 restart
```
