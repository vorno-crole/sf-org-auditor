@isTest
private class Test_Trig_AuditLog
{

	@testSetup
	static void setup() 
	{
		/*
        Case testCase = new Case(
			Subject = 'New Case',
			Origin = 'Web'
		);
		insert testCase;

		System.assertNotEquals(null, testCase.Id, 'Failed to insert testCase');
        */
	}

	/*
    @isTest
	static void testCaseTriggerHandler() 
	{
		Case testCase = new Case(
			Subject = 'New Case',
			Origin = 'Web'
		);
		insert testCase;

		for (Case c: [SELECT Id, CaseNumber, Subject, Origin FROM Case WHERE Id = :testCase.Id])
			System.assertEquals('Trigger ' + testCase.Subject, c.Subject);

		testCase.Subject = 'Subject 2';
		update testCase;

		for (Case c: [SELECT Id, CaseNumber, Subject, Origin FROM Case WHERE Id = :testCase.Id])
			System.assertEquals('Trigger ' + testCase.Subject, c.Subject);

		Trig_Case.TrigDisabled = true;
		testCase.Subject = 'Subject 3';
		update testCase;

		for (Case c: [SELECT Id, CaseNumber, Subject, Origin FROM Case WHERE Id = :testCase.Id])
			System.assertEquals(testCase.Subject, c.Subject);

		Trig_Case.TrigDisabled = false;
		TrigSettings__c trigSet = new TrigSettings__c();
		trigSet.Case_Trigger_Disabled__c = true;
		trigSet.SetupOwnerId = UserInfo.getOrganizationId();
		insert trigSet;
		
		testCase.Subject = 'Subject 4';
		update testCase;

		for (Case c: [SELECT Id, CaseNumber, Subject, Origin FROM Case WHERE Id = :testCase.Id])
			System.assertEquals(testCase.Subject, c.Subject);

		delete testCase;

		undelete testCase;
	}
    */
}