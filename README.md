# Asustor APKG WebUIfor...
This tool is to create an APKG for your script-server scripts, for managing another APKG  

**Requirements** :  
... **scriptserver** APKG >= 1.17  
... **target_apkg** APKG (version check is possible)
  
**Methodology** :  
... first create your scripts and optional shell(s) called by your scripts  
... In folder containing webUI generator  
... ... create a folder with name of the target APKG  
... ... with sub-folder : **bin** (optional) **my_data** (optional) and **script_server/runners** (require)  
... ... copy shell scripts in bin (if needed)  
... ... copy scripts (json files) in script_server/runners/    
... ... copy generated .htpassword file (user name used by scripts and encrypted password used for authentication by scriptserver) or if no .htpassword or empty ... user will be created by WebUIforXXXX APKG with name : target_apkg_name (ex. if target APKG is x11vnc ... user will be x11vnc if not .htpassword provide or if SCUSER is filled with any name you want.)
... ... create a file name {target APKG}.conf like (x11vnc.conf for ex. for x11vnc APKG target)

**[SC]  
ARCH = x86-64  
\# ARCH default is any (x86_64, arm64, arm, any)  
VERSION = 1.0  
\# VERSION default is 1.0  
\# Optional  
\# DEPENDS = target_apkg_name(>=0.93)  
\# DEPENDS default is target_apkg_name only without version verification  
\# SCUSER = user_name  
\# SCUSER default is target_apkg_name**

... Now you can create the APKG, icons and necessary structure and installation  
... ... icons a tagged with the target APKG name  
... ... generated APKG name is : WebUIforXXXX (XXXX is the target APKG name)
... ... ex. if target is x11vnc APKG for script server management is : WebUIforx11vnc

**Run** : ./generateWebUIfor.sh TARGET_APKG_NAME

When APKG (WebUIforTARGET_APKG) is created, install it manually as usual, if you uninstall it, json scripts are removed, if target APKG and / or scriptserver APKG are removed, WebUIfor{targetAPKG} is also removed.

If you need to personalize the start-stop.sh script to add some actions before starting of WebUIforXXXX or just before stopping it.  
you can add in **bin** folder shell script named :  
**before_start.sh** ... executed at end of start of the APKG  
**before_stop.sh** ... executed at end of stop of the APKG

By default, when you click on generated icon in A.D.M. webUI, a splash screen is displayed to remember you user name for script-server and default password (if not changed by you) before redirecting you to script-server login page. This splash screen can be removed, to have a direct access to screen-server login page 

Good Luck.  
Philippe.