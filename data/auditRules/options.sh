## declare an array variable of all extract queries WITH linking external IDs
## please place ORDER BY <<ID Lookup field>> clause at the end for consistency in extract outputs
declare -a queryArray=(
	"SELECT Sequence__c, Field__c, Condition__c, Value__c, Permission__c FROM Audit_Rule__c ORDER BY Sequence__c ASC"
)

declare -a objectArray=(
	"Audit_Rule__c"
)

declare -a idLookupArray=(
	"Sequence__c"
)
