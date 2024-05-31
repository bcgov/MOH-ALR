/**
* @Name              : RCVCreationHelperTest
* @Description       : Test class for RCVCreationHelper
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1291
**/
@isTest
public class RCVCreationHelperTest {
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
        database.insert(loc);
        Set<Id>loct = New Set<Id>();
        List<Schema.location> loction =[select id,Name from Location where Name ='U.S. 101N'];
        
        for(Account acc1 : accList){
            AssociatedLocation assosicatedloc = new AssociatedLocation();
            assosicatedloc.ParentRecordId = acc1.Id;
            assosicatedloc.LocationId = loc.Id;
            accList2.add(assosicatedloc);
        }
        database.insert(accList2);
        
        Set<Id> accSet= new Set<Id>();
        for(Account acc3 : accList){
            AccSet.add(acc3.Id);
        }
        InspectionType insType = new InspectionType();
        insType.Name = 'Compliance Monitoring Inspection1';
        database.insert(insType);
       
        Visit insp = new Visit();
        insp.AccountId =acc.id;
        insp.InspectionMethod__c ='Scheduled on Site Inspection';
        insp.PlannedVisitStartTime = System.today();
        insp.PlaceId = loction[0].Id;
        insp.VisitTypeId =insType.Id;
        database.insert(insp);
        Visit inspec = [Select id from Visit where AccountId =:acc.id Limit 1];
        AssessmentIndicatorDefinition aid = new AssessmentIndicatorDefinition (Name='A person employed as a volunteer.',Category__c='Administrative and Other Matters',DataType= 'String');
        database.insert(aid);
        AssessmentTaskDefinition aTD1 = new AssessmentTaskDefinition(Name='Health and Safety SN Application	',TaskType ='InspectionChecklist',Category__c='Health and Safety');
        database.insert(atD1);
        List<AssessmentTask> ATstoInsert = new List<AssessmentTask>();
        AssessmentTask  newAssessmentTask = new AssessmentTask();
        newAssessmentTask.Name = aTD1.Category__c;
        newAssessmentTask.AssessmentTaskDefinitionId = aTD1.Id;
        newAssessmentTask.ParentId = insp.Id;
        newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
        database.insert(newAssessmentTask);
        InspectionAssessmentInd iai = new InspectionAssessmentInd(TextFieldResponse ='text',Result='Non-compliant',AssessmentIndDefinitionId=aid.Id,AssessmentTaskId=newAssessmentTask.Id);
        database.insert(iai);
        RegulatoryAuthority ray = new RegulatoryAuthority(Name ='Mentaal Health');
        database.insert(ray);
        RegulatoryCode rcd = new RegulatoryCode(Name ='S 20.1.b - Employees', Subject='S 20.1.b - Employees ',RegulatoryAuthorityId=ray.id,EffectiveFrom=DateTime.now());
        database.insert(rcd);
        RegulatoryCodeAssessmentInd rcai = new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId=aid.Id,RegulatoryCodeId=rcd.Id);
        database.insert(rcai);
        
        Test.startTest();
        inspec.Status ='Completed';
        Database.update(inspec);
        RCVCreationHelper.createRegulatoryCodeViolations(inspec.id);
        Test.stopTest();
        Assert.areEqual(True,RCVCreationHelper.createRegulatoryCodeViolations(inspec.id) == null);
        Assert.areNotEqual(False,RCVCreationHelper.createRegulatoryCodeViolations(inspec.id) == null);

    }

}