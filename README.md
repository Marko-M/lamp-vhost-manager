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
    -h    Show this message
    -m    Mode (required, "add" or "remove")
    -n    Project name (required, used as directory name and as domain name if -t is omitted)
    -t    TLD (optional, provide only if directory name differs from domain name)
    -d    Document root (optional, "/var/www" by default)
    -u    MySQL administrative user name (optional, ommit to avoid managing database)
    -p    MySQL administrative user password (optional, ommit to avoid managing database)
    -U    Desired MySQL database user name (optional, to be used with -u and -p, project name by default)
    -P    Desired MySQL database password (optional, to be used with -u and -p, project name by default)
    -N    Desired MySQL database name (optional, to be used with -u and -p, project name by default)
    -g    Initialize empty git repository inside project directory
    -c    Create CGI directory in document root
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
