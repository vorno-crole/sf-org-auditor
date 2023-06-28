public abstract class UtilTrigHandle
{
	public abstract void BeforeInsert(List<SObject> newSObjs);

	public abstract void BeforeUpdate(Map<Id, SObject> newSObjs, Map<Id, SObject> oldSObjs);

	public abstract void BeforeDelete(Map<Id, SObject> oldSObjs);

	public abstract void AfterInsert(Map<Id, SObject> newSObjs);

	public abstract void AfterUpdate(Map<Id, SObject> newSObjs, Map<Id, SObject> oldSObjs);

	public abstract void AfterDelete(Map<Id, SObject> oldSObjs);

	public abstract void AfterUndelete(Map<Id, SObject> oldSObjs);

	public abstract String getTriggerObject();

	public abstract Boolean getTrigDisabled();


	// *********************************************************************
	// *** Disable logic
	public Boolean IsDisabled()
	{
		if (TrigSettings__c.getInstance() == null || TrigSettings__c.getInstance().get(getTriggerObject() + '_Trigger_Disabled__c') == null)
			return getTrigDisabled();

		Boolean TrigSettingDisabled = (Boolean)TrigSettings__c.getInstance().get(getTriggerObject() + '_Trigger_Disabled__c');
		
		if (TrigSettingDisabled == null || TrigSettingDisabled)
			return true;

		return getTrigDisabled();
	}


	// *********************************************************************
	// *** Helper methods
	public void SetOpType(System.TriggerOperation TrigOp)
	{
		switch on TrigOp
		{
			when BEFORE_INSERT {
				isBefore = true; isInsert = true;
			} 
			when BEFORE_UPDATE {
				isBefore = true; isUpdate = true;
			} 
			when BEFORE_DELETE {
				isBefore = true; isDelete = true;
			} 
			when AFTER_INSERT {
				isAfter = true; isInsert = true;
			} 
			when AFTER_UPDATE {
				isAfter = true; isUpdate = true;
			} 
			when AFTER_DELETE {
				isAfter = true; isDelete = true;
			} 
			when AFTER_UNDELETE {
				isAfter = true; isUndelete = true;
			}
		}
	}

	public Boolean isBefore = false, isAfter = false;
	public Boolean isInsert = false, isUpdate = false, isDelete = false, isUndelete = false;
}
