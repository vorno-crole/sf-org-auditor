#!/bin/bash

# Setup
	set -e
	# set -o pipefail

	YLW="\033[33;1m"
	GRN="\033[32;1m"
	WHT="\033[97;1m"
	RED="\033[91;1m"
	RES="\033[0m"
	VERSION="1.0"
	USAGE="$0 -o <org-name>"
	ORG_NAME=""
	DEV_HUB=""

	SCRATCH_DEF="config/project-scratch-def.json"

	title()
	{
		echo -e "${GRN}*** ${WHT}Create Scratch Org script v${VERSION}${RES}\nby ${GRN}vc@vaughancrole.com${RES}\n"
	}
	export -f title

	pause()
	{
		read -p "Press Enter to continue."
	}
	export -f pause

	while [ $# -gt 0 ] ; do
		case $1 in
			--targetusername | -u | -o) ORG_NAME="$2"
				shift;;

			--devhub | -d) DEV_HUB="$2"
				shift;;

			-h | --help) title
						 echo -e "$USAGE"
						 exit 0;;

			*) title
			   echo -e "${RED}*** Error: ${RES}Invalid option: ${WHITE}$1${RES}. See usage:"
			   echo -e "$USAGE"
			   exit 1;;
		esac
		shift
	done

	if [[ $ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi

	if [[ $DEV_HUB == "" ]] ; then
		DEV_HUB="$(sf config get target-dev-hub --json | jq -r '.result[0].value')"
	fi
# end setup

title
echo -e "${GRN}*${RES} Org name: ${WHT}$ORG_NAME${RES}"
echo -e "${GRN}*${RES} Scratch Org Definition: ${WHT}$SCRATCH_DEF${RES}\n"


cd "$(dirname "$BASH_SOURCE")"
cd ..

# Create org
sf org create scratch --definition-file ${SCRATCH_DEF} --duration-days 30 --alias ${ORG_NAME} --set-default --track-source --target-dev-hub ${DEV_HUB}
sf org display -o ${ORG_NAME} --json | tee .org_display
USER_NAME="$(jq -r '.result.username' .org_display)"
rm -f .org_display

# Deploy
sf project deploy start -o ${ORG_NAME}

# Set up user
	# Perm sets
	scripts/shell/assign-perm-sets.sh -o ${ORG_NAME} --username ${USER_NAME}


# data
data/import-all.sh -o ${ORG_NAME}

# open org
sf org open -o ${ORG_NAME}


echo -e "${GREEN}Success.${RESTORE} Complete."

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
