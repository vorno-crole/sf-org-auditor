public with sharing class Rule_Processor
{
	// ************************************************
	// usage:
	//		Rule_Processor.Permission perm = Rule_Processor.getRP().checkLog(my_Audit_Log_record);
	//		if (perm == Rule_Processor.Permission.ALLOW)
	//		if (perm == Rule_Processor.Permission.DENY)





	// ************************************************
	// *** Member vars
	public enum Permission {ALLOW, DENY}

	private List<Audit_Rule__c> rules;
	private static Rule_Processor RP;

	private static Map<String, String> fieldMap = new Map<String,String> // Rule field => Log API field name
	{
		'User'      => 'User__c',
		'Namespace' => 'Source_Namespace_Prefix__c',
		'Action'    => 'Action__c',
		'Section'   => 'Section__c'
	};


	// ************************************************
	// *** Constructor
	public Rule_Processor()
	{
		loadRules();
	}


	// ************************************************
	// *** Static methods
	public static Rule_Processor getRP()
	{
		if (RP == null) RP = new Rule_Processor();
		return RP;
	}


	// ************************************************
	// *** Instance methods
	private void loadRules()
	{
		rules = [SELECT Id, Name, Sequence__c, Field__c, Condition__c, Value__c, Permission__c FROM Audit_Rule__c ORDER BY Sequence__c ASC];
	}

	public Permission checkLog(Audit_Log__c AL)
	{
		String output;

		for (Audit_Rule__c rule: rules)
		{
			String ruleField = rule.Field__c;
			String ruleCond  = rule.Condition__c;
			String ruleValue = rule.Value__c;
			String rulePerm  = rule.Permission__c;

			if (ruleCond != null && ruleCond == 'catch all')
			{
				// apply catch all, break;
				output = ruleValue;
				break;
			}

			if (ruleField == null || ruleCond == null || ruleValue == null || rulePerm == null)
			{
				// big error
				System.debug(System.LoggingLevel.ERROR, 'Fatal error: Rule invalid. Cannot continue.');
				return null;
			}

			String logField = fieldMap.get(ruleField);
			String logValue;

			if (AL.get(logField) != null) logValue = (String)AL.get(logField);

			switch on ruleCond
			{
				when 'equals'
				{
					if (logValue == ruleValue)
					{
						output = rulePerm;
						break;
					}
				}

				when 'does not equal'
				{
					if (logValue != ruleValue)
					{
						output = rulePerm;
						break;
					}
				}

				when 'starts with'
				{
					if (logValue.startsWith(ruleValue))
					{
						output = rulePerm;
						break;
					}
				}

				when else
				{
					// big error
					System.debug(System.LoggingLevel.ERROR, 'Error: Rule invalid. Attempting to continue.');
					continue;
				}
			}
		}

		// maybe we have an output now?
		return getPermEnum(output);
	}

	public Permission getPermEnum(String strPerm)
	{
		if (strPerm == null) 
		{
			System.debug('getPermEnum is null.');
			return null;
		}

		if (strPerm == 'Allow') return Permission.ALLOW;
		if (strPerm == 'Deny') return Permission.DENY;
		return null;
	}
}