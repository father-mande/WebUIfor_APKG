#!/bin/sh
if [ -z "${1}" ] ; then
	echo "Usage : $0 TARGET_APK_NAME x. $0 x11vnc"
	exit 1
fi
APP_NAME="${1}" 
echo -e "START getting parameters in ${APP_NAME}.conf"
### ARCH can be x86-64, arm64, arm, any ... i686 (32 bits) don't support ADM 4.0
ARCH="any"
VERSION="1.0"
DEPENDS=${APP_NAME}
SCUSER=${APP_NAME}
if [ -e ./${APP_NAME}/${APP_NAME}.conf ] ; then
	ARCH=$(/usr/bin/confutil -get ./${APP_NAME}/${APP_NAME}.conf SC ARCH)
	if [ $? -ne 0 ] ; then
		echo -e "HUM no ARCH for ${APP_NAME} ??? so any as default"
		ARCH="any"
	fi
	VERSION=$(/usr/bin/confutil -get ./${APP_NAME}/${APP_NAME}.conf SC VERSION)
	if [ $? -ne 0 ] ; then
		echo -e "HUM no VERSION for ${APP_NAME} script-server ??? so 1.0 as default"
		VERSION="1.0"
	fi
	DEPENDS="${APP_NAME}"
	DEPENDS=$(/usr/bin/confutil -get ./${APP_NAME}/${APP_NAME}.conf SC DEPENDS)
	if [ $? -ne 0 ] ; then
		DEPENDS=${APP_NAME}
	fi
	SCUSER="${APP_NAME}"
	SCUSER=$(/usr/bin/confutil -get ./${APP_NAME}/${APP_NAME}.conf SC SCUSER)
	if [ $? -ne 0 ] ; then
		SCUSER=${APP_NAME}
	fi
fi

echo -e "SAVE PREVIOUS version if exist"
if [ -e ./WebUIfor${APP_NAME} ] ; then
	rm -rf ./WebUIfor${APP_NAME}.save
	mv ./WebUIfor${APP_NAME} ./WebUIfor${APP_NAME}.save
fi

TARGET_CONTROL="./WebUIfor${APP_NAME}/CONTROL"
if [ ! -e "${TARGET_CONTROL}" ] ; then
	mkdir -p "${TARGET_CONTROL}"
fi
### copy fake_apkg to WebUIfor${APP_NAME}
echo -e "GENERATING all icons tagged with APKG name"
TXT1=""
POS1=200 # base for 8 first char of text if size > 8 char
POS=245 # base pos for text <=8 and rest after 8 char if necessary
FONTSZ=48
## CUT APP name if size > 8 characters
SZ=$(echo "${APP_NAME}" | /usr/bin/wc -L)
if [ ${SZ} -gt 8 ] ; then
	rest=$((SZ - 8))
	TXT1="${APP_NAME:0:8}"
	TXT="${APP_NAME: -rest}"
else
	RST=$(((8 - SZ) /2))
	if [ $RST -eq 3 ] ; then
		TXT="\ \ \ ${APP_NAME}"
	elif [ $RST -eq 2 ] ; then
		TXT="\ \ ${APP_NAME}"
	elif [ $RST -eq 1 ] ; then
		TXT="\ ${APP_NAME}"
	else
		TXT=${APP_NAME}
	fi
fi

# here BUILD ICONS for CONTROL folder
rm -f tempo_icon-server.png
if [ -z "${TXT1}" ] ; then
	/usr/builtin/bin/convert -font ./DejaVuSerif-Bold.ttf -pointsize ${FONTSZ} -fill red -annotate +2+${POS} "${TXT}" apkg_webui.png ${TARGET_CONTROL}/icon-server.png
else
	/usr/builtin/bin/convert -font ./DejaVuSerif-Bold.ttf -pointsize ${FONTSZ} -fill red -annotate +2+${POS} "${TXT}" apkg_webui.png tempo_icon-server.png
	/usr/builtin/bin/convert -font ./DejaVuSerif-Bold.ttf -pointsize ${FONTSZ} -fill red -annotate +2+${POS1} "${TXT1}" tempo_icon-server.png ${TARGET_CONTROL}/icon-server.png
fi
# now generate all icon-server
/usr/builtin/bin/convert ${TARGET_CONTROL}/icon-server.png -resize 90x90 ${TARGET_CONTROL}/icon-enable.png
cp -p ${TARGET_CONTROL}/icon-enable.png ${TARGET_CONTROL}/icon.png
/usr/builtin/bin/convert ${TARGET_CONTROL}/icon-server.png -resize 90x90 -colorspace Gray ${TARGET_CONTROL}/icon-disable.png
cp -p ${TARGET_CONTROL}/icon-server.png ${TARGET_CONTROL}/icon-server-enable.png
/usr/builtin/bin/convert ${TARGET_CONTROL}/icon-server.png -colorspace Gray ${TARGET_CONTROL}/icon-server-disable.png
echo -e "ADD my_data folder with inside .htpassword to add to scriptserver one if exist"
if [ -e ./${APP_NAME}/my_data ] ; then
	cp -pPR ./${APP_NAME}/my_data "./WebUIfor${APP_NAME}/"
else
	mkdir -p "./WebUIfor${APP_NAME}/my_data"
fi

echo -e "CREATING APKG structure based on skeleton"
# moding CONTROL
cp -pPR ./fake_apkg/fake/CONTROL/* "${TARGET_CONTROL}"

echo "Script_Server for ${APP_NAME}" > "${TARGET_CONTROL}/description.txt"

sed -i "s/%NAME%/${APP_NAME}/g" "${TARGET_CONTROL}/config.json"
sed -i "s/%DEPENDS%/${DEPENDS}/" "${TARGET_CONTROL}/config.json"
sed -i "s/%VER%/${VERSION}/" "${TARGET_CONTROL}/config.json"
sed -i "s/%ARCH%/${ARCH}/" "${TARGET_CONTROL}/config.json"

sed -i "s/%APP%/${APP_NAME}/g" "${TARGET_CONTROL}/start-stop.sh"
sed -i "s/%SCUSER%/${SCUSER}/" "${TARGET_CONTROL}/start-stop.sh"

### ADD shell used by json script (can be empty)
echo -e "ADD shell called by json script if exist"
cp -pPR ./fake_apkg/fake/bin "./WebUIfor${APP_NAME}/"
if [ -e ./${APP_NAME}/bin/ ] ; then
	cp -pP ./${APP_NAME}/bin/* "./WebUIfor${APP_NAME}/bin/"
fi

### ADD runners json scripts and first to supress splash screen
echo -e "ADD json scriptserver scripts"
cp -pPR ./fake_apkg/fake/script_server "./WebUIfor${APP_NAME}/"
mv ./WebUIfor${APP_NAME}/script_server/runners/1_WebUIfor_APP_splash_screen.json ./WebUIfor${APP_NAME}/script_server/runners/1_WebUIfor_${APP_NAME}_splash_screen.json
sed -i "s/%APP%/${APP_NAME}/g" ./WebUIfor${APP_NAME}/script_server/runners/1_WebUIfor_${APP_NAME}_splash_screen.json
if [ -e ./${APP_NAME}/script_server/runners/ ] ; then
	cp -pP ./${APP_NAME}/script_server/runners/* ./WebUIfor${APP_NAME}/script_server/runners/
fi

cp -pPR ./fake_apkg/fake/www "./WebUIfor${APP_NAME}/"
### index?html etc. are modified at start of the new APKG WebUIforxxxx

## time to generate APKG
./apkg-tools.py create WebUIfor${APP_NAME}
