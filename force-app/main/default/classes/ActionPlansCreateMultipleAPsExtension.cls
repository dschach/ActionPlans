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
public inherited sharing class ActionPlansCreateMultipleAPsExtension {

    private ApexPages.StandardSetController standardController;

    public String objIDs { get; private set; }

    public ActionPlansCreateMultipleAPsExtension(ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
        Set<Id> selected = new Map<Id, SObject>(standardController.getSelected()).keySet();
        List<Id> objIDsList = new List<Id>(selected);
        /* for(Id i : selected){
            objIDsList.add((String)i);
        } */
        objIDs = String.join(objIDsList,',');
    }

    public PageReference doRedirect() {
        if(String.isBlank(objIDs)){
            return null;
        }

        Pagereference pageRef = Page.ActionPlanCreation;

        Id firstId = objIDs.split(',')[0];
        String objType = firstId.getSobjectType().getDescribe().getLabel();
        String objPrefix = firstId.getSobjectType().getDescribe().getKeyPrefix();
        System.debug('refids ' + objIDs);
        System.debug('reftype ' + objType);
        pageRef.getParameters().put('refType', objType);
        pageRef.getParameters().put('refId', objIDs);
        pageRef.getParameters().put('retURL', '/' + objPrefix + '/o' );
        pageRef.setRedirect(true);
        System.debug('redirecting to new page ' + pageRef.getURL());
        return pageRef;


        /* Set<Id> selected = new Map<Id, SObject>(standardController.getSelected()).keySet();
        //delete [SELECT Id FROM ActionPlan__c WHERE Id IN :selected];

        List<Id> recordIds = new List<Id>();
        recordIds.addAll(selected);
        ActionPlansBatchDelete aPBatch = new ActionPlansBatchDelete(recordIds);
        Database.ExecuteBatch( aPBatch );

        return standardController.cancel(); */
    }
}