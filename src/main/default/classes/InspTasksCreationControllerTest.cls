@isTest
public class InspTasksCreationControllerTest {
    public static testMethod void testInsert(){
        List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
        Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);
        Account acc = [Select Id from Account Where Name ='residence1'];
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
        loc.Longitude = 28.635308;
        loc.Latitude = 28.635308;
        insert loc;
        Set<Id>loct = New Set<Id>();
        List<Schema.location> loction =[select id,Name from Location where Name ='U.S. 101N'];
        
        for(Account acc1 : accList){
            AssociatedLocation assosicatedloc = new AssociatedLocation();
            assosicatedloc.ParentRecordId = acc1.Id;
            assosicatedloc.LocationId = loc.Id;
            accList2.add(assosicatedloc);
        }
        insert accList2;
        
        Set<Id> accSet= new Set<Id>();
        for(Account acc3 : accList){
            AccSet.add(acc3.Id);
        }
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection';
        insert insType;
        Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        finalList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE  Id IN : AccSet];
        
        Visit insp = new Visit();
        insp.AccountId =acc.id;
        insp.InspectionMethod__c ='Scheduled on Site Inspection';
        insp.PlannedVisitStartTime = System.today();
        insp.PlaceId = loction[0].Id;
        insp.VisitTypeId =insType.Id;
        Insert insp;
        Visit inspec = [Select id from Visit where AccountId =:acc.id Limit 1];
        
        ActionPlanTemplate apt1 = New ActionPlanTemplate(ActionPlanType='Retail', TargetEntityType = 'Visit', Name='SN Application Inspection1', UniqueName='SN_Application_Inspection1_ffafb54c_e85a_11ee_9032_cbd0374f6064');
        insert apt1;
        ActionPlanTemplate apt2 = New ActionPlanTemplate(ActionPlanType='Retail', TargetEntityType = 'Visit', Name='MH Application Inspection1',UniqueName='MH_Application_Inspection1_42a1e36e_e84f_11ee_8eb2_2993cc7f45f7');
        insert apt2;
        List<ActionPlanTemplate> actiontemp = new List<ActionPlanTemplate>();
        actiontemp.add(apt1);
        actiontemp.add(apt2);
            List<ActionPlanTemplate> apt = [Select id,ActionPlanType,Status from ActionPlanTemplate WHERE Id =: apt1.Id LIMIT 3];
        
        ActionPlanTemplateVersion  aptv1 = new ActionPlanTemplateVersion (Name='SN Application Inspection1',ActionPlanTemplateId=apt1.id);
        insert aptv1;
        ActionPlanTemplateVersion  aptv2 = new ActionPlanTemplateVersion (Name='MH Application Inspection1',ActionPlanTemplateId=apt2.id); 
        insert aptv2;
        List<ActionPlanTemplateVersion> actiontempversion = new List<ActionPlanTemplateVersion>();
        actiontempversion.add(aptv1);
        actiontempversion.add(aptv2);
        
        List<ActionPlanTemplateVersion> aptv =[Select id from ActionPlanTemplateVersion WHERE Id =: aptv1.Id Limit 3];
       
        ActionPlanTemplateItem apti1 = new ActionPlanTemplateItem (Name ='Test1',ActionPlanTemplateVersionId = aptv1.id,ItemEntityType ='AssessmentTask', UniqueName='X2_Application_Fee1_01d0e828_b560_11ee_a19c_358c7fbe009f');
        insert apti1;
        ActionPlanTemplateItem apti2 = new ActionPlanTemplateItem (Name ='Test2',ActionPlanTemplateVersionId = aptv2.Id,ItemEntityType ='AssessmentTask', UniqueName='X6_References1_cc8ad63f_b561_11ee_a19c_55f955ca2de8' );
        insert apti2;
        List<ActionPlanTemplateItem> actiontempitem = new List<ActionPlanTemplateItem>();
        actiontempitem.add(apti1);
        actiontempitem.add(apti2);
        
        List <ActionPlanTemplateItem> apti = [Select Id from ActionPlanTemplateItem WHERE Id =: apti1.Id Limit 3 ];
        
        List<InspTasksCreationController.FlowInputs> flowInputs = new List<InspTasksCreationController.FlowInputs>();
        InspTasksCreationController.FlowInputs input = new InspTasksCreationController.FlowInputs();
        List<String> aptistring = new List<String>();
        aptistring.add(apti1.Id);
        input.ATIId = aptistring;
            input.InspId = inspec.id;
        flowInputs.add(input);
        AssessmentTaskDefinition aTD1 = new AssessmentTaskDefinition(Name='Health and Safety SN Application	',TaskType ='InspectionChecklist',Category__c='Health and Safety');
        insert atD1;
        AssessmentTaskDefinition aTD2 = new AssessmentTaskDefinition(Name='Emergency Preparedness SN Application',TaskType ='InspectionChecklist',Category__c='Emergency Preparedness');
        insert atD2;
        List<AssessmentTaskDefinition> assessTskDef = new List<AssessmentTaskDefinition>();
        assessTskDef.add(aTD1);
        assessTskDef.add(aTD2);
        
        List<AssessmentTaskDefinition> atd = [Select id from AssessmentTaskDefinition WHERE Id =: aTD1.Id];
        ActionPlanTemplateItemValue aPTIV1 = new ActionPlanTemplateItemValue( ValueLiteral=aTD1.Id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=apti1.id, Name='AssessmentTaskDefinitionId');
        insert aPTIV1;
        ActionPlanTemplateItemValue aPTIV2 = new ActionPlanTemplateItemValue( ValueLiteral=aTD2.id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=apti2.id , Name='AssessmentTaskDefinitionId' );
        insert aPTIV2;
        List<ActionPlanTemplateItemValue> actionplantemitemvalue = new List<ActionPlanTemplateItemValue>();
        actionplantemitemvalue.add(aPTIV1);
        actionplantemitemvalue.add(aPTIV2);
            
        List<ActionPlanTemplateItemValue> aptiv = [Select id,ItemEntityFieldName, ValueLiteral, ActionPlanTemplateItemId from ActionPlanTemplateItemValue WHERE ActionPlanTemplateItemId =: apti1.id AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName];
        Set<Id> LiteralValues = new Set<Id>();
        for(ActionPlanTemplateItemValue aptiv3 : aptiv){
            LiteralValues.add(aptiv3.ValueLiteral);
        }
        
        List<AssessmentTask> ATstoInsert = new List<AssessmentTask>();
        AssessmentTask  newAssessmentTask = new AssessmentTask();
        newAssessmentTask.Name = aTD1.Category__c;
        newAssessmentTask.AssessmentTaskDefinitionId = aTD1.Id;
        newAssessmentTask.ParentId = insp.Id;
        newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
        insert newAssessmentTask;
        //ATstoInsert.add(newAssessmentTask);

        Test.startTest();
        InspTasksCreationController.getActionPlanItemIds(flowInputs);
        Test.stopTest();
        System.assert(InspTasksCreationController.getActionPlanItemIds(flowInputs) == null, 'Its not null');
        
        
    }
    
}