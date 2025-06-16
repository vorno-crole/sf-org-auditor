#!/bin/bash
SECONDS=0
sedi=(-i) && [ "$(uname)" == "Darwin" ] && sedi=(-i '')

# Setup
	set -e
	# set -o pipefail

	YLW="\033[33;1m"
	GRN="\033[32;1m"
	WHT="\033[97;1m"
	RED="\033[91;1m"
	RES="\033[0m"
	VERSION="1.0"
	SCRIPT_NAME="Get and Upsert Audit Trail CSV"
	USAGE="$0 -o target-org-name (--source org-name | --all)"

	UPSERT_ORG_NAME=""
	GET_ORG_NAME=""
	FILE_NAME="SetupAuditTrail.csv2"
	MODE="normal"
	ALL_ORGS=()

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
		BREAK=""
		while [[ $# -gt 0 && $BREAK == "" ]]; do
			case $1 in
				-u | -o | --target-org | -r) UPSERT_ORG_NAME="$2"
					shift;;

				--source | -s) GET_ORG_NAME="$2"
					shift;;

				--all) MODE="all"
					# load all orgs into the array
					while IFS= read -u 10 -r alias; do
						ALL_ORGS+=("$alias")
					done 10< <(jq -r '.[] .alias' org-names.json);;

				-h | --help) title
							 echo -e $USAGE
							 exit 0;;

				--) BREAK="TRUE";;

				*) echo -e "${RED}*** ERROR: ${RES}Invalid option: ${WHITE}$1${RES}. See usage:"
				echo -e $USAGE
				exit 1;;
			esac
			shift
		done
	# end read args

	if [[ ${MODE} == "normal" && $GET_ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your source org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi

	if [[ $UPSERT_ORG_NAME == "" ]] ; then
		echo -e "${RED}*** Error: ${RES}Specify your reporting org name alias. See usage:"
		echo -e "${WHT}$USAGE${RES}"
		exit 1
	fi
# end setup


# header
	title
	if [[ ${MODE} == "normal" ]] ; then
		echo -e "Source Org name: ${WHT}${GET_ORG_NAME}${RES}"
		ALL_ORGS=("${GET_ORG_NAME}")
	else
		echo -e "Source Org name: ${GRN}All orgs in ${WHT}${ALL_ORGS[*]}${RES}"
	fi

	echo -e "Upsert Org name: ${WHT}${UPSERT_ORG_NAME}${RES}"
# end header

cd "$(dirname "$BASH_SOURCE")"
cd ../..



# loop through all orgs if --all is specified
for GET_ORG_NAME in "${ALL_ORGS[@]}" ; do
	if [[ ${MODE} == "all" ]] ; then
		echo -e "\n${YLW}Getting audit trail for ${GET_ORG_NAME}${RES}"
	fi

	scripts/shell/get-audit-trail.sh -o ${GET_ORG_NAME} -r ${UPSERT_ORG_NAME} "$@" || continue;
	scripts/shell/upsert-audit-trail.sh -o ${UPSERT_ORG_NAME} --filename ${FILE_NAME}
done

rm -f SetupAuditTrail.csv*
rm -f SetupAuditTrail.json*

echo -e "${GRN}Success.${RES} Complete."
echo -e "\nTime taken: ${SECONDS} seconds."
exit 0;
