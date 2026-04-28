@isTest
public class GetInsActionPlanTemplateMappingsTest {
		@isTest
    Static void actionplantemplateexist(){
        GetInsActionPlanTemplateMappings.Request req = new GetInsActionPlanTemplateMappings.Request();
        req.AccountType = 'Dairy';
        req.InspectionType = 'Routine';
        
        Test.startTest();
        List<GetInsActionPlanTemplateMappings.Response> results =
            GetInsActionPlanTemplateMappings.resolve(
                new List<GetInsActionPlanTemplateMappings.Request>{ req }
                );
        Test.stopTest();
        System.assertNotEquals(null, results);
        System.assert(results.size()>0 , 'response should return');
        System.assertNotEquals(null, results[0].TemplateName,'TemplateName should populate');
        
    }
    
    @isTest
    static void actionplantemplatenotexist(){
        GetInsActionPlanTemplateMappings.Request req = new GetInsActionPlanTemplateMappings.Request();
        req.AccountType = 'testtype';
        req.InspectionType = 'testinspectiontype';
        
         List<GetInsActionPlanTemplateMappings.Response> results =
            GetInsActionPlanTemplateMappings.resolve(
                new List<GetInsActionPlanTemplateMappings.Request>{ req }
                );
        System.assertEquals(1, results.size(),'Should return exactly one response');
        System.assertEquals(null, results[0].TemplateName,'TemplateName should be null when no CMDT match exists');

        
    }
}