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
	SCRIPT_NAME="Get and Upsert Audit Trail CSV"
	USAGE="$0 -o org-name"

	UPSERT_ORG_NAME=""
	GET_ORG_NAME="uomAT"
	FILE_NAME="SetupAuditTrail.csv"

	# functions
		pause()
		{
			read -p "Press Enter to continue."
		}
		export -f pause

		title()
		{
			echo -e "${GRN}*** ${WHT}${SCRIPT_NAME} script v${VERSION}${RES}\nby ${GRN}vc@vaughancrole.com${RES}\n"
		}
		export -f title
	# end functions

	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-u | -o) UPSERT_ORG_NAME="$2"
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

	if [[ $UPSERT_ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi
# end setup


# header
	title
	echo -e "Get Org name: ${WHT}${GET_ORG_NAME}${RES}"
	echo -e "Upsert Org name: ${WHT}${UPSERT_ORG_NAME}${RES}"
# end header

cd "$(dirname "$BASH_SOURCE")"
cd ../..

# start here
scripts/shell/get-audit-trail.sh -o ${GET_ORG_NAME}
scripts/shell/upsert-audit-trail.sh -o ${UPSERT_ORG_NAME} --filename ${FILE_NAME}

echo -e "${GRN}Success.${RES} Complete."
echo -e "\nTime taken: ${SECONDS} seconds."
exit 0;
