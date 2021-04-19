/*
Action Plans v4
Updated by David Schach 2021

Action Plans v3
Force.com Labs
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2011, salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
	* Neither the name of the salesforce.com, inc. nor the names of its contributors
	may be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public inherited sharing class ActionPlanTemplateDetailController {

	public ActionPlanTemplate__c 	actionPlanTemplate;
	public Document                 actionPlanExportXMLDoc { get; set; }
	public Boolean					taskHasRecordType		{ get; set; }

	/**
	 * Constructor
	 * If we can obtain the Id from the page parameters then we search for that template and set the variable for that template.
	 * If we can't obtain the Id from the page parameters then we create a new template and obtain from the controller.
	 */
	public ActionPlanTemplateDetailController ( ApexPages.StandardController stdController ){

		actionPlanTemplate = ( ActionPlanTemplate__c ) stdController.getRecord();

		taskHasRecordType = ActionPlansMetadataUtility.HAS_RECORD_TYPE;

	}

	/**
	 * Convert Record Type Id to Record Type Name
	 * @return Record Type Name
	 */
	public String getRecordTypeName(){
		String toReturn = '';

		if( taskHasRecordType && actionPlanTemplate.TaskRecordTypeID__c != null ){
			Map<Id,Schema.RecordTypeInfo> rtMapById = Task.SObjectType.getDescribe().getRecordTypeInfosById();
			if(!rtMapById.isEmpty() && rtMapById.containsKey(actionPlanTemplate.TaskRecordTypeID__c)){
				return rtMapById.get(actionPlanTemplate.TaskRecordTypeID__c).getName();
			}
		}
		return toReturn;
	}

	/**
	 * Call method deleteTemplate()
	 * @return PageReference
	 */
	public PageReference deleteTemplate(){
		try{
			delete actionPlanTemplate;
		} catch( Exception e ){	Apexpages.addMessages( e );	return null; }

		// Send the user to the detail page for the new account.
		PageReference newPage = new PageReference( '/' + Schema.ActionPlanTemplate__c.SObjectType.getDescribe().getKeyPrefix() + '/o' );
		newPage.setRedirect( true );

		return newPage;
	}

	/**
	 * Call method getTemplateTasks()
	 * @return List<APTTaskTemplate__c>
	 */
	public List<APTTaskTemplate__c> getTemplateTasks(){
		return [SELECT a.Type__c, a.Subject__c, a.Priority__c, a.Dependent__c, a.Name, a.User__c, TaskIndex__c,
							 a.User__r.Name, a.Id, a.DaysFromStart__c, a.CreatedById, a.Action_Plan_Template__c, a.APTTaskTemplate__c,
							 a.APTTaskTemplate__r.Subject__c, a.Reminder__c, a.SendEmail__c, a.Comments__c
							 FROM APTTaskTemplate__c a
							 WHERE a.Action_Plan_Template__c = :actionPlanTemplate.Id  ORDER BY TaskIndex__c ASC];
	}

	/**
	 * Flush the viewstate to make cloning work
	 * Commenting for now; will add this functionality
	 * @return PageReference pageRef edit page
	 */
	/* public PageReference cloneTemplate(){
		Pagereference pageRef = Page.ActionPlanTemplateCreation;
		pageRef.getParameters().put('id', actionPlanTemplate.Id);
		pageRef.getParameters().put( 'clone', '1' );

		pageRef.setRedirect(true);
		return pageRef;
	} */

	/**
	* Method exports the Action Plan template into a new XML document
	*/
	public void exportTemplateToXMLDoc(){
		ExportActionPlanTemplate utility = new ExportActionPlanTemplate( actionPlanTemplate.Id );

		actionPlanExportXMLDoc = utility.export();
	}

}