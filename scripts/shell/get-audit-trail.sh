#!/bin/bash
SECONDS=0

set -e

ORG_NAME=""
ORG_URL_NAME=""
PAGE_NAME="//setup/org/orgsetupaudit.jsp?setupid=SecurityEvents"
CURL_OPTS="-c cookiejar -L"
CURRENT_URL=""
PREV_URL=""
FILENAME="SetupAuditTrail.csv"
FILENAME_JSON="$(basename -s .csv $FILENAME).json"
AUTO_OPEN="FALSE"
MODE="download"

sedi=(-i) && [ "$(uname)" == "Darwin" ] && sedi=(-i '')

# Setup
	# set -e
	# set -o pipefail

	YELLOW="\033[33;1m"
	GREEN="\033[32;1m"
	WHITE="\033[97;1m"
	RED="\033[91;1m"
	RESTORE="\033[0m"
	VERSION="0.2 alpha"
	AUTHOR="vc@vaughancrole.com"
	USAGE="$0 -o org-name [--open-file]"

	# functions
		pause()
		{
			read -p "Press Enter to continue."
		}
		export -f pause

		title()
		{
			echo -e "${GREEN}*** ${WHITE}Get Audit Trail CSV script v${VERSION}${RESTORE}\nby ${GREEN}${AUTHOR}${RESTORE}\n"
		}
		export -f title
	# end functions

	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-u | -o) ORG_NAME="$2"
					shift;;

				--open-file) AUTO_OPEN="TRUE";;

				-m | --mode) MODE="$2"
					shift;;

				-h | --help) title
							 echo -e $USAGE
							 exit 0;;

				*) echo -e "${RED}*** ERROR: ${RESTORE}Invalid option: ${WHITE}$1${RESTORE}. See usage:"
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
# end setup


# header
	title
	echo -e "Org name: ${WHITE}${ORG_NAME}${RESTORE}\n"
# end header



# start here
if [[ $MODE == "download" ]]; then

	# tidy
	rm -f cookiejar

	# Get authentication URL
	echo -e "${GREEN}*${RESTORE} Get authentication URL from SFDX"
	CURRENT_URL="$(sf org open -o ${ORG_NAME} -p ${PAGE_NAME} -r --json 2> /dev/null | jq -r '.result.url' | tee url.txt)"
	echo -e "- ${CURRENT_URL}\n"
	NEXT_URL="$(curl ${CURL_OPTS} --url "$(cat url.txt)" --silent | tee curl.log | ggrep -oP -m1 "https://[\w\-\.\/\?=&%]+" | head -1)"
	rm -f url.txt

	# Follow Javascript redirect, ensure cookies set are transmitted with the request
	echo -e "${GREEN}*${RESTORE} Following Javascript redirect"
	PREV_URL="${CURRENT_URL}"
	CURRENT_URL="${NEXT_URL}"
	NEXT_URL=$(curl ${CURL_OPTS} -b cookiejar -e ${PREV_URL} ${CURRENT_URL} --silent | tee curl2.log | ggrep SetupAuditTrail | ggrep -oP "href=\"/serv(.+?)\"" | head -1 | cut -d "\"" -f 2)

	# Find and Construct the CSV URL from PREV_URL host and CURR_URL pathname, also translate &amp; into &
	echo -e "${GREEN}*${RESTORE} Finding CSV URL and downloading"
	PREV_URL="${CURRENT_URL}"
	CURRENT_URL="$(echo -e ${PREV_URL} | ggrep -oP "https://[\w\-\.]+")${NEXT_URL}"
	CURRENT_URL="$(sed "s/\&amp;/\&/g" <<< "${CURRENT_URL}")"
	echo -e "- ${CURRENT_URL}\n"

	# Follow the CSV link
	# FILENAME="SetupAuditTrail-${ORG_NAME}-$(date +"%d-%b-%Y").csv"
	curl ${CURL_OPTS} -b cookiejar -J -o ${FILENAME} -e ${PREV_URL} ${CURRENT_URL}
	echo ""
	rm -f cookiejar

	# TODO processing
	# TODO: Not carriage return safe
	echo -e "${GREEN}*${RESTORE} Processing CSV"

	# TODO do we convert to json? yes
	echo -e "- Convert to JSON\n"
	yq -p csv -o json ${FILENAME} > ${FILENAME_JSON}
	# jq 'sort_by(.Date_str__c, .User__c, .Action__c)' ${FILENAME_JSON} > ${FILENAME_JSON}2
	# mv ${FILENAME_JSON}2 ${FILENAME_JSON}

	MODE="process"
fi


if [[ $MODE == "process" ]]; then
	# Generate hash per line for External Id field
	echo -e "- Generating Hashes\n"
	rm -f ${FILENAME_JSON}2
	SECONDS=0

	ORG_URL_NAME="$(sf org display -o ${ORG_NAME} --json 2>/dev/null | jq -r '.result.instanceUrl' | cut -d "." -f 1 | cut -c 9-)"
	# ORG_URL_NAME="ausnetservices--preprod"
	echo -e "Org URL Name: ${ORG_URL_NAME}"
	SIZE="$(jq 'length' SetupAuditTrail.json)"

	# Iterate json, process each line
	i=0
	prior_line=""
	prior_count=1
	while IFS= read -u 10 -r line ; do
		((i=i+1))
		# echo "$i : $line"
		echo -ne "\033[2K\r"
		echo -ne "$i / $SIZE  "

		# generate hash
		hash="$(sha1sum <<< "$line" | cut -d " " -f 1)"

		# get date str
		datestr="$(jq -r '.Date' <<< "$line")"

		# add key to structure
		jq -c ". += { hash: \"$datestr-$hash\", orgName: \"$ORG_URL_NAME\" }" <<< "$line" >> ${FILENAME_JSON}2
		prior_line="$line"

		# if [[ $i -ge 10000 ]]; then
		# 	break;
		# fi

	done 10< <(jq -c '.[]' ${FILENAME_JSON})
	echo ""

	# Reconstruct JSON back into array
	echo -e "- Reconstruct JSON back into array\n"
	sort -u -o ${FILENAME_JSON}2 ${FILENAME_JSON}2
	jq --slurp '.' ${FILENAME_JSON}2 > ${FILENAME_JSON}3
	mv ${FILENAME_JSON}3 ${FILENAME_JSON}2
	# cat ${FILENAME_JSON}2
	# exit 1;

	# Rename keys
	echo -e "- Rename keys\n"
		# Date -> Date_str__c
		# User -> User__c
		# Source Namespace Prefix -> Source_Namespace_Prefix__c
		# Action -> Action__c
		# Section -> Section__c
		# Delegate User -> Delegate_User__c
		# hash -> Hash__c
		# orgName -> Org_Name__c
	jq 'map(
	with_entries(
		if .key == "Date" then .key = "Date_str__c" 
		elif .key == "User" then .key = "User__c"
		elif .key == "Source Namespace Prefix" then .key = "Source_Namespace_Prefix__c"
		elif .key == "Action" then .key = "Action__c"
		elif .key == "Section" then .key = "Section__c"
		elif .key == "Delegate User" then .key = "Delegate_User__c"
		elif .key == "hash" then .key = "Hash__c"
		elif .key == "orgName" then .key = "Org_Name__c"
		else .
		end
	)
	)' ${FILENAME_JSON}2 > ${FILENAME_JSON}3
	mv ${FILENAME_JSON}3 ${FILENAME_JSON}2

	# convert back to CSV
	echo -e "- convert back to CSV\n"
	yq -p json -o csv ${FILENAME_JSON}2 > ${FILENAME}2
fi


# Auto open file
if [[ ${AUTO_OPEN} == "TRUE" ]]; then
	echo "Opening file: $FILENAME."
	open $FILENAME
fi

echo -e "\nTime taken: ${SECONDS} seconds."
exit 0;
