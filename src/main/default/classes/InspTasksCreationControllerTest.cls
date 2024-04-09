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
        
        Set<Id> AccSet= new Set<Id>();
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
        
        ActionPlanTemplate Apt1 = New ActionPlanTemplate(ActionPlanType='Retail',TargetEntityType='Visit',Name='SN Application Inspection');
        ActionPlanTemplate Apt2 = New ActionPlanTemplate(ActionPlanType='Retail',TargetEntityType='Visit',Name='MH Application Inspection');
        insert new List<ActionPlanTemplate>{Apt1,Apt2};
            List<ActionPlanTemplate> Apt = [Select id,ActionPlanType,Status from ActionPlanTemplate Where ActionPlanType='Retail'];
        
        ActionPlanTemplateVersion  Aptv1 = new ActionPlanTemplateVersion (Status='Final',Name='SN Application Inspection',ActionPlanTemplateId=Apt[0].id);
        ActionPlanTemplateVersion  Aptv2 = new ActionPlanTemplateVersion (Status='Final',Name='MH Application Inspection',ActionPlanTemplateId=Apt[1].id); 
        insert new List<ActionPlanTemplateVersion>{Aptv1,Aptv2};  
            List<ActionPlanTemplateVersion> Aptv =[Select id from ActionPlanTemplateVersion where Status='Draft'];
        
        ActionPlanTemplateItem Apti1 = new ActionPlanTemplateItem (Name ='Test1',ActionPlanTemplateVersionId	=Aptv[0].id,ItemEntityType ='AssessmentTask' );
        ActionPlanTemplateItem Apti2 = new ActionPlanTemplateItem (Name ='Test2',ActionPlanTemplateVersionId	=Aptv[1].Id,ItemEntityType ='AssessmentTask' );
        insert new List<ActionPlanTemplateItem>{Apti1,Apti2};
            List <ActionPlanTemplateItem> Apti = [Select Id from ActionPlanTemplateItem  ];
        
        List<InspTasksCreationController.FlowInputs> flowInputs = new List<InspTasksCreationController.FlowInputs>();
        InspTasksCreationController.FlowInputs input = new InspTasksCreationController.FlowInputs();
        input.ATIId = new List<String>{Apti[0].id, apti[1].id};
            input.InspId = inspec.id;
        flowInputs.add(input);
        AssessmentTaskDefinition ATD1 = new AssessmentTaskDefinition(Name='Health and Safety SN Application	',TaskType ='InspectionChecklist',Category__c='Health and Safety');
        AssessmentTaskDefinition ATD2 = new AssessmentTaskDefinition(Name='Emergency Preparedness SN Application',TaskType ='InspectionChecklist',Category__c='Emergency Preparedness');
        insert new List<AssessmentTaskDefinition>{ATD1, ATD2};
            List<AssessmentTaskDefinition> atd = [Select id from AssessmentTaskDefinition];
                ActionPlanTemplateItemValue APTIV1 = new ActionPlanTemplateItemValue( ValueLiteral=atd[0].id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=Apti[0].id);
        ActionPlanTemplateItemValue APTIV2 = new ActionPlanTemplateItemValue( ValueLiteral=atd[1].id,ItemEntityFieldName='AssessmentTask.AssessmentTaskDefinitionId',ActionPlanTemplateItemId=Apti[1].id);
        insert new List<ActionPlanTemplateItemValue>{APTIV1, APTIV2};
            List<ActionPlanTemplateItemValue> Aptiv = [Select id from ActionPlanTemplateItemValue];
        Test.startTest();
        InspTasksCreationController.getActionPlanItemIds(flowInputs);
        Test.stopTest();
        System.assert(InspTasksCreationController.getActionPlanItemIds(flowInputs) == null, 'Its not null');
        
        
    }
    
}