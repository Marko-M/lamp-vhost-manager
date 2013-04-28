LAMP virtual host manager
==================

This script should somewhat simplify handling development virtual hosts on your Debian based Linux operating system.

Usage
-----
This script requires root access.

./lamp-vhost-manager.sh OPTIONS

OPTIONS:
-h      Show this message
-m      Mode [add|remove]
-n      Project name
-d      Document root (optional, "/var/www" by default)
-t      Simulated top level domain (optional, "loc" by default)
-u      MySQL administrative user name (optional, ommit to avoid creating database)
-p      MySQL administrative user password (optional, ommit to avoid creating database)

Examples
--------
Add project named "example":

```bash
./lamp-vhost-manager.sh -m add -n example -u mysqladminusername -p mysqladminuserpassword
```

Output:

<pre>
Creating "/var/www/example"...
"/var/www/example" already owned by user "root", so not changing ownership...
"/var/www/example" already owned by user "root" from group "root", so not changing group ownership...
Adding "127.0.0.1 example.loc" to "/etc/hosts"...
Creating "/etc/apache2/sites-available/example"...
Creating MySQL user and database...
Running "a2ensite example"...
Running "service apache2 restart"...
PROJECT PATH: /var/www/example
PROJECT URL: http://example.loc
MYSQL USER: example
MYSQL PASSWORD: example
MYSQL DATABASE NAME: example
</pre>

Remove project named "example":

```bash
./lamp-vhost-manager.sh -m remove -n example -u mysqladminusername -p mysqladminuserpassword
```

Output:

<pre>
Do you want to remove "/var/www/example"? (y/N)?Y
Removing "/var/www/example"...
Removing "127.0.0.1 example.loc" from "/etc/hosts"...
Removing "/etc/apache2/sites-available/example"...
Do you want to remove MySQL "example" database and "example" user? (y/N)?Y
Removing MySQL user and database...
Running "a2dissite example"...
Running "service apache2 restart"...
</pre>