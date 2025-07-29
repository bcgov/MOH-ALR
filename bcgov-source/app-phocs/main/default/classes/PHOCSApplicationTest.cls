
@isTest
public class PHOCSApplicationTest {
    
    @isTest 
    public static void testExecute() {
        PHOCSApplication app = new PHOCSApplication();
        System.assertNotEquals(null, PHOCSApplication.UnitOfWork);
    }
}