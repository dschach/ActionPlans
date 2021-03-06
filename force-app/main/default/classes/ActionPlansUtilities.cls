/*
Action Plans v4
David Schach 2021

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
public without sharing class ActionPlansUtilities {

	/*************
	 * CONSTANTS *
	*************/

	// Max number of APTasks per Action Plan
	public static final Integer MAX_APTASKS = 400;

	// Max number of Action Plans that can be deleted from list
	public static final Integer MAX_APTODELETE = 1000;

    //public static final Boolean HAS_RECORD_TYPE = Task.sObjectType.getDescribe().fields.getMap().containsKey('recordtypeid');
    public static final Id MASTER_RECORD_TYPE_ID = '012000000000000AAA';

	public static final Boolean HAS_RECORD_TYPE = setHasRecordType();

	/**
	 * @description Actions to perform whenever loading a Visualforce page
	 * Ensures that Custom Setting is created for the org
	 * @return   null PageReference
	 */
	public static PageReference onPageLoad(){
		getCustomSetting();
		return null;
	}

	/**
	 * Allows us to force the environment variable checking if Task has a Record Type for testing. Increases code coverage.
	 */
	private static Boolean setHasRecordType(){
		if(ActionPlansTestUtilities.forceHasRecordType != null){
			return ActionPlansTestUtilities.forceHasRecordType;
		} else {
			ActionPlansTestUtilities.forceHasRecordType = Task.sObjectType.getDescribe().fields.getMap().containsKey('recordtypeid');
		}
		return ActionPlansTestUtilities.forceHasRecordType;
	}


	/**
	 * Section to describe ActionPlan object to make custom relationship fields dynamic
	 */

	private static List<String> apCustomRelationshipFields;

	public static List<String> getCustomRelationshipFields(){
		if(apCustomRelationshipFields == null){
			List<String> referenceFieldNames = new List<String>();

			Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.ActionPlan__c.fields.getMap();

			for(String s : fieldMap.keyset()){

				if(s.containsIgnoreCase('.')){ continue; }
				Schema.DescribeFieldResult dfr = fieldMap.get(s).getDescribe();
				Schema.DisplayType dt = dfr.getType();
				if(dt.name().equalsIgnoreCase('Reference') && s.endsWithIgnoreCase('__c')){
					String relatedObjectName = dfr.getReferenceTo()[0].getDescribe().getName();
					if( !relatedObjectName.startsWithIgnoreCase('ActionPlan') )
					{
						referenceFieldNames.add(s);
					}
				}
			}
			apCustomRelationshipFields = referenceFieldNames;
		}
		//System.debug('Related Fields: ' + apCustomRelationshipFields);
		return apCustomRelationshipFields;
	}

	/**
	* Get prefix of sObject
	* @param objName
	* @return obj.getKeyPrefix()
	*/
	public static String getObjectKeyPrefix( String objName ){
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objName ).getDescribe();
		return obj.getKeyPrefix();
	}

	/**
	 * Lazy load task record types to reduce queries
	 * @since 4
	 */
	private static List<SObject> getTaskRecordTypes(){
		if(taskRecordTypes == null){
			String taskRTQuery = 'SELECT Id, IsActive, Name FROM RecordType WHERE SObjectType = \'Task\' AND IsActive = true ORDER BY Name ASC';
			taskRecordTypes = Database.query(taskRTQuery);
		}
		return taskRecordTypes;
	}
	private static List<SObject> taskRecordTypes;

	/**
	 * Generate Map of Record Type Id to default Task Status
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypeStatusDefaultValues(){
		if(taskRecordTypeStatusDefaultValues == null){
			taskRecordTypeStatusDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypeStatusDefaultValues.put((Id)rt.get('Id'), t.Status);
				}
			} else {
				taskRecordTypeStatusDefaultValues.put(null, (String)Task.Status.getDescribe().getDefaultValue());
			}

		}
		return taskRecordTypeStatusDefaultValues;
	}
	private static Map<Id, String> taskRecordTypeStatusDefaultValues;

	/**
	 * Generate Map of Record Type Id to default Task Type
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypeTypeDefaultValues(){
		if(taskRecordTypeTypeDefaultValues == null){
			taskRecordTypeTypeDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypeTypeDefaultValues.put((Id)rt.get('Id'), t.Type);
				}
			} else {
				Task t = (Task)Task.sObjectType.newSObject(null, true);
				taskRecordTypeTypeDefaultValues.put(null, t.Type);
			}
		}
		return taskRecordTypeTypeDefaultValues;
	}
	private static Map<Id, String> taskRecordTypeTypeDefaultValues;


	/**
	 * Generate Map of Record Type Id to default Task Priority
	 * @since 4
	 */
	public static Map<Id, String> getTaskRecordTypePriorityDefaultValues(){
		if(taskRecordTypePriorityDefaultValues == null){
			taskRecordTypePriorityDefaultValues = new Map<Id, String>();
			if(ActionPlansUtilities.HAS_RECORD_TYPE){
				for( SObject rt : getTaskRecordTypes() ){
					Task t = (Task)Task.sObjectType.newSObject((Id)rt.get('Id'), true);
					taskRecordTypePriorityDefaultValues.put((Id)rt.get('Id'), t.Priority);

				}
			} else {
				taskRecordTypePriorityDefaultValues.put(null, (String)Task.Priority.getDescribe().getDefaultValue());
			}
		}
		return taskRecordTypePriorityDefaultValues;
	}
	private static Map<Id, String> taskRecordTypePriorityDefaultValues;

	/**
	 * Find user default recordtype
	 * @since 4
	 */
	public static String getDefaultTaskRecordTypeId(){
		String toReturn = null;
		if(ActionPlansUtilities.HAS_RECORD_TYPE){
			List<Schema.RecordTypeInfo> recordTypeInfoList = Task.SObjectType.getDescribe().getRecordTypeInfos();
			for(RecordTypeInfo info : recordTypeInfoList) {
				//Check default record type
				if(info.isDefaultRecordTypeMapping()){
					toReturn = info.getRecordTypeId();
					break;
				}
			}
		}
		return toReturn;
	}

	/**
	 * Generate picklist of Task Record Types
	 * @since 4
	 */
	public static List<SelectOption> getTaskRTPicklistValues(){
		if(taskRTs == null){
			taskRTs = new List<SelectOption>();
			for( SObject rt : getTaskRecordTypes()){
				SelectOption so = new SelectOption((String)rt.get('Id'), (String)rt.get('Name'), !(Boolean)rt.get('IsActive'));
				taskRTs.add(so);
			}
		}
		return taskRTs;
	}
	private static List<SelectOption> taskRTs;

	/**
	 * Lazy load open task statuses
	 * @since 4
	 */
	public static Set<String> getOpenTaskStatuses(){
		if(openTaskStatuses == null){
			openTaskStatuses = new Set<String>();
			for(TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = false]){
				openTaskStatuses.add(ts.MasterLabel);
			}
		}
		return openTaskStatuses;
	}
	private static Set<String> openTaskStatuses;

	/**
	 * Find all closed Task statuses
	 * @return List of completed statuses
	 */
	private static Set<String> closedTaskStatuses;
	public static Set<String> getClosedTaskStatuses(){
		if(closedTaskStatuses == null){
			closedTaskStatuses = new Set<String>();
			for(TaskStatus ts : [SELECT IsClosed, MasterLabel FROM TaskStatus WHERE IsClosed = true]){
				closedTaskStatuses.add(ts.MasterLabel);
			}
		}
		return closedTaskStatuses;
	}

	/**
	 * Get a Visualforce picklist from any object and field
	 * @param objectname    the object name
	 * @param fieldname     the field name
	 * @return              List<SelectOption>
	 */
	public static List<SelectOption> getFieldOptions(String objectname, String fieldname, Boolean hasDefaultValue){
		List<SelectOption> toReturn = new List<SelectOption>();
		Schema.DescribeSObjectResult obj = Schema.getGlobalDescribe().get( objectname ).getDescribe();
		Schema.SObjectField sof = obj.fields.getMap().get(fieldname);

		for(Schema.PicklistEntry spe : sof.getDescribe().getPicklistValues()){
			if(spe.isDefaultValue()){
				hasDefaultValue = true;
			}
			toReturn.add(new Selectoption(spe.getValue(), spe.getLabel()));
		}
		if(hasDefaultValue == null || !hasDefaultValue){
			toReturn.add( 0, new SelectOption( '', '--' + System.Label.ap_None +'--' ) );
		}
		return toReturn;
	}

	/**
	* Set the Hours for select box of Reminder Time
	* @return options
	*/
	public static List<SelectOption> getHoursOption() {

 	 	List<SelectOption> options = new List<SelectOption>();
 	 	options.add( new SelectOption( '0',  '12:00 AM'  ) );
 	 	options.add( new SelectOption( '30', '12:30 AM'  ) );
		options.add( new SelectOption( '60', '1:00 AM'   ) );
		options.add( new SelectOption( '90', '1:30 AM'   ) );
		options.add( new SelectOption( '120', '2:00 AM'  ) );
		options.add( new SelectOption( '150', '2:30 AM'  ) );
		options.add( new SelectOption( '180', '3:00 AM'  ) );
		options.add( new SelectOption( '210', '3:30 AM'  ) );
		options.add( new SelectOption( '240', '4:00 AM'  ) );
		options.add( new SelectOption( '270', '4:30 AM'  ) );
		options.add( new SelectOption( '300', '5:00 AM'  ) );
		options.add( new SelectOption( '330', '5:30 AM'  ) );
		options.add( new SelectOption( '360', '6:00 AM'  ) );
		options.add( new SelectOption( '390', '6:30 AM'  ) );
		options.add( new SelectOption( '420', '7:00 AM'  ) );
		options.add( new SelectOption( '450', '7:30 AM'  ) );
		options.add( new SelectOption( '480', '8:00 AM'  ) );
		options.add( new SelectOption( '510', '8:30 AM'  ) );
		options.add( new SelectOption( '540', '9:00 AM'  ) );
		options.add( new SelectOption( '570', '9:30 AM'  ) );
		options.add( new SelectOption( '600', '10:00 AM' ) );
		options.add( new SelectOption( '630', '10:30 AM' ) );
		options.add( new SelectOption( '660', '11:00 AM' ) );
		options.add( new SelectOption( '690', '11:30 AM' ) );
		options.add( new SelectOption( '720', '12:00 PM' ) );
		options.add( new SelectOption( '750', '12:30 PM' ) );
		options.add( new SelectOption( '780', '1:00 PM'  ) );
		options.add( new SelectOption( '810', '1:30 PM'  ) );
		options.add( new SelectOption( '840', '2:00 PM'  ) );
		options.add( new SelectOption( '870', '2:30 PM'  ) );
		options.add( new SelectOption( '900', '3:00 PM'  ) );
		options.add( new SelectOption( '930', '3:30 PM'  ) );
		options.add( new SelectOption( '960', '4:00 PM'  ) );
		options.add( new SelectOption( '990', '4:30 PM'  ) );
		options.add( new SelectOption( '1020', '5:00 PM' ) );
		options.add( new SelectOption( '1050', '5:30 PM' ) );
		options.add( new SelectOption( '1080', '6:00 PM' ) );
		options.add( new SelectOption( '1110', '6:30 PM' ) );
		options.add( new SelectOption( '1140', '7:00 PM' ) );
		options.add( new SelectOption( '1170', '7:30 PM' ) );
		options.add( new SelectOption( '1200', '8:00 PM' ) );
		options.add( new SelectOption( '1230', '8:30 PM' ) );
		options.add( new SelectOption( '1260', '9:00 PM' ) );
		options.add( new SelectOption( '1290', '9:30 PM' ) );
		options.add( new SelectOption( '1320', '10:00 PM' ) );
		options.add( new SelectOption( '1350', '10:30 PM' ) );
		options.add( new SelectOption( '1380', '11:00 PM' ) );
		options.add( new SelectOption( '1410', '11:30 PM' ) );

 	 	return options;
  	}

	/**
	* Verifies that the user is able to add reminders.
	* Checks the existence of a reminder setting field of the user object.
	* Mathod can be improved by asking for Reminder Options at Activity settings.
	* Does not query if the user wants reminders by default
	* @return if the user has access to reminders
	*/
	public static Boolean getCanDisplayReminder(){
		if(canDisplayReminder == null){
			canDisplayReminder = Schema.sObjectType.User.fields.getMap().containsKey('UserPreferencesTaskRemindersCheckboxDefault');
		}
		return canDisplayReminder;
	}
	private static Boolean canDisplayReminder;

	/**
	 * Check user preferences for whether to show task reminders by default
	 * @return Boolean if Task reminder checkbox should be checked by default (this will override default value)
	 * @since 4
	 */
	public static Boolean getCheckReminderByDefault(){
		if(checkReminderByDefault == null){
			checkReminderByDefault = false;
			if(getCanDisplayReminder()){
				String reminderQuery = 'SELECT Name, UserPreferencesTaskRemindersCheckboxDefault FROM User WHERE Id = \'' + UserInfo.getUserId() + '\'';
				List<SObject> sList = Database.query(reminderQuery);
				checkReminderByDefault = (Boolean)sList[0].get('UserPreferencesTaskRemindersCheckboxDefault');
			}
		}
		return checkReminderByDefault;
	}
	private static Boolean checkReminderByDefault;

	/**
	* Gets task reminder default time for current user
	* @return String picklist value
	*/
	public static String getDefaultReminderMinutes(){
		if(defaultMinutesForReminderTime == null){
			Map<String, Schema.SObjectField> fieldsMap = Schema.sObjectType.User.fields.getMap();
			defaultMinutesForReminderTime = '480';

			List<UserPreference> uP = [SELECT Value
										FROM UserPreference
										WHERE UserId = :Userinfo.getUserId() AND Preference = '58'];
			if ( !uP.isEmpty() ){
				defaultMinutesForReminderTime = uP[0].Value;
			}
		}
		return defaultMinutesForReminderTime;
	}
	private static String defaultMinutesForReminderTime;

	/**
	* Get the "Default" Custom Setting and return it.
	* @return cSetting
	*/
	public static Action_Plans_Settings__c getCustomSetting(){
		Action_Plans_Settings__c instance;
		instance = Action_Plans_Settings__c.getOrgDefaults();
		if(instance.Id == null){
			instance = new Action_Plans_Settings__c(SetupOwnerId = UserInfo.getOrganizationId());
			instance.Action_Plans_Business_Hours_ID__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true].Id;
			instance.Default_Object_on_Lead_Conversion__c = 'Contact';
			upsert instance;
		}

		instance = Action_Plans_Settings__c.getInstance();
		return instance;

	}

	/**
	 * Single method to shorten long strings to the hard-coded 80 character length of record name field
	 * @param the long string
	 * @return the full string or shortened if longer than 80 characters
	 */
	public static String actionPlanSubjectToName(String subject){
		return actionPlanSubjectToName(subject, 80);
	}

	/**
	 * Single method to shorten long strings to the dynamically described character length of record name field
	 * @param the long string
	 * @return the full string or shortened if longer than max characters
	 */
	public static String actionPlanSubjectToName(String subject, Integer maxChars){
		if(subject == null){System.debug('NULL SUBJECT'); return null;}
		if( subject.trim().length() > maxChars ){
			return subject.left(maxChars - 3).trim() + '...';
		}
		return subject;
	}


	//private static Boolean orgCanSendEmails;
	public static Boolean canSendEmails() {
		Boolean orgCanSendEmails;
		if (orgCanSendEmails == null){
			// An attempt to reserve some email capacity is the only means available for determining permissions
			// or limits issues. In the case of a lack of permissions, System.NoAccessException is thrown. If
			// limits are exhausted then System.HandledException is thrown
			try {
				Messaging.reserveSingleEmailCapacity(1);

				orgCanSendEmails = true;
			} catch (Exception e) {
				orgCanSendEmails = false;
			}
		}

		return orgCanSendEmails;
	}

	public static String getDayOfWeek(Date d){

		Date monday = Date.newInstance(1900, 1, 1);
		Integer dayOfWeek = Math.mod(monday.daysBetween(d), 7);
		return dayOfWeekEnglish.get(dayOfWeek);

	}

	public static Map<Integer, String> dayOfWeekEnglish = new Map<Integer, String>{
		0 => 'Monday', 1 => 'Tuesday', 2 => 'Wednesday', 3 => 'Thursday', 4 => 'Friday', 5 => 'Saturday', 6 => 'Sunday'
	};

	public static Weekend_Day__mdt getWeekendDay(String developerName){
		return Weekend_Day__mdt.getInstance(developerName);
	}

	/**
	 * Given a task due date, we adjust it here for weekends
	 * @param actionPlanStartDate the start date of the action plan
	 * @param taskDaysFromStart the days after the initial date that the task will be due
	 * @return the new task due date
	 */
	public static Date adjustTaskDueDate(Date actionPlanStartDate, Integer taskDaysFromStart, String apSkipDay){

		Date dueDate = actionPlanStartDate.addDays( taskDaysFromStart );

		// find if the due date fall on a Saturday or Sunday.  Add 1 day for Sunday and 2 for Saturday
		//Date refDate        = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sun
		//Integer dayOfWeek   = Math.mod(refDate.daysBetween(dueDate), 7); // 0 = Sun ... 6 = Sat

		String dayName = ActionPlansUtilities.getDayOfWeek( dueDate );

		Weekend_Day__mdt cmdt = ActionPlansUtilities.getWeekendDay(dayName);  //Weekend_Day__mdt.getInstance(dayName);

		Integer addDays = 0;

		if( apSkipDay != null && apSkipDay.startsWithIgnoreCase('End')){
			Integer daysToAdjust = cmdt.Days_from_end_of_previous_week__c.intValue();
			addDays = addDays - daysToAdjust;
		}
		else if( apSkipDay != null && apSkipDay.startsWithIgnoreCase('Start')){
			Integer daysToAdjust = cmdt.Days_to_start_of_next_week__c.intValue();
			addDays = addDays + daysToAdjust;
		}
		/* if(addDays != 0){
			System.debug('Task is now due on a ' + ActionPlansUtilities.getDayOfWeek( dueDate.addDays( addDays ) ));
		} */
		return dueDate.addDays( addDays );
	}

	/*******
	 * Detect user theme
	 */
	public static Boolean getIsLex(){
		return ( UserInfo.getUiThemeDisplayed().containsIgnoreCase('theme4') );
	}
}
