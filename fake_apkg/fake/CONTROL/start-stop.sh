#!/bin/sh 
APP=%APP%
NAME=WebUIfor${APP}
APKG_PATH=/usr/local/AppCentral/${NAME}
# path of APKG targeted by WebUI
APP_PATH=/usr/local/AppCentral/${APP}
SC_PATH=/usr/local/AppCentral/scriptserver
SC_PATH_RUN=${SC_PATH}/script-server/conf/runners
SC_USER=%SCUSER%
rcP=/usr/local/etc/init.d/P90${NAME}

. /lib/lsb/init-functions
SC_PORT=$(grep \"port\": /usr/local/AppCentral/scriptserver/script-server/conf/script-server.json |tr -d " " | cut -f 2 -d ":" | cut -f 1 -d ",")
SC_SSL=$(grep  \"ssl\" /usr/local/AppCentral/scriptserver/script-server/conf/script-server.json)
SC_IP=$(hostname -i)

prepare_index_html(){
	CURPWD="$(pwd)"
	cd ${APKG_PATH}/www
	#
	for SPLASH in splash nosplash
	do
		rm -f index.html.${SPLASH}
		sed -e "s/%MYIP%/${SC_IP}/" index.html.${SPLASH}.skel > index.html.${SPLASH}
		sed -i "s/%MYPORT%/${SC_PORT}/" index.html.${SPLASH}
		sed -i "s/%USER%/${APP}/" index.html.${SPLASH}
		if [ -z "${SC_SSL}" ] ; then
			sed -i "s/%HTTP%/http/" index.html.${SPLASH}
		else
			sed -i "s/%HTTP%/https/" index.html.${SPLASH}
		fi
	done
	rm -f index.html
	if [ -e ${APKG_PATH}/.nosplash ] ; then
		ln -s index.html.nosplash index.html
	else
		ln -s index.html.splash index.html
	fi
	cd ${CURPWD}
}

link_runners(){
	CURPWD=$(pwd)
	cd ${SC_PATH_RUN}
	for F in "${APKG_PATH}/script_server/runners"/*
	do
		if [ -L "$(basename ${F})" ] ; then
			rm -f "$(basename ${F})"
		fi
		ln -s ${F} .
	done
	cd ${CURPWD}
}

unlink_runners(){
	CURPWD=$(pwd)
	cd ${SC_PATH_RUN}
	rm -f ./*${APP}*
	cd ${CURPWD}
}

add_user_in_sc_if_needed(){
	### SC USER NAME is APKG name
	# /usr/local/bin/script_server_mngt list_users_defined | grep -v "====" | grep -q ${SC_USER}
	grep -q "^${SC_USER}:" ${SC_PATH}/my_data/.htpassword
	if [ $? -ne 0 ] ; then
		echo -e "HUM! user ${SC_USER} don't exist try to add it from pre encrypted file .htpassword"
		echo -e "... ... ... or created automaticalu using asusfr1 as ${SC_USER} temporary password"
		if [ -e ${APKG_PATH}/my_data/.htpassword ] ; then
			cat ${APKG_PATH}/my_data/.htpassword >> ${SC_PATH}/my_data/.htpassword
		else
			/usr/local/bin/script_server_mngt add_new_user_password ${SC_USER} asusfr1 asusfr1 
		fi
	else
		echo -e "HUM! user ${SC_USER} already exist ... use it please"
	fi
}

start_daemon () {
    [ -e "$rcP" ] || ln -s ${APKG_PATH}/CONTROL/start-stop.sh $rcP 
	# test if SC run
	/bin/ps -eaf | grep -v grep | grep "/usr/local/AppCentral/scriptserver" | grep -q "launcher.py"
	if [ $? -eq 0 ] ; then
		add_user_in_sc_if_needed
		link_runners
		prepare_index_html
		if [ -e ${APKG_PATH}/bin/before_start.sh ] ; then
			${APKG_PATH}/bin/before_start.sh ${APP}
		fi
	else
		/usr/sbin/syslog -g 0 -l 2 --user admin --event "Script-server is not running, WebUIfor${APP} can't start ??? "
	fi
}

stop_daemon () {
    [ -e "$rcP" ] && rm -rf $rcP 	
	unlink_runners
	if [ -e ${APKG_PATH}/bin/before_stop.sh ] ; then
		${APKG_PATH}/bin/before_stop.sh ${APP}
	fi
}

case "$1" in
    start)
        log_daemon_msg "Starting daemon" "$NAME"
        start_daemon
        log_end_msg 0
        ;;
    stop)
        log_daemon_msg "Stopping daemon" "$NAME"
        stop_daemon
        log_end_msg 0
        ;;
    restart)
        log_daemon_msg "Restarting daemon" "$NAME"
        stop_daemon
        start_daemon
        log_end_msg 0
        ;;
    debug)
        ;;
	relink_json)
		link_runners
		;;
	set_splash_off)
		if [ ! -e ${APKG_PATH}/.nosplash ] ; then
			touch ${APKG_PATH}/.nosplash
			prepare_index_html
		fi
		echo "splash screen is OFF ... direct access to script-server login"
		;;
	set_splash_on)
		if [ -e ${APKG_PATH}/.nosplash ] ; then
			rm -f ${APKG_PATH}/.nosplash
			prepare_index_html
		fi
		echo "splash screen is ON ... access to script-server login is after splash-screen"
		;;
    *)
        echo "Usage: $0 {start|stop|restart}"
		echo "Usage: $0 {set_splash_on,set_splash_off} ... access to Script-Server via splash screen or directly"
		echo "Usage: $0 {relink_json} ... in case relink APKG json script in SC (case SC faill when starting"
        exit 2
        ;;
esac

if [ "$1" != "debug" ] ; then
    exit 0
fi
