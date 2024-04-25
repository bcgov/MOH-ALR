/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]               
***********************************************************************************************/
public class Application {
    static String className = 'Application';
/**
* @Author:
* @date: 
* @description: The purpose of this method is to Configure and create the UnitOfWorkFactory for this Application
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
        new List<SObjectType>{
            Account.SObjectType,
                AccountShare.SObjectType,
                Contact.SObjectType,
                Case.SObjectType,
                Log__c.SObjectType,
                PermissionSetAssignment.SObjectType,
                User.SObjectType   
                }
    );
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to Configure and create the ServiceFactory for this Application
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
        new Map<Type, Type>{
        }
    );
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to Configure and create the SelectorFactory for this Application
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
        new Map<SObjectType, Type>{
        }
    );
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to Configure and create the DomainFactory for this Application
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
        Application.Selector,
        new Map<SObjectType, Type>{
            Log_Event__e.SObjectType => LogEvents.Constructor.class
            }
    );
}