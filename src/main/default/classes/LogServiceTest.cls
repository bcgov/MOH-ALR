@IsTest
private class LogServiceTest {

    /**
     * @Description: Testing the LogService Log and PublishLogs
     * @StateUnderTest: An exception has occurred in the execution
     * @ExpectedBehaviour: A Log__c record is created with the details
     */
    @IsTest
    private static void Log_Enabled_Test(){
        //GIVEN : Enable_Logging__c is set to TRUE at Org Level
        insert new Log_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId(), Enable_Logging__c = true);

        //WHEN
        //An exception occurs in the execution
        Exception dmlException = new DMLException();
        dmlException.setMessage('Invalid Id for update operation');

        Test.startTest();
        LogService.log('LogServiceTest', 'LogTest', null, dmlException);
        LogService.publishLogs();
        Test.stopTest();

        //THEN
        //Log__c records are created.
        List<Log__c> logs = [SELECT Id, Class_Name__c, Method_Name__c FROM Log__c ];
        System.assertEquals(logs.size(), 1, 'a log record is not created');
        System.assertEquals(logs[0].Class_Name__c, 'LogServiceTest');
        System.assertEquals(logs[0].Method_Name__c, 'LogTest');
    }

    /**
     * @Description: Testing the LogService Log and PublishLogs
     * @StateUnderTest: An exception has occurred in the execution
     * @ExpectedBehaviour: A Log__c record is not created
     */
    @IsTest
    private static void Log_Disabled_Test(){
        //GIVEN : Enable_Logging__c is set to FALSE at Org Level
        insert new Log_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId(), Enable_Logging__c = false);

        //WHEN
        //An exception occurs in the execution
        Exception dmlException = new DMLException();
        dmlException.setMessage('Cannot find the service class');

        Test.startTest();
        LogService.log('LogServiceTest', 'LogTest', null, dmlException);
        LogService.publishLogs();
        Test.stopTest();

        //THEN
        //Log__c records are not created.
        List<Log__c> logs = [SELECT Id, Class_Name__c, Method_Name__c FROM Log__c ];
        System.assert(logs.isEmpty());
    }

    /**
     * @Description: Testing the LogService LogAndPublish
     * @StateUnderTest: An exception has occurred in the execution
     * @ExpectedBehaviour: A Log__c record is created with the details
     */
    @IsTest
    private static void LogAndPublish_Test(){
        //GIVEN : Enable_Logging__c is set to TRUE at Org Level
        insert new Log_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId(), Enable_Logging__c = true);

        //WHEN
        //An exception occurs in the execution
        Exception dmlException = new DMLException();
        dmlException.setMessage('Invalid Id for update operation');

        Test.startTest();
        LogService.logAndPublish('LogServiceTest', 'LogTest', null, dmlException);
        Test.stopTest();

        //THEN
        //Log__c records are created.
        List<Log__c> logs = [SELECT Id, Class_Name__c, Method_Name__c FROM Log__c ];
        System.assertEquals(logs.size(), 1, 'a log record is not created');
        System.assertEquals(logs[0].Class_Name__c, 'LogServiceTest');
        System.assertEquals(logs[0].Method_Name__c, 'LogTest');
    }
    
    /**
     * @Description: Testing the LogService LogAndPublish
     * @StateUnderTest: An exception has occurred in the execution
     * @ExpectedBehaviour: A Log__c record is created with the details
     */
    @IsTest
    private static void processFailedLogs_Test(){
    
        //GIVEN : Enable_Logging__c is set to TRUE at Org Level
        insert new Log_Configuration__c(SetupOwnerId = UserInfo.getOrganizationId(), Enable_Logging__c = true);

        //WHEN
        //An exception occurs in the execution
        List<Account> accList = new List<Account>();
        Account acc = New Account();
        accList.add(acc);
        
        Database.saveResult[] srList = database.insert (accList,false); 
        
        Test.startTest();
        LogService.processFailedLogs('LogServiceTest', 'LogTest', srList );
        Test.stopTest();

        //THEN
        //Log__c records are created.
        List<Log__c> logs = [SELECT Id, Class_Name__c, Method_Name__c FROM Log__c ];
        System.assertEquals(logs.size(), 1, 'a log record is created');
        System.assertEquals(logs[0].Class_Name__c, 'LogServiceTest');
        System.assertEquals(logs[0].Method_Name__c, 'LogTest');
    }
}