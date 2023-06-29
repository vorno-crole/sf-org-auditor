#!/bin/bash

# Setup
	set -e
	set -o pipefail

	YELLOW="\033[33;1m"
	GREEN="\033[32;1m"
	WHITE="\033[97;1m"
	RED="\033[91;1m"
	RESTORE="\033[0m"
	VERSION="1.0"

	ORG_NAME=""

	# functions
	title()
	{
		echo -e "${GREEN}*** ${WHITE}Deploy Data script v${VERSION}${RESTORE}\nby ${GREEN}vc@vaughancrole.com${RESTORE}\n"
	}
	export -f title

	usage()
	{
		title
		echo -e "Usage:"
		echo -e "${WHITE}$0${RESTORE} (-o <destination org alias> | --default)"
	}
	export -f usage

	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-o) ORG_NAME="$2"
					shift;;

				--default ) ORG_NAME="$(sfdx force:config:get defaultusername --json | egrep value | cut -d "\"" -f 4)";;

				-h | --help) usage
				exit 0;;

				*) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
				usage
				exit 1;;
			esac
			shift
		done

		if [[ $ORG_NAME == "" ]]; then
			echo -e "${RED}*** Error: ${RESTORE}Destination Org not specified."
			usage
			exit 1
		fi
	# end read args
# end Setup


title
echo -e "${GREEN}Deploying data.${RESTORE}\n"

echo -e "${GREEN}*${RESTORE} Audit Rules"
data/auditRules/import.sh -o ${ORG_NAME}

# Success
echo -e "${GREEN}Deploy Data Successful!${RESTORE}"
