#!/bin/bash
SECONDS=0
sedi=(-i) && [ "$(uname)" == "Darwin" ] && sedi=(-i '')

# Setup
	# set -e
	# set -o pipefail

	YLW="\033[33;1m"
	GRN="\033[32;1m"
	WHT="\033[97;1m"
	RED="\033[91;1m"
	RES="\033[0m"
	VERSION="1.0"
	SCRIPT_NAME="Upsert Audit Trail CSV"
	USAGE="$0 -o org-name --filename file.csv"

	ORG_NAME=""
	FILE_NAME=""
	OBJ_NAME="Audit_Log__c"
	EXT_ID_FLD="Hash__c"
	WAIT_TIME="10"

	# functions
		pause()
		{
			read -p "Press Enter to continue."
		}
		export -f pause

		title()
		{
			echo -e "${GRN}*** ${WHT}${SCRIPT_NAME} script v${VERSION}${RES}\nby ${GRN}vaughan.crole@au1.ibm.com${RES}\n"
		}
		export -f title
	# end functions

	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-u | -o) ORG_NAME="$2"
					shift;;

				--filename | -f) FILE_NAME="$2"
					shift;;

				-h | --help) title
							 echo -e $USAGE
							 exit 0;;

				*) echo -e "${RED}*** ERROR: ${RES}Invalid option: ${WHITE}$1${RES}. See usage:"
				echo -e $USAGE
				exit 1;;
			esac
			shift
		done
	# end read args

	if [[ $ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi

	if [[ $FILE_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your file name. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi
# end setup


# header
	title
	echo -e "Org name: ${WHT}${ORG_NAME}${RES}"
	echo -e "File name: ${WHT}${FILE_NAME}${RES}\n"
# end header

# start here
sfdx data:upsert:bulk -f ${FILE_NAME} -o ${ORG_NAME} -i ${EXT_ID_FLD} -s ${OBJ_NAME} -w ${WAIT_TIME}

echo -e "${GRN}Success.${RES} Complete."
echo -e "\nTime taken: ${SECONDS} seconds."
exit 0;
