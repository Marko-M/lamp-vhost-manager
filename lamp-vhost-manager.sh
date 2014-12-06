#!/bin/bash
# Author: Marko Martinović
# License: GPLv2

# Default document root (change if neccessary)
DOCROOT="/var/www"

# Default log root (change if neccessary)
LOGROOT="/var/log/apache2"

# Directory name and domain name if $TLD is empty (enter to avoid having to use this argument)
NAME=

# Desired top level domain (enter to avoid having to use this argument)
TLD=

# Mode, add or remove (enter to avoid having to use this argument)
MODE=

# MySQL admin user name (enter to avoid having to use this argument)
MYSQLAU=

# MySQL admin user password (enter to avoid having to use this argument)
MYSQLAP=

# Desired MySQL database user (enter to avoid having to use this argument)
MYSQLU=

# Desired MySQL database password (enter to avoid having to use this argument)
MYSQLP=

# Desired MySQL database name (enter to avoid having to use this argument)
MYSQLN=

# Initialize git repository
GIT=false

# Create CGI directory in document root
CGI=false

###############################################################################

# Prints $1 and then exits after any key
function exit_pause() {
    echo -e "$1.\n"
    read -p "Press any key to EXIT"
    exit 1
}

# Prompts for yes/no confirmation with no being default.
# Returns 1 for no and 0 for yes.
function yes_no_pause() {
    read -p "$1 (y/N)?" choice
    case "$choice" in
    y|Y ) return 0;;
    n|N ) return 1;;
    * ) return 1;;
    esac
}

# Prints usage instructions
function usage() {
  cat << EOF
  Usage: $0 OPTIONS

  Easily manage LAMP name based virtual hosts for your web development projects.

  OPTIONS:
    -h    Show this message
    -m    Mode (required, "add" or "remove")
    -n    Project name (required, used as directory name and as domain name if -t is omitted)
    -t    TLD (optional, provide only if directory name differs from domain name)
    -d    Document root (optional, "$DOCROOT" by default)
    -u    MySQL administrative user name (optional, ommit to avoid managing database)
    -p    MySQL administrative user password (optional, ommit to avoid managing database)
    -U    Desired MySQL database user name (optional, to be used with -u and -p, project name by default)
    -P    Desired MySQL database password (optional, to be used with -u and -p, project name by default)
    -N    Desired MySQL database name (optional, to be used with -u and -p, project name by default)
    -g    Initialize empty git repository inside project directory
    -c    Create CGI directory in document root

  Examples:
    -Add project "example.loc" and create database having "example.loc" user and password and name:
	$0 -m add -n example.loc -u mysqladminusername -p mysqladminuserpassword

    -Remove project "example.loc" and optionaly remove database having "example.loc" user and password and name:
	$0 -m remove -n example.loc -u mysqladminusername -p mysqladminuserpassword

    -Add project "example.loc" using "example" as directory name and "example.loc" as domain without creating database:
	$0 -m add -n example -t loc

    -Remove project "example.loc" using "example" as directory name and "example.loc" as domain without removing database:
	$0 -m remove -n example -t loc

    -Add project "example.loc" and create database having "exampledbname" name, "exampledbuser" user and "exampledbpass" password:
	$0 -m add -n example.loc -u mysqladminusername -p mysqladminuserpassword -U exampledbuser -P exampledbpass -N exampledbname

    -Remove project "example.loc" and optionaly remove database having "exampledbname" name, "exampledbuser" user and "exampledbpass" password:
	$0 -m remove -n example.loc -u mysqladminusername -p mysqladminuserpassword -U exampledbuser -P exampledbpass -N exampledbname
EOF
}

