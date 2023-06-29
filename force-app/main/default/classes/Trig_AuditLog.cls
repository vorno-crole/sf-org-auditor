public with sharing class Trig_AuditLog extends UtilTrigHandle
{
	// *********************************************************************
	// *** Trigger settings
	// Ensure this is set to the object API name.
	public override String getTriggerObject() { return 'Audit_Log'; }

	public static Boolean TrigDisabled = false;
	public override Boolean getTrigDisabled() { return TrigDisabled; }


	// *********************************************************************
	// *** Trigger contexts
	public override void BeforeInsert(List<SObject> newSObjs)
	{
		checkApplyRules((List<Audit_Log__c>)newSObjs);
	}

	public override void BeforeUpdate(Map<Id, SObject> newSObjs, Map<Id, SObject> oldSObjs)
	{
		checkApplyRules((List<Audit_Log__c>)newSObjs.values());
	}

	// if context is not implemented, condense into one-liners
	public override void BeforeDelete(Map<Id, SObject> oldSObjs) {}
	public override void AfterInsert(Map<Id, SObject> newSObjs) {}
	public override void AfterUpdate(Map<Id, SObject> newSObjs, Map<Id, SObject> oldSObjs) {}
	public override void AfterDelete(Map<Id, SObject> oldSObjs) {}
	public override void AfterUndelete(Map<Id, SObject> oldSObjs) {}


	// *********************************************************************
	// *** Trigger methods
	private static String CatchAllStatus = AL_Strings.LOG_STATUS_BAD;


	@testvisible private void checkApplyRules(List<Audit_Log__c> newLogItems)
	{
		if (newLogItems == null || newLogItems.isEmpty()) return;

		List<Audit_Log__c> qualified = new List<Audit_Log__c>();
		for (Audit_Log__c log: newLogItems)
		{
			if (log.Status__c == AL_Strings.LOG_STATUS_NEW)
				qualified.add(log);
		}

		if (!qualified.isEmpty()) applyRules(qualified);
	}

	@testvisible private void applyRules(List<Audit_Log__c> logItems)
	{
		for (Audit_Log__c log: logItems)
		{
			String newStatus;

			// run rules
			Rule_Processor.Permission perm = Rule_Processor.getRP().checkLog(log);

			// catch all
			if (perm == null)
				newStatus = CatchAllStatus;

			if (perm == Rule_Processor.Permission.ALLOW)
			{
				// this is ok
				newStatus = AL_Strings.LOG_STATUS_GOOD;
			}
			else if (perm == Rule_Processor.Permission.DENY)
			{
				// this is less than ok
				newStatus = AL_Strings.LOG_STATUS_BAD;
			}

			log.Status__c = newStatus;
		}
	}
}
