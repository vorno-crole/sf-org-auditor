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
		setDateField((List<Audit_Log__c>)newSObjs);
		checkApplyRules((List<Audit_Log__c>)newSObjs);
	}

	public override void BeforeUpdate(Map<Id, SObject> newSObjs, Map<Id, SObject> oldSObjs)
	{
		setDateField((List<Audit_Log__c>)newSObjs.values());
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
			{
				//newStatus = CatchAllStatus;
				System.debug('applyRules: permission is null. Skipping record.');
				continue;
			}

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

	@testvisible private void setDateField(List<Audit_Log__c> logItems)
	{
		for (Audit_Log__c log: logItems)
		{
			if (log.Date_str__c != null && log.Date__c == null)
			{
				// Create a Datetime value from the date string
				// "7/07/2023 10:45:24 AM"
				String dateStr = log.Date_str__c;

				// TODO check string format

				// 12/6/2025, 1:08:37 pm AEST
				// String regex = '^\d{1,2}\/\d{1,2}\/\d{2,4}, \d{1,2}:\d{2}:\d{2} (am|pm) AEST';

				List<String> DT_Parts = dateStr.split(' '); // 0: date 1: time 2: am/pm 3: tz
				List<String> D_Parts = DT_Parts[0].split('/'); // 0: dd 1: mm 2: yyyy
				List<String> T_Parts = DT_Parts[1].split(':'); // 0: h 1: m 2: ss

				Integer day = Integer.valueOf(D_Parts[0]);
				Integer mth = Integer.valueOf(D_Parts[1]);
				Integer yr  = Integer.valueOf(D_Parts[2].removeEnd(','));

				Integer hr  = Integer.valueOf(T_Parts[0]);
				Integer min = Integer.valueOf(T_Parts[1]);
				Integer sec = Integer.valueOf(T_Parts[2]);

				if (DT_Parts[2].toLowerCase() == 'pm')
					hr += 12;

				DateTime dt = DateTime.newInstance(yr, mth, day, hr, min, sec);

				log.Date__c = dt;
			}
		}
	}
}