# Adds virtual host and optionaly creates database.
function add() {
    # Create virtualhost document root
    if [ ! -d $VHOSTDOCROOT ]
    then
	echo "Creating \"$VHOSTDOCROOT\"..."
	mkdir $VHOSTDOCROOT

     # Create git repository
      if [ $GIT == true ]
      then
        echo "Creating git repository in \"$VHOSTDOCROOT\"..."
        git init $VHOSTDOCROOT
      fi

    else
	echo "\"$VHOSTDOCROOT\" already exists, so not creating..."
    fi

    # Create virtualhost log root
    if [ ! -d $VHOSTLOGROOT ]
    then
	echo "Creating \"$VHOSTLOGROOT\"..."
	mkdir $VHOSTLOGROOT
    else
	echo "\"$VHOSTLOGROOT\" already exists, so not creating..."
    fi

    if [ $CGI == true ]
    then
	echo "Creating \"$VHOSTCGIROOT\"..."
	mkdir $VHOSTCGIROOT
read -r -d '' CGIPATTERN <<EOF
    ScriptAlias /cgi-bin/ $VHOSTCGIROOT/
    <Directory "$VHOSTCGIROOT">
	AllowOverride None
	Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
	Order allow,deny
	Allow from all
    </Directory>
EOF
    else
	echo "\"$VHOSTCGIROOT\" already exists, so not creating..."
	CGIPATTERN=
    fi

    # Detect user and group ownerships (for serving outside of /var/www)
    local DOCROOTUSER=$(stat -c "%U" $DOCROOT)
    local DOCROOTGROUP=$(stat -c "%G" $DOCROOT)
    local VHOSTDOCROOTUSER=$(stat -c "%U" $VHOSTDOCROOT)
    local VHOSTDOCROOTGROUP=$(stat -c "%G" $VHOSTDOCROOT)

    # Chown virtualhost document root to user owning document root if neccessary
    if [ "$DOCROOTUSER" != "$VHOSTDOCROOTUSER" ]
    then
    	echo "Chown \"$VHOSTDOCROOT\" to \"$DOCROOTUSER\"..."
	chown -R $DOCROOTUSER $VHOSTDOCROOT
    else
	echo "\"$VHOSTDOCROOT\" already owned by user \"$DOCROOTUSER\", so not changing ownership..."
    fi

    # Chgrp virtualhost document root to group owning document root if neccessary
    if [ "$DOCROOTGROUP" != "$VHOSTDOCROOTGROUP" ]
    then
    	echo "Chgrp \"$VHOSTDOCROOT\" to \"$DOCROOTGROUP\"..."
	chgrp -R $DOCROOTGROUP $VHOSTDOCROOT
    else
	echo "\"$VHOSTDOCROOT\" already owned by user \"$DOCROOTUSER\" from group \"$DOCROOTGROUP\", so not changing group ownership..."
    fi

    # Add line to "/etc/hosts" if it isn't already there
    grep -Fxq "$HOSTSLINE" "/etc/hosts"
    if [ $? = 1 ]
    then
	echo "Adding \"$HOSTSLINE\" to \"/etc/hosts\"..."
	echo "$HOSTSLINE" >> /etc/hosts
    else
	echo "\"$HOSTSLINE\" already inside \"/etc/hosts\", so not adding..."
    fi

    # Create virtual host file if it doesn't already exist
    if [ ! -f $VHOSTFILE ]
    then
	echo "Creating \"$VHOSTFILE\"..."
cat > $VHOSTFILE <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@$VHOSTDOMAIN
    ServerName $VHOSTDOMAIN

    DocumentRoot $VHOSTDOCROOT
    <Directory />
	Options FollowSymLinks
	AllowOverride None
    </Directory>
    <Directory $VHOSTDOCROOT/>
	Options Indexes FollowSymLinks MultiViews
	AllowOverride All
	Order allow,deny
	allow from all
    </Directory>
    $CGIPATTERN
    CustomLog $VHOSTLOGROOT/access.log combined
    ErrorLog $VHOSTLOGROOT/error.log
</VirtualHost>
EOF
    else
	echo "\"$VHOSTFILE\" already exists, so not creating..."
    fi

    # If MySQL credentials are available, use them to create db and user
    if [[ ! -z $MYSQLAU ]] || [[ ! -z $MYSQLAP ]]
    then
    echo "Creating MySQL \"$MYSQLU\" user and \"$MYSQLN\" database..."
mysql "-u$MYSQLAU" "-p$MYSQLAP" <<QUERY_INPUT
GRANT USAGE ON * . * TO '$MYSQLU'@'localhost' IDENTIFIED BY '$MYSQLP' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS \`$MYSQLN\`;
GRANT ALL PRIVILEGES ON \`$MYSQLN\`. * TO '$MYSQLU'@'localhost';
QUERY_INPUT
    else
	echo "Ommit creating MySQL user and database..."
    fi

    # Enable virtual host
    echo "Running \"a2ensite $NAME\"..."
    a2ensite $NAME>/dev/null 2>&1

    # Restart apache service
    echo "Running \"service apache2 restart\"..."
    service apache2 restart>/dev/null 2>&1

    # Print results
    echo "PROJECT PATH: $VHOSTDOCROOT"
    echo "PROJECT URL: http://$VHOSTDOMAIN"

    if [[ ! -z $MYSQLAU ]] || [[ ! -z $MYSQLAP ]]
    then
	echo "MYSQL USER: $MYSQLU"
	echo "MYSQL PASSWORD: $MYSQLP"
	echo "MYSQL DATABASE: $MYSQLN"
    fi
}

function remove() {
    # Remove virtualhost document root if it exists
    if [ -d $VHOSTDOCROOT ]
    then
	# Ask for confirmation
	yes_no_pause "Do you want to remove \"$VHOSTDOCROOT\"?"
	if [ $? = 0 ]
	then
	    echo "Removing \"$VHOSTDOCROOT\"..."
	    rm -fR $VHOSTDOCROOT
	else
	    echo "NOT removing \"$VHOSTDOCROOT\"..."
	fi
    else
	echo "\"$VHOSTDOCROOT\" doesn't exist, so not offering to remove it..."
    fi

    # Remove virtualhost log root if it exists
    if [ -d $VHOSTLOGROOT ]
    then
	echo "Removing \"$VHOSTLOGROOT\"..."
	rm -fR $VHOSTLOGROOT
    else
	echo "Thereis no \"$VHOSTLOGROOT\", nothing remove..."
    fi

    # Remove line from /etc/hosts if it is there
    grep -Fxq "$HOSTSLINE" "/etc/hosts"
    if [ $? = 0 ]
    then
	echo "Removing \"$HOSTSLINE\" from \"/etc/hosts\"..."
	sudo sed -i "/$HOSTSLINE/d" /etc/hosts
    else
	echo "\"$HOSTSLINE\" not inside \"/etc/hosts\", so not removing..."
    fi

    # Remove virtual host file if it exists
    if [ -f $VHOSTFILE ]
    then
	echo "Removing \"$VHOSTFILE\"..."
	rm $VHOSTFILE
    else
	echo "\"$VHOSTFILE\" doesn't exist, so not removing..."
    fi

    # If MySQL credentials are available, use them to remove db and user
    if [[ ! -z $MYSQLAU ]] || [[ ! -z $MYSQLAP ]]
    then
	yes_no_pause "Do you want to remove MySQL \"$NAME\" database and \"$NAME\" user?"
	if [ $? = 0 ]
	then
	    echo "Removing MySQL \"$MYSQLU\" user and \"$MYSQLN\" database..."
mysql "-u$MYSQLAU" "-p$MYSQLAP" <<QUERY_INPUT
GRANT USAGE ON * . * TO '$MYSQLU'@'localhost';
DROP USER '$MYSQLU'@'localhost';
DROP DATABASE IF EXISTS \`$MYSQLN\`;
QUERY_INPUT
	else
	    "Not removing MySQL \"$MYSQLN\" database and \"$MYSQLU\" user..."
	fi
    else
	echo "Ommit removing MySQL user and database..."
    fi

    # Disable virtual host
    echo "Running \"a2dissite $NAME\"..."
    a2dissite $NAME >/dev/null 2>&1

    # Restart apache service
    echo "Running \"service apache2 restart\"..."
    service apache2 restart>/dev/null 2>&1
}

# We need admin privileges to proceed
if [ "$(whoami)" != "root" ]
    then
    exit_pause "Please call this script with elevated privileges."
fi

# Parse script arguments
while getopts "hm:n:t:d:u:p:U:P:N:gc" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    m)
      MODE=$OPTARG
      ;;
    n)
      NAME=$OPTARG
      ;;
    t)
      TLD=$OPTARG
      ;;
    d)
      DOCROOT=$OPTARG
      ;;
    u)
      MYSQLAU=$OPTARG
      ;;
    p)
      MYSQLAP=$OPTARG
      ;;
    U)
      MYSQLU=$OPTARG
      ;;
    P)
      MYSQLP=$OPTARG
      ;;
    N)
      MYSQLN=$OPTARG
      ;;
    g)
      GIT=true
      ;;
    c)
      CGI=true
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

# Test for required arguments
if [[ -z $DOCROOT ]] || [[ -z $NAME ]] || [[ $MODE != 'add' && $MODE != 'remove' ]]
then
     usage
     exit 1
fi

# Document root must exist to proceed
if [ ! -d $DOCROOT ]
    then
    exit_pause "Document root directory doesn't exist."
fi

# For db user fallback to $NAME
if [[ -z $MYSQLU ]]
then
     MYSQLU=$NAME
fi

# For db password fallback to $NAME
if [[ -z $MYSQLP ]]
then
     MYSQLP=$NAME
fi

# For db name fallback to $NAME
if [[ -z $MYSQLN ]]
then
     MYSQLN=$NAME
fi

# If $TLD specified, use it as vhost domain
if [[ ! -z $TLD ]]
then
     VHOSTDOMAIN="$NAME.$TLD"
else
     VHOSTDOMAIN="$NAME"
fi

# Virtual host file
VHOSTFILE="/etc/apache2/sites-available/$NAME.conf"

# Virtual host document root
VHOSTDOCROOT="$DOCROOT/$NAME"

# Virtual host log root
VHOSTLOGROOT="$LOGROOT/$NAME"

# Virtual host CGI root
VHOSTCGIROOT="$DOCROOT/$NAME/cgi-bin"

# Virtual host /etc/hosts line
HOSTSLINE="127.0.0.1 $VHOSTDOMAIN"

# Run in selected mode
$MODE

# Exit success
exit 0
