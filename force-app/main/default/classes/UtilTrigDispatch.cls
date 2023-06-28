public class UtilTrigDispatch
{
	public static void Run(UtilTrigHandle handler, System.TriggerOperation TriggerEvent)
	{
		// Check to see if the trigger has been disabled. If it has, return
		if (handler.IsDisabled())
		{
			String handlerName = String.valueOf(handler).split(':')[0];
			System.debug('*** [UtilTrigDispatch] Trigger class disabled, skipping: ' + handlerName);
			return;
		}

		handler.SetOpType(TriggerEvent);

		// Detect the current trigger context and fire the relevant methods on the trigger handler:
		switch on TriggerEvent
		{
			when BEFORE_INSERT {
				handler.BeforeInsert(Trigger.new);
			} when BEFORE_UPDATE {
				handler.BeforeUpdate(Trigger.newMap, Trigger.oldMap);
			} when BEFORE_DELETE {
				handler.BeforeDelete(Trigger.oldMap);
			} when AFTER_INSERT {
				handler.AfterInsert(Trigger.newMap);
			} when AFTER_UPDATE {
				handler.AfterUpdate(Trigger.newMap, Trigger.oldMap);
			} when AFTER_DELETE {
				handler.AfterDelete(Trigger.oldMap);
			} when AFTER_UNDELETE {
				handler.AfterUndelete(Trigger.oldMap);
			}
		}
	}
}
