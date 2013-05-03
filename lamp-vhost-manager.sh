#!/bin/bash
# Author: Marko Martinović
# License: GPLv2

# Default document root (change if neccessary)
DOCROOT="/var/www"

# Virtual host name (enter to avoid having to use argument)
NAME=

# Mode, add or remove (enter to avoid having to use argument)
MODE=

# MySQL admin user name (enter to avoid having to use argument)
MYSQLU=

# MySQL admin user password (enter to avoid having to use argument)
MYSQLP=

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
    -n    Project domain name (required, "magento.loc" for example)
    -d    Document root (optional, "$DOCROOT" by default)
    -u    MySQL administrative user name (optional, ommit to avoid creating database)
    -p    MySQL administrative user password (optional, ommit to avoid creating database)

  Examples:
    -add project named "example":
	$0 -m add -n example.com -u mysqladminusername -p mysqladminuserpassword

    -Remove project named "example":
	$0 -m remove -n example.com -u mysqladminusername -p mysqladminuserpassword
EOF
}

# Adds virtual host and optionaly creates database.
function add() {
    # Create virtualhost document root
    if [ ! -d $VHOSTDOCROOT ]
    then
	echo "Creating \"$VHOSTDOCROOT\"..."
	mkdir $VHOSTDOCROOT
    else
	echo "\"$VHOSTDOCROOT\" already exists, so not creating..."
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
	chown $DOCROOTUSER $VHOSTDOCROOT
    else
	echo "\"$VHOSTDOCROOT\" already owned by user \"$DOCROOTUSER\", so not changing ownership..."
    fi

    # Chgrp virtualhost document root to group owning document root if neccessary
    if [ "$DOCROOTGROUP" != "$VHOSTDOCROOTGROUP" ]
    then
    	echo "Chgrp \"$VHOSTDOCROOT\" to \"$DOCROOTGROUP\"..."
	chgrp $DOCROOTGROUP $VHOSTDOCROOT
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
    ServerAdmin webmaster@$NAME
    ServerName $NAME

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
</VirtualHost>
EOF
    else
	echo "\"$VHOSTFILE\" already exists, so not creating..."
    fi

    # If MySQL credentials are available, use them to create db and user
    if [[ ! -z $MYSQLU ]] || [[ ! -z $MYSQLP ]]
    then
    echo "Creating MySQL user and database..."
mysql "-u$MYSQLU" "-p$MYSQLP" <<QUERY_INPUT
GRANT USAGE ON * . * TO '$NAME'@'localhost' IDENTIFIED BY '$NAME' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS \`$NAME\`;
GRANT ALL PRIVILEGES ON \`$NAME\`. * TO '$NAME'@'localhost';
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
    echo "PROJECT URL: http://$NAME"

    if [[ ! -z $MYSQLU ]] || [[ ! -z $MYSQLP ]]
    then
	echo "MYSQL USER: $NAME"
	echo "MYSQL PASSWORD: $NAME"
	echo "MYSQL DATABASE: $NAME"
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
    if [[ ! -z $MYSQLU ]] || [[ ! -z $MYSQLP ]]
    then
	yes_no_pause "Do you want to remove MySQL \"$NAME\" database and \"$NAME\" user?"
	if [ $? = 0 ]
	then
	    echo "Removing MySQL user and database..."
mysql "-u$MYSQLU" "-p$MYSQLP" <<QUERY_INPUT
GRANT USAGE ON * . * TO '$NAME'@'localhost';
DROP USER '$NAME'@'localhost';
DROP DATABASE IF EXISTS \`$NAME\`;
QUERY_INPUT
	else
	    "Not removing MySQL \"$NAME\" database and \"$NAME\" user?"
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

# Document root must exist to proceed
if [ ! -d $DOCROOT ]
    then
    exit_pause "Document root directory doesn't exist."
fi

# Parse script arguments
while getopts "hm:n:d:u:p:" OPTION
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
    d)
      DOCROOT=$OPTARG
      ;;
    u)
      MYSQLU=$OPTARG
      ;;
    p)
      MYSQLP=$OPTARG
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

# Virtual host file
VHOSTFILE="/etc/apache2/sites-available/$NAME"

# Virtual host document root
VHOSTDOCROOT="$DOCROOT/$NAME"

# Virtual host /etc/hosts line
HOSTSLINE="127.0.0.1 $NAME"

# Run in selected mode
$MODE

# Exit success
exit 0
