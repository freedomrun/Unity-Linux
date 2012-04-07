#! /bin/bash -x

if $(zenity --question --ok-label="Install" --cancel-label="Quit" --text="You are about to install a meta task package. 
 
Are you sure you want to continue?")
then
	if $(zenity --question --title="Got Internet?" --text="Do you have a working internet connection?")
	then
		ping google.com -c 5 | zenity --progress --title="Testing" --text="Testing your internet connection..." --pulsate --auto-close
		if [ "${PIPESTATUS[0]}" != "0" ]; then
			zenity --error --text="Sorry, You do not currently have a fully working internet connection." --title="Error"
			exit 0
		fi
	while [[ $1 == -* ]]; do
		case "$1" in
		-k|--task-kde4) gksu '(smart --gui update || smart --gui install task-kde4)' ; exit 0;;
		-g|--task-gnome) gksu '(smart --gui update || smart --gui install task-gnome)' ; exit 0;;
		-l|--task-lxde) gksu '(smart --gui update || smart --gui install task-lxde)' ; exit 0;;
		-e|--task-e17) gksu '(smart --gui update || smart --gui install task-e17)'; exit 0;;
		-x|--task-xfce) gksu '(smart --gui update || smart --gui install task-xfce)'; exit 0;;
		esac
	done
	fi	 
fi

