trigger AuditLogTrigger on Audit_Log__c (before insert, after insert, before update, after update, before delete, after delete, after undelete)
{
	UtilTrigDispatch.Run(new Trig_AuditLog(), Trigger.operationType);
}