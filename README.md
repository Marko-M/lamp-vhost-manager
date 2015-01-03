LAMP Vhost Manager - Apache 2.4
======================================

Easily manage LAMP name based virtual hosts for your web development projects.

For more details you can visit [my article at inchoo.net](http://inchoo.net/tools-frameworks/easily-manage-lamp-name-based-virtual-hosts/).

Features
--------
* Two modes of operation, add and remove project
* Optionally creates MySQL user and database
* Detects suphp module to create files with proper user and group ownership depending on configurable base document root
* Supports later Debian and Ubuntu versions distributed with Apache 2.4 web server

Usage
-----
This script requires root access.

```bash
./lamp-vhost-manager.sh OPTIONS
```

OPTIONS:

<pre>
    -h  Show this message
    -m  Mode (required, "add" or "remove")
    -n  Project name (required, assumed it contains domain if -t is omitted)
    -t  TLD (optional, provide only if directory name differs from domain name)
    -d  Document root directory (optional, defaults to "$DOCROOT/<Project Name>")
    -o  HTTP port (optional, defaults to port 80)
    -S  Create HTTPS virtual host (optional, defaults to no, requires ssl-cert package installed)
    -s  HTTPS port (optional, defaults to port 443, to be used with -S option)
    -u  MySQL administrative user name (optional, ommit to avoid managing database)
    -p  MySQL administrative user password (optional, ommit to avoid managing database)
    -U  Desired MySQL database user name (optional, to be used with -u and -p, <Project Name> by default, trimmed to 16 characters)
    -P  Desired MySQL database password (optional, to be used with -u and -p, <Project Name> by default, trimmed to 16 characters)
    -N  Desired MySQL database name (optional, to be used with -u and -p, <Project Name> by default, trimmed to 16 characters)
    -g  Initialize empty git repository inside project directory (optional, defaults to no)
    -r  Log files root directory (optional, defaults to "$LOGROOT/<Project Name>")
</pre>

Example
-------
Add project "example.loc":

```bash
./lamp-vhost-manager.sh -m add -n example.loc -u mysqladminusername -p mysqladminuserpassword
```

Output:

<pre>
Creating "/var/www/example.loc"...
"/var/www/example.loc" already owned by user "root", so not changing ownership...
"/var/www/example.loc" already owned by user "root" from group "root", so not changing group ownership...
Adding "127.0.0.1 example.loc" to "/etc/hosts"...
Creating "/etc/apache2/sites-available/example.loc"...
Creating "/var/log/apache2/example.loc"...
Creating MySQL user and database...
Running "a2ensite example.loc"...
Running "service apache2 restart"...
PROJECT PATH: /var/www/example.loc
PROJECT URL: http://example.loc
MYSQL USER: example.loc
MYSQL PASSWORD: example.loc
MYSQL DATABASE: example.loc
</pre>

Remove project "example.loc":

```bash
./lamp-vhost-manager.sh -m remove -n example.loc -u mysqladminusername -p mysqladminuserpassword
```

Output:

<pre>
Do you want to remove "/var/www/example.loc"? (y/N)?Y
Removing "/var/www/example.loc"...
Removing "/var/log/apache2/example.loc"...
Removing "127.0.0.1 example.loc" from "/etc/hosts"...
Removing "/etc/apache2/sites-available/example.loc"...
Do you want to remove MySQL "example.loc" database and "example.loc" user? (y/N)?Y
Removing MySQL user and database...
Running "a2dissite example.loc"...
Running "service apache2 restart"...
</pre>
