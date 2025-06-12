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
	USAGE="$0 -o <org-name> --object <sf-object-name> --where <sql-query-criteria> (--limit <num-rows>)"
	ORG_NAME=""

	OBJ_NAME=""
	QUERY=""
	SKIP_CONFIRM="FALSE"
	TOOLING_API=""
	LIMIT="500000"

	title()
	{
		echo -e "${GRN}*** ${WHT}Flush object script v${VERSION}${RES}\nby ${GRN}vc@vaughancrole.com${RES}\n"
	}
	export -f title

	pause()
	{
		read -p "Press Enter to continue."
	}
	export -f pause

	confirm()
	{
		if [[ ${SKIP_CONFIRM} == "FALSE" ]]; then
			echo -ne "${WHT}"
			read -n 1 -p "Do you wish to continue (y/n)? " choice
			echo -e "${RES}"
			case "$choice" in
				y|Y) echo -e "Yes.\n";;

				n|N) echo -e "No."
					exit 0;;

				*) echo -e "${RED}* Error: ${RES}Invalid input."
				exit 1;;
			esac
		fi
	}
	export -f confirm

	while [ $# -gt 0 ] ; do
		case $1 in
			-u | -o | --target-org) ORG_NAME="$2"
				shift;;

			--object | --obj) OBJ_NAME="$2"
				shift;;

			--where | -w) WHERE="$2"
				shift;;

			--limit | -l) LIMIT="$2"
				shift;;

			-y) SKIP_CONFIRM="TRUE";;

			-t | --use-tooling-api) TOOLING_API="--use-tooling-api";;

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

	if [[ $OBJ_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify object name. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi

	if [[ $WHERE == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your query criteria. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi

	if [[ $LIMIT == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your query limit. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi
# end setup

title
echo -e "${GRN}*${RES} Org name: ${WHT}$ORG_NAME${RES}"
echo -e "${GRN}*${RES} Object to flush: ${WHT}$OBJ_NAME${RES}"
echo -e "${GRN}*${RES} SOQL Criteria: ${WHT}$WHERE${RES}\n"

CSV_FILENAME="flush-${OBJ_NAME}.csv"

sfdx config:set org-max-query-limit=$LIMIT > /dev/null

# TODO get number
COUNT_QRY="SELECT COUNT(Id) numRecs FROM ${OBJ_NAME} WHERE ${WHERE}"
NUM_RECS="$(sfdx force:data:soql:query -o ${ORG_NAME} -q "${COUNT_QRY}" -r json ${TOOLING_API} | egrep numRecs | egrep -o "[[:digit:]]+$")"
echo -e "${GRN}*${RES} Number of records found: ${WHT}$NUM_RECS${RES}"

if [[ $NUM_RECS -eq 0 ]]; then
	echo -e "No records to flush, exiting now."
	exit 0;
fi

echo -e "\n${GRN}*** ${WHT}Do you wish to proceed with this operation?${RES}"
echo -e "This will ${RED}delete ${NUM_RECS} records${RES} from the ${WHT}${OBJ_NAME}${RES} object in the ${WHT}${ORG_NAME}${RES} org."
echo -e "${RED}THIS CANNOT BE UNDONE.${RES}\n"
confirm

QUERY="SELECT Id FROM ${OBJ_NAME} WHERE ${WHERE}"

if [[ $NUM_RECS -lt 1000 ]]; then
	# use apex
	FILENAME="flush-${OBJ_NAME}.apex"
	rm -rf ${FILENAME}
	echo "delete [${QUERY}];" > ${FILENAME}
	sf apex run -o ${ORG_NAME} -f ${FILENAME} | grep -E Compiled\|Executed\|Error
	rm ${FILENAME}

else
	# use bulk
	sfdx force:data:soql:query -o ${ORG_NAME} -q "${QUERY}" -r csv ${TOOLING_API} > ${CSV_FILENAME}

	if [ ! -f ${CSV_FILENAME} ]; then
		echo -e "Nothing to do."
	fi

	sfdx force:data:bulk:delete -o ${ORG_NAME} -f ${CSV_FILENAME} -s ${OBJ_NAME} -w 10
	rm ${CSV_FILENAME}
fi
