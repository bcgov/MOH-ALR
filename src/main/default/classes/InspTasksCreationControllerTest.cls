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
        
        ActionPlanTemplate apt1 = New ActionPlanTemplate(ActionPlanType='',Name='SN Application Inspection',UniqueName='SN_Application_Inspection_ffafb54c_e85a_11ee_9032_cbd0374f6064' );
        ActionPlanTemplate apt2 = New ActionPlanTemplate(ActionPlanType='',Name='MH Application Inspection',UniqueName='MH_Application_Inspection_42a1e36e_e84f_11ee_8eb2_2993cc7f45f7' );
        insert new List<ActionPlanTemplate>{apt1,apt2};
            List<ActionPlanTemplate> apt = [Select id,ActionPlanType,Status from ActionPlanTemplate Limit 3];
        
        ActionPlanTemplateVersion  aptv1 = new ActionPlanTemplateVersion (Status='Final',Name='SN Application Inspection',ActionPlanTemplateId=apt[0].id);
        ActionPlanTemplateVersion  aptv2 = new ActionPlanTemplateVersion (Status='Final',Name='MH Application Inspection',ActionPlanTemplateId=apt[1].id); 
        insert new List<ActionPlanTemplateVersion>{aptv1,aptv2};  
            List<ActionPlanTemplateVersion> aptv =[Select id from ActionPlanTemplateVersion  Limit 3];
       
        ActionPlanTemplateItem apti1 = new ActionPlanTemplateItem (Name ='Test1',ActionPlanTemplateVersionId = aptv[0].id,ItemEntityType ='AssessmentTask', UniqueName='X2_Application_Fee_01d0e828_b560_11ee_a19c_358c7fbe009f');
        ActionPlanTemplateItem apti2 = new ActionPlanTemplateItem (Name ='Test2',ActionPlanTemplateVersionId = aptv[1].Id,ItemEntityType ='AssessmentTask', UniqueName='X6_References_cc8ad63f_b561_11ee_a19c_55f955ca2de8' );
        insert new List<ActionPlanTemplateItem>{apti1,apti2};
            List <ActionPlanTemplateItem> apti = [Select Id from ActionPlanTemplateItem Limit 3 ];
        
        List<InspTasksCreationController.FlowInputs> flowInputs = new List<InspTasksCreationController.FlowInputs>();
        InspTasksCreationController.FlowInputs input = new InspTasksCreationController.FlowInputs();
        input.ATIId = new List<String>{apti[0].id, apti[1].id};
            input.InspId = inspec.id;
        flowInputs.add(input);
        AssessmentTaskDefinition aTD1 = new AssessmentTaskDefinition(Name='Health and Safety SN Application	',TaskType ='InspectionChecklist',Category__c='Health and Safety');
        AssessmentTaskDefinition aTD2 = new AssessmentTaskDefinition(Name='Emergency Preparedness SN Application',TaskType ='InspectionChecklist',Category__c='Emergency Preparedness');
        insert new List<AssessmentTaskDefinition>{aTD1, aTD2};
            List<AssessmentTaskDefinition> atd = [Select id from AssessmentTaskDefinition];
                ActionPlanTemplateItemValue aPTIV1 = new ActionPlanTemplateItemValue( ValueLiteral=atd[0].id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=apti[0].id, Name='AssessmentTaskDefinitionId');
        ActionPlanTemplateItemValue aPTIV2 = new ActionPlanTemplateItemValue( ValueLiteral=atd[1].id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=apti[1].id , Name='AssessmentTaskDefinitionId' );
        insert new List<ActionPlanTemplateItemValue>{aPTIV1, aPTIV2};
            List<ActionPlanTemplateItemValue> aptiv = [Select id from ActionPlanTemplateItemValue];
        Test.startTest();
        InspTasksCreationController.getActionPlanItemIds(flowInputs);
        Test.stopTest();
        System.assert(InspTasksCreationController.getActionPlanItemIds(flowInputs) == null, 'Its not null');
        
        
    }
    
}