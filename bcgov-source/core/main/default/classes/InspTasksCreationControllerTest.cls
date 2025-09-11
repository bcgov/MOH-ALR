/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class for Inspection Assessment Indicator Creation
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                           ALR-1230             Anilkumar     Error while creating the inspection
***********************************************************************************************/
@isTest(SeeAllData=true)
public class InspTasksCreationControllerTest {
    public static testMethod void testInsert(){
        List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
        List<Account> finalList;
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
        Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(AccRec);
        Account acc = [SELECT Id FROM Account WHERE Name ='residence1'];
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
        loc.Longitude = 28.635308;
        loc.Latitude = 28.635308;
        insert loc;
        Set<Id>loct = New Set<Id>();
        List<Schema.location> loction =[SELECT id,Name FROM Location WHERE Name ='U.S. 101N'];
        
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
        insType.Name = 'Compliance Monitoring Inspection1';
        insert insType;
        Map<String, Id> mapInspectionType = new Map<String, Id>();
        mapInspectionType.put('InspectionType', insType.Id);
        
        finalList = [SELECT Id, Name, Rating, OwnerId, (SELECT Id, Location.VisitorAddress.Address, LocationId FROM AssociatedLocations LIMIT 1) FROM Account WHERE  Id IN : AccSet];
        
        Visit insp = new Visit();
        insp.AccountId =acc.id;
        insp.InspectionMethod__c ='Scheduled on Site Inspection';
        insp.PlannedVisitStartTime = System.today();
        insp.ActualVisitStartTime = System.today();
        insp.PlaceId = loction[0].Id;
        insp.VisitTypeId =insType.Id;
        Insert insp;
        Visit inspec = [SELECT id FROM Visit WHERE AccountId =:acc.id Limit 1];

        String likeValue = '%Application%Inspection%';
            List<ActionPlanTemplate> apt = [SELECT id,ActionPlanType,Status FROM ActionPlanTemplate WHERE Name Like :likevalue and Status ='Final' LIMIT 3];

        List<ActionPlanTemplateVersion> aptv =[SELECT id FROM ActionPlanTemplateVersion WHERE ActionPlanTemplateId =: apt[0].Id Limit 3];

        List <ActionPlanTemplateItem> apti = [SELECT Id FROM ActionPlanTemplateItem WHERE ActionPlanTemplateVersionId =: aptv[0].Id Limit 3 ];
        
        List<InspTasksCreationController.FlowInputs> flowInputs = new List<InspTasksCreationController.FlowInputs>();
        InspTasksCreationController.FlowInputs input = new InspTasksCreationController.FlowInputs();
        List<String> aptistring = new List<String>();
        aptistring.add(apti[0].Id);
        input.ATIId = aptistring;
            input.InspId = inspec.id;
        flowInputs.add(input);
              
        List<ActionPlanTemplateItemValue> aptiv = [SELECT id,ItemEntityFieldName, ValueLiteral, ActionPlanTemplateItemId FROM ActionPlanTemplateItemValue WHERE ActionPlanTemplateItemId =: apti[0].id AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName];
        Set<String> LiteralValues = new Set<String>();
        for(ActionPlanTemplateItemValue aptiv3 : aptiv){
            LiteralValues.add(aptiv3.ValueLiteral);
        }
         If(LiteralValues.Size() !=0){
            List<AssessmentTaskDefinition> atds= [SELECT Id,Name,Category__c FROM AssessmentTaskDefinition WHERE Name IN: LiteralValues];

        List<AssessmentTask> ATstoInsert = new List<AssessmentTask>();
        AssessmentTask  newAssessmentTask = new AssessmentTask();
        newAssessmentTask.Name = atds[0].Category__c;
        newAssessmentTask.AssessmentTaskDefinitionId = atds[0].Id;
        newAssessmentTask.ParentId = insp.Id;
        newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
        insert newAssessmentTask;

        Test.startTest();
        InspTasksCreationController.getActionPlanItemIds(flowInputs);
        Test.stopTest();
        System.assert(InspTasksCreationController.getActionPlanItemIds(flowInputs) == null, 'Its not null');
        
        
    }
    }
}