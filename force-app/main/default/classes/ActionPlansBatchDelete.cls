/*
Action Plans v4
David Schach 2021

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

BSD 3-Clause License

Copyright (c) 2021, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
global inherited sharing class ActionPlansBatchDelete implements Database.Batchable<SObject>, Database.Stateful{

	private Set<Id> relActionPlansIds;

	/**
	* Constructor
	*/
	public ActionPlansBatchDelete( Set<Id> oIDsSet){

		relActionPlansIds = oIDsSet;

	}

	/**
	* Use the start method to collect the records or objects to be passed to the interface method execute
	*/
	global Database.QueryLocator start( Database.BatchableContext bc ){

		String soql = 'SELECT Id FROM ActionPlan__c WHERE Id IN :relActionPlansIds';
		return Database.getQueryLocator( soql );

	}

	/**
	*
	* @param bc
	* @param data
	*/
	global void execute( Database.BatchableContext bc, List<SObject> data ){
		Set<Id> actionPlanIDs = new Set<Id>();
		for( SObject s : data ){
			actionPlanIDs.add((Id)s.get('Id'));
		}
		try{
			deleteActionPlans(actionPlanIDs);
			if (ActionPlansTestUtilities.forceError){
				String str = null;
				str.toLowerCase();
			}
		} catch(Exception e){
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
				FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		   // If there were any errors Send an email to the Apex job's submitter
		   // notifying of job completion
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {a.CreatedBy.Email};
			mail.setToAddresses(toAddresses);
			mail.setSubject('EXCEPTION during Action Plans Batch deletion  ' + a.Status);
			mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches.\nError :' + makeEmailBody(e) );
			if(ActionPlansUtilities.canSendEmails()){
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
		}
	}

	global void deleteActionPlans(Set<Id> relActionPlansIds) {

		List<ActionPlan__c> relActionPlans = [SELECT Id FROM ActionPlan__c WHERE Id IN :relActionPlansIds LIMIT :ActionPlansUtilities.MAX_APTODELETE];
		Map<Id, APTaskTemplate__c> relTaskTemplateMap = new Map<Id, APTaskTemplate__c>([SELECT Id FROM APTaskTemplate__c WHERE Action_Plan__c IN :relActionPlansIds]);
		List<Task> relTaskList = [SELECT Id FROM Task WHERE IsClosed = false AND TaskAPTaskTemplate__c IN :relTaskTemplateMap.keySet()];

		if(!relActionPlans.isEmpty()){
			List<Database.DeleteResult> results = Database.delete( relActionPlans );
		}

		if(!relTaskList.isEmpty()){
			List<Database.DeleteResult> results = Database.delete( relTaskList );
		}
	 }

	 private String makeEmailBody(Exception e){
		String emailBody = '';
		emailBody += 'Exception type caught: ' + e.getTypeName();
		emailBody += 'Message: ' + e.getMessage();
		emailBody += 'Cause: ' + e.getCause();
		emailBody += 'Line number: ' + e.getLineNumber();
		emailBody += 'Stack trace: ' + e.getStackTraceString();
		return emailBody;
	 }

	/**
	*
	*/
	global void finish( Database.BatchableContext bc ){}

}