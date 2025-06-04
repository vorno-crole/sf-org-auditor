#!/bin/bash

# Setup
	# set -e
	# set -o pipefail

	YLW="\033[33;1m"
	GRN="\033[32;1m"
	WHT="\033[97;1m"
	RED="\033[91;1m"
	RES="\033[0m"
	VERSION="1.0"
	USAGE="$0 -o <org-name>"
	ORG_NAME=""

	USER_NAME=""

	title()
	{
		echo -e "${GRN}*** ${WHT}Assign Permission Sets script v${VERSION}${RES}\nby ${GRN}vc@vaughancrole.com${RES}\n"
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

			-h | --help) title
						 echo -e "$USAGE"
						 exit 0;;
			
			--username) USER_NAME="$2"
				shift;;

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
# end setup

title
echo -e "${GRN}*${RES} Org name: ${WHT}$ORG_NAME${RES}"

if [[ $USER_NAME == "" ]]; then 
	# Get current user name
	sfdx org:display -o ${ORG_NAME} > .org_display
	USER_NAME="$(grep -E "^ ?Username" .org_display | awk '{print $2}')"
	rm -f .org_display
fi

echo -e "${GRN}*${RES} Username: ${WHT}$USER_NAME${RES}"

# find perm sets
mkdir -p .flags
find force-app/main/default/permissionsets -type f | xargs basename -s .permissionset-meta.xml >> .flags/name

# assign all perm sets to user
sf org assign permset --flags-dir .flags -o ${ORG_NAME} -b ${USER_NAME}
rm -rf .flags


echo -e ""
echo -e "${GREEN}Success.${RESTORE} Complete."

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
