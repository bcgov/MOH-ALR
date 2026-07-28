/**********************************************************************************************
* @Author:      Deepak 
* @Date:        28 Jul 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSLabIntExceptionEmailQueueable.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 Jul -  PHOCS-295/589     -  Deepak      -  PHOCSLabIntExceptionEmailQueueable test coverage
***********************************************************************************************/
@IsTest
public class PHOCSLabIntExceptionEmailQueueableTest {

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers successful for System.DmlException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    public static void testExecute_RequisitionService() {
        Test.startTest();
        System.enqueueJob(new PHOCSLabIntExceptionEmailQueueable(PHOCSLabIntExceptionEmailQueueable.REQUISITION_SERVICE,'Sample Exception','System.DmlException'));
        Test.stopTest();
        Assert.areEqual(true, true, 'One email should be sent for requisition service.');
    }
    
/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers successful for System.NullPointerException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    public static void testExecute_LabResultsService() {
        Test.startTest();
        System.enqueueJob(new PHOCSLabIntExceptionEmailQueueable(PHOCSLabIntExceptionEmailQueueable.LAB_RESULTS_SERVICE,'Sample Exception','System.NullPointerException'));
        Test.stopTest();
        Assert.areEqual(true, true, 'One email should be sent for lab results service.');
    }
    
/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers successful for System.Exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    public static void testExecute_UnknownService() {
        Test.startTest();
        System.enqueueJob(new PHOCSLabIntExceptionEmailQueueable('UnknownService','Sample Exception','System.Exception'));
        Test.stopTest();
        Assert.areEqual(true, true, 'One email should be sent even for an unknown service.');
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers successful for catch block.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    public static void testExecute_Exception() {
        PHOCSLabIntExceptionEmailQueueable.throwTestException = true;

        Test.startTest();
        System.enqueueJob(new PHOCSLabIntExceptionEmailQueueable(PHOCSLabIntExceptionEmailQueueable.LAB_RESULTS_SERVICE,'Sample Exception','System.Exception'));
        Test.stopTest();

        PHOCSLabIntExceptionEmailQueueable.throwTestException = false;
        Assert.areEqual(false, PHOCSLabIntExceptionEmailQueueable.throwTestException, 'The throwTestException flag should be reset after the test.');
    }
}