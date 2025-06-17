#!/bin/bash
SECONDS=0

set -e

ORG_NAME=""
ORG_URL_NAME=""
REPORT_ORG_NAME=""
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
	USAGE="$0 -o org-name --reporting-org org-name [--open-file]"

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

		grepp()
		{
			if [ "$(uname)" == "Darwin" ]; then
				ggrep "$@"
			else
				grep "$@"
			fi
		}
		export -f grepp

	# end functions

	# read args
		while [ $# -gt 0 ] ; do
			case $1 in
				-u | -o) ORG_NAME="$2"
					shift;;

				-r | --reporting-org) REPORT_ORG_NAME="$2"
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
	if [[ $REPORT_ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your reporting org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi
# end setup


# header
	title
	echo -e "Org name: ${WHITE}${ORG_NAME}${RESTORE}\n"
# end header


ORG_URL_NAME="$(sf org display -o ${ORG_NAME} --json 2>/dev/null | jq -r '.result.instanceUrl' | cut -d "." -f 1 | cut -c 9-)"
echo -e "Org URL Name: ${ORG_URL_NAME}"

orgName="$(jq -r ".[] | select(.subdomain==\"$ORG_URL_NAME\") .name" org-names.json)"
if [[ $orgName == "" ]]; then
	orgName="$ORG_URL_NAME"
fi

# start here
if [[ $MODE == "download" ]]; then

	# tidy
	rm -f cookiejar

	# Get authentication URL
	echo -e "${GREEN}*${RESTORE} Get authentication URL from SFDX"
	CURRENT_URL="$(sf org open -o ${ORG_NAME} -p ${PAGE_NAME} -r --json 2> /dev/null | jq -r '.result.url' | tee url.txt)"
	echo -e "- ${CURRENT_URL}\n"
	NEXT_URL="$(curl ${CURL_OPTS} --url "$(cat url.txt)" --silent | grepp -oP -m1 "https://[\w\-\.\/\?=&%]+" | head -1)"
	rm -f url.txt

	# Follow Javascript redirect, ensure cookies set are transmitted with the request
	echo -e "${GREEN}*${RESTORE} Following Javascript redirect"
	PREV_URL="${CURRENT_URL}"
	CURRENT_URL="${NEXT_URL}"
	NEXT_URL=$(curl ${CURL_OPTS} -b cookiejar -e ${PREV_URL} ${CURRENT_URL} --silent | grepp SetupAuditTrail | grepp -oP "href=\"/serv(.+?)\"" | head -1 | cut -d "\"" -f 2)

	# Find and Construct the CSV URL from PREV_URL host and CURR_URL pathname, also translate &amp; into &
	echo -e "${GREEN}*${RESTORE} Finding CSV URL and downloading"
	PREV_URL="${CURRENT_URL}"
	CURRENT_URL="$(echo -e ${PREV_URL} | grepp -oP "https://[\w\-\.]+")${NEXT_URL}"
	CURRENT_URL="$(sed "s/\&amp;/\&/g" <<< "${CURRENT_URL}")"
	echo -e "- ${CURRENT_URL}\n"

	# Follow the CSV link
	# FILENAME="SetupAuditTrail-${ORG_NAME}-$(date +"%d-%b-%Y").csv"
	curl ${CURL_OPTS} -b cookiejar -J -o ${FILENAME} -e ${PREV_URL} ${CURRENT_URL}
	echo ""
	rm -f cookiejar

	MODE="preprocess"
fi


if [[ $MODE == "preprocess" ]]; then

	# TODO processing
	# TODO: Not carriage return safe
	echo -e "${GREEN}*${RESTORE} Processing CSV"


	# TODO
	# Get latest record from Salesforce, and trim the JSON file to only include records after that date
	echo -e "- Find last upsert"
	cat <<- EOF > .query.soql
		SELECT Id, Org_Name__c, Date__c, Date_str__c,
		User__c, Source_Namespace_Prefix__c, Action__c, Section__c, Delegate_User__c, Hash__c, Status__c
		FROM Audit_Log__c
		WHERE Org_Name__c = '$orgName'
		ORDER BY Date__c DESC
		LIMIT 1
	EOF

	sf data query -o ${REPORT_ORG_NAME} -f .query.soql --json > data.json
	rm -f .query.soql

	# ensure status is 0
	if [[ "$(jq -r '.status' data.json)" == "0" ]]; then
		echo "success"

		size="$(jq -r '.result.totalSize' data.json)"
		if [[ $size -gt 0 ]]; then

			jq '.result.records[0] | del(.attributes) |
				with_entries(
				if .value == null or .value == "null" then .value = "" else . end
			)' data.json > data.json2 && \
			mv data.json2 data.json

			# cat <<- EOF > .jq.str
			# 	"\"" + .Date_str__c + "\",\"" + .User__c + "\",\"" + .Source_Namespace_Prefix__c + "\",\"" + .Action__c + "\",\"" + .Section__c + "\",\"" + .Delegate_User__c + "\""
			# EOF
			cat <<- EOF > .jq.str
				.Date_str__c
			EOF
			jq -r "$(cat .jq.str)" data.json > .string
			rm -f .jq.str

			cat .string
			LINE_NUM="$(grep -n "$(cat .string)" ${FILENAME} | cut -d : -f 1 | head -n1)"
			echo -e "Last record found in CSV file at line: ${LINE_NUM}"
			rm .string

			# delete lines $LINE_NUM until end of file
			sed "${sedi[@]}" "${LINE_NUM},\$d" ${FILENAME}
		else
			echo "No records found in Audit Log."
			echo "setting limit to 5000"
			LINE_NUM=5001
			sed "${sedi[@]}" "${LINE_NUM},\$d" ${FILENAME}
		fi

	fi
	# exit;
	rm data.json

	# if file has only one line, then we have no data
	if [[ $(wc -l < ${FILENAME} | grepp -Po '\d+') -le 1 ]]; then
		echo -e "No changes found in Audit Log. Exiting."
		exit 1
	fi

	# TODO do we convert to json? yes
	echo -e "- Convert to JSON\n"
	yq -p csv -o json ${FILENAME} > ${FILENAME_JSON}

	jq 'map(
		if (.Action | type == "object")
		then .Action |= (to_entries | map("\(.key): \(.value)") | join(", "))
		else . end
	)' ${FILENAME_JSON} > ${FILENAME_JSON}2
	mv ${FILENAME_JSON}2 ${FILENAME_JSON}

	MODE="process"
fi



if [[ $MODE == "process" ]]; then
	# Generate hash per line for External Id field
	echo -e "- Generating Hashes\n"
	rm -f ${FILENAME_JSON}2
	SECONDS=0

	# Iterate json, process each line
	i=0
	SIZE="$(jq 'length' SetupAuditTrail.json)"
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
		jq -c ". += { hash: \"$datestr-$ORG_URL_NAME-$hash\", orgName: \"$orgName\" }" <<< "$line" >> ${FILENAME_JSON}2

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
	jq 'map(with_entries(
		if .key == "Date" then .key = "Date_str__c"
		elif .key == "User" then .key = "User__c"
		elif .key == "Source Namespace Prefix" then .key = "Source_Namespace_Prefix__c"
		elif .key == "Action" then .key = "Action__c"
		elif .key == "Section" then .key = "Section__c"
		elif .key == "Delegate User" then .key = "Delegate_User__c"
		elif .key == "hash" then .key = "Hash__c"
		elif .key == "orgName" then .key = "Org_Name__c"
		else . end
	))' ${FILENAME_JSON}2 > ${FILENAME_JSON}3
	mv ${FILENAME_JSON}3 ${FILENAME_JSON}2

	# replace nulls with empty strings
	echo -e "- Replace nulls with empty strings\n"
	jq 'map(with_entries(
		if .value == null then .value = "" else . end
	))' ${FILENAME_JSON}2 > ${FILENAME_JSON}3
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
