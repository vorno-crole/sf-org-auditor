#!/bin/bash
SECONDS=0

set -e

ORG_NAME=""
PAGE_NAME="//setup/org/orgsetupaudit.jsp?setupid=SecurityEvents"
CURL_OPTS="-c cookiejar -L"
CURRENT_URL=""
PREV_URL=""
FILENAME="SetupAuditTrail.csv"
FILENAME_JSON="$(basename -s .csv $FILENAME).json"
AUTO_OPEN="FALSE"

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

# tidy
rm -f cookiejar

# Get authentication URL
echo -e "${GREEN}*${RESTORE} Get authentication URL from SFDX"
CURRENT_URL="$(sf org open -o ${ORG_NAME} -p ${PAGE_NAME} -r --json 2> /dev/null | jq -r '.result.url' | tee url.txt)"
echo -e "- ${CURRENT_URL}\n"
NEXT_URL="$(curl ${CURL_OPTS} --url "$(cat url.txt)" --silent | tee curl.log | ggrep -oP -m1 "https://[\w\-\.\/\?=&%]+" | head -1)"

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

# TODO processing
# TODO: Not carriage return safe
echo -e "${GREEN}*${RESTORE} Processing CSV"
# sed -i '/"deploymentuser@ue./d' $FILENAME
# sed -i '/"vaughan.crole@powercor.com.au.ched.uecat"/d' $FILENAME
# sed -i '/"Manage Users"/d' $FILENAME

# TODO do we convert to json? yes?
echo -e "- Convert to JSON\n"
yq -p csv -o json ${FILENAME} > ${FILENAME_JSON}



# Generate hash per line for External Id field
echo -e "- Generating IDs\n"



# Iterate json
linenum=0
while IFS= read -u 10 -r line ; do
	((linenum=linenum+1))
	echo $linenum

	# generate hash
	# add key to structure
	# add org name to structure
	# add date string? to structure

	if [[ $linenum -ge 10 ]]; then
		break;
	fi

done 10< <(jq -c '.[]' ${FILENAME_JSON})


exit 1;

FILENAME2="${FILENAME}2"
rm -f $FILENAME2
prior_line=""
while read -r line ; do
	((linenum=linenum+1))
	# echo $linenum

	if [[ $linenum == 1 ]]; then
		# line 1
			# add "Id," to start of line
			# echo "Id,$line" > $FILENAME2

		echo "Hash__c,Org_Name__c,Date_str__c,User__c,Source_Namespace_Prefix__c,Action__c,Section__c,Delegate_User__c"  > $FILENAME2

	else
		# line 2+:  compute and add hash to start of line

		# Check for duplicate lines
		if [[ "$prior_line" == "$line" ]]; then
			continue;
		fi

		# Some CSV rows are multiline. Need to identify these lines and process accordingly
		# Check if line starts with reg ex....
		if echo "$line" | grep -q -E '^"[[:digit:]]{1,2}/[[:digit:]]{1,2}/[[:digit:]]{4} [[:digit:]]{1,2}:[[:digit:]]{1,2}:[[:digit:]]{1,2} (AM|PM)",'; then
			hash="$(echo "$line" | sha1sum | cut -d " " -f 1)"

			# get field 1 (date)
			datestr="$(echo "$line" | cut -d "," -f 1 | tr -d '"')"

			echo "\"$datestr-$hash\",${ORG_NAME},$line" >> $FILENAME2
		else
			echo "$line" >> $FILENAME2

		fi
	fi

	prior_line="$line"
done < $FILENAME

mv $FILENAME2 $FILENAME

# Auto open file
if [[ ${AUTO_OPEN} == "TRUE" ]]; then
	echo "Opening file: $FILENAME."
	open $FILENAME
fi

echo -e "\nTime taken: ${SECONDS} seconds."
exit 0;
