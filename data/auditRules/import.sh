#!/bin/bash
SECONDS=0
# set -e
# set -o pipefail
cd "$(dirname "$BASH_SOURCE")"
OPERATION="Import"
source options.sh


# Setup
	YELLOW="\033[33;1m"
	GREEN="\033[32;1m"
	WHITE="\033[97;1m"
	RED="\033[91;1m"
	RESTORE="\033[0m"
	USAGE="$0 (-o <org_name> | --default) [--flush-data]"
	VERSION="1.2"
	AUTHOR="vc@vaughancrole.com"

	ORG_NAME=""
	FLUSH_DATA="FALSE"

	while [ $# -gt 0 ] ; do
		case $1 in
			-o | --target | --targetusername ) ORG_NAME="$2"
				shift;;

			--default ) ORG_NAME="$(sfdx force:config:get defaultusername --json | egrep value | cut -d "\"" -f 4)";;

			--flush-data) FLUSH_DATA="TRUE";;
 
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

echo -e "${GREEN}* ${RESTORE}${OPERATION}ing data to ${WHITE}${ORG_NAME}${RESTORE}."

# TODO: Note flushing the table is destructive and may cause problems later.
#       This needs to be rewritten to only find and delete orphaned records (not in the CSVs)
#       Don't use this flag in pipeline please.
if [[ $FLUSH_DATA == "TRUE" ]]; then
	echo -e "Flushing tables..."

	for (( i=0; i<${#objectArray[@]}; i++ )); do
		OBJ_NAME="${objectArray[i]}"
		echo "delete [SELECT Id FROM ${OBJ_NAME}];" >> .flush.apex
	done

	sfdx apex:run -f .flush.apex -u $ORG_NAME | egrep Executed\|Error
	rm .flush.apex
	echo ""
fi


## loop through objectArray
for (( i=0; i<${#objectArray[@]}; i++ ));
do
	OBJ_NAME="${objectArray[i]}"
	UPSERT_FLD="${idLookupArray[i]}"
	CSV_NAME="${objectArray[i]}.csv"

	echo "- $OBJ_NAME: Upserting... "

	sfdx force:data:bulk:upsert -s "${OBJ_NAME}" -f "${CSV_NAME}" -i "${UPSERT_FLD}" -u ${ORG_NAME} -w 15 --json > output
	ERROR_CODE=$?

	if [ $ERROR_CODE -ne 0 ]; then
		echo -e "${RED}*** Error: ${RESTORE}"
		cat output;
		exit $ERROR_CODE;
	fi

	BULK_ID="$(grep "\"id\"" output| cut -d "\"" -f 4)"
	COMPLETED="$(grep numberBatchesCompleted output| cut -d "\"" -f 4)"
	PROCESSED="$(grep numberRecordsProcessed output | cut -d "\"" -f 4)"
	FAILED="$(grep numberRecordsFailed output | cut -d "\"" -f 4)"
	rm output

	if [ $FAILED -ne 0 ]; then
		echo -ne "${RED}*** Error: "
		echo -e "Completed: ${COMPLETED}, Records processed: ${PROCESSED}, Failures: ${FAILED}, Bulk Job ID [${BULK_ID}]\n"
		echo -ne "${RESTORE}"
		exit 1;
	else
		echo -e "Completed: ${COMPLETED}, Records processed: ${PROCESSED}, Failures: ${FAILED}, Bulk Job ID [${BULK_ID}]\n"
	fi
done

echo -e "${GREEN}Success.${RESTORE} Data ${OPERATION} complete."

echo -e "Time taken: ${SECONDS} seconds.\n"
exit 0;
