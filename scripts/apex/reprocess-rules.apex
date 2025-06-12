// Apex script
// Select all Audit_Log__c records and reprocess them through the rules engine

List<Audit_Log__c> auditLogs = [SELECT Id, Status__c FROM Audit_Log__c WHERE Status__c = 'Bad' ORDER BY LastModifiedDate ASC LIMIT 10000];

if (auditLogs == null || auditLogs.isEmpty()) return; // No logs to process

for (Audit_Log__c log : auditLogs)
	log.Status__c = 'New';

update auditLogs;
