public class Application {
    // Configure and create the UnitOfWorkFactory for this Application
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
        new List<SObjectType>{
            Account.SObjectType,
            AccountShare.SObjectType,
            Contact.SObjectType,
            Case.SObjectType,
            //Communication__c.SObjectType,
           // Form__c.SObjectType,
            //Form_Page__c.SObjectType,
            //Form_Section__c.SObjectType,
           // Form_Question__c.SObjectType,
           // Form_Response__c.SObjectType,
           // Form_Question_Response__c.SObjectType,
            HealthcareProvider.SObjectType,
            Log__c.SObjectType,
            PermissionSetAssignment.SObjectType,
            User.SObjectType   
        }
    );

    // Configure and create the ServiceFactory for this Application
    public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
        new Map<Type, Type>{
            // AccountShareService.class => AccountShareService.class,
            // BcDiagnosisCodeMdtService.class => BcDiagnosisCodeMdtService.class,
            // DynamicQuestionnaireFormHelper.class => DynamicQuestionnaireFormHelper.class,
            // DynamicQuestionnaireFormService.class => DynamicQuestionnaireFormService.class,
            // DynamicQuestionnaireFormResponseService.class => DynamicQuestionnaireFormResponseService.class,
            // FormResponseService.class => FormResponseService.class,
            // FormQuestionResponseService.class => FormQuestionResponseService.class,
            // FormQuestionService.class => FormQuestionService.class,
            // HealthcareProviderService.class => HealthcareProviderService.class,
            // ProcedureCodeMdtService.class => ProcedureCodeMdtService.class,
            // UserService.class => UserService.class
        }
    );

    // Configure and create the SelectorFactory for this Application
    public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
        new Map<SObjectType, Type>{
            // Account.SObjectType => AccountSelector.class,
            // AccountShare.SObjectType => AccountShareSelector.class,
            // BC_Diagnosis_Code__mdt.SObjectType => BCDiagnosisCodeMdtSelector.class,
            // Contact.SObjectType => ContactSelector.class,
            // Communication__c.SObjectType => CommunicationSelector.class,
            // Facility_Allowed_Status_Mapping__mdt.SObjectType => FacilityAllowedStatusMappingSelector.class,
            // Form__c.SObjectType => FormSelector.class,
            // Form_Version__c.SObjectType => FormVersionSelector.class,
            // Form_Question_Response__c.SObjectType => FormQuestionResponseSelector.class,
            // Form_Question__c.SObjectType => FormQuestionSelector.class,
            // Form_Section__c.SObjectType => FormSectionSelector.class,
            // Form_Response__c.SObjectType => FormResponseSelector.class,
            // Group.SObjectType.SObjectType => GroupSelector.class,
            // HealthcareProvider.SObjectType => HealthcareProviderSelector.class,
            // Patient_Portal_Configuration__mdt.SObjectType => PatientPortalConfigurationSelector.class,
            // Patient_Portal_URL_Mapping__mdt.SObjectType => PatientPortalURLMappingSelector.class,
            // Procedure_Code__mdt.SObjectType => ProcedureCodeMdtSelector.class,
            // PermissionSetGroup.SObjectType => PermissionSetGroupSelector.class,
            // PermissionSet.SObjectType => PermissionSetSelector.class,
            // Profile.SObjectType => ProfileSelector.class,
            // PermissionSetAssignment.SObjectType => PermissionSetAssignmentSelector.class,
            // Reference_Field__mdt.SObjectType => ReferenceFieldMdtSelector.class,
            // Schedule_Email_Config__mdt.SObjectType => ScheduleEmailConfigSelector.class,
            // User.SObjectType.SObjectType => UserSelector.class,
            // User_Permission_Set_Assignment__mdt.SObjectType => UserPermissionSetAssignmentMdtSelector.class,
            // User_Role_Assignment__mdt.SObjectType => UserRoleAssignmentMdtSelector.class,
            // UserRole.SObjectType => UserRoleSelector.class,
            // Value_Configuration__mdt.SObjectType => ValueMdtSelector.class
        }
    );

    // Configure and create the DomainFactory for this Application
    public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
        Application.Selector,
        new Map<SObjectType, Type>{
           // Form_Question_Response__c.SObjectType => FormQuestionResponses.Constructor.class,
           // Form_Response__c.SObjectType => FormResponses.Constructor.class,
            Log_Event__e.SObjectType => LogEvents.Constructor.class
        }
    );
}