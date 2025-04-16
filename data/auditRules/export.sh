#!/bin/bash
SECONDS=0
set -e
set -o pipefail
cd "$(dirname "$BASH_SOURCE")"
OPERATION="Export"
source options.sh


# Setup
	YELLOW="\033[33;1m"
	GREEN="\033[32;1m"
	WHITE="\033[97;1m"
	RED="\033[91;1m"
	RESTORE="\033[0m"
	USAGE="$0 (-o <org_name> | --default)"
	VERSION="1.2"
	AUTHOR="vc@vaughancrole.com"

	ORG_NAME=""

	while [ $# -gt 0 ] ; do
		case $1 in
			-o | --target | --targetusername | --source ) ORG_NAME="$2"
				shift;;

			--default ) ORG_NAME="$(sfdx force:config:get defaultusername --json | egrep value | cut -d "\"" -f 4)";;

			-h | --help) echo "$USAGE"
						exit 0;;

			*) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
			echo -e "$USAGE"
			exit 1;;
		esac
		shift
	done

	if [[ $ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RESTORE}Specify your org name alias. See usage:"
		echo -e "${WHITE}$USAGE${RESTORE}"
		exit 1
	fi

	title()
	{
		echo -e "${GREEN}*** ${WHITE}Multi-Object ${OPERATION} script v${VERSION}${RESTORE}"
		echo -e "by ${GREEN}${AUTHOR}${RESTORE}\n"
	}
	export -f title
# Setup


title

echo -e "${GREEN}* ${RESTORE}${OPERATION}ing data from ${WHITE}${ORG_NAME}${RESTORE}."

## loop through queryArray
for (( i=0; i < ${#queryArray[@]}; i++ ));
do
	OBJ_NAME="${objectArray[i]}"
	CSV_NAME="${OBJ_NAME}.csv"
	SOQL=${queryArray[i]}

	echo -e "- $OBJ_NAME: "
	sfdx data:query -q "$SOQL" -r csv -o ${ORG_NAME} > $CSV_NAME
	echo ""
done

echo -e "${GREEN}Success.${RESTORE} Data ${OPERATION} complete."

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
