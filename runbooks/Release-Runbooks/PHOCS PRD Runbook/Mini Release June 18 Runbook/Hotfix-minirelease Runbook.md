Created Date |16-06-2026|
Last Modified Date |16-06-2026|
Description - "Mini release runboom for June 18 deployment"

- Package.xml for the PR 's raised to hotfixdev branch
- Pull Request Number - 2664, 2666 , 2689,2682, 2683, 2695

	<types>
		<members>CustomTokenInspectionData</members>
		<members>PHOCSAssessmentIndCtrlV2Test</members>
		<members>PHOCSInspectionAssessmentIndControllerV2</members>
		<members>PHOCSInspectionsHelper</members>
		<name>ApexClass</name>
	</types>
	<types>
		<members>Account.FirstNationPartnershipName__c</members>
		<members>Account.FirstNationPartnership__c</members>
		<members>Account.LocatedonFirstNationReserveLand__c</members>
		<members>Account.OperatedbyFirstNationName__c</members>
		<members>Account.OperatedbyFirstNation__c</members>
		<members>Account.ReserveName__c</members>
		<name>CustomField</name>
	</types>
	<types>
		<members>Residence_Record_Page</members>
		<name>FlexiPage</name>
	</types>
	<types>
		<members>Clear_value_When_Checkbox_Unchecked</members>
		<members>VisitCreationPHOCS</members>
		<name>Flow</name>
	</types>
	<types>
		<members>inspectionQuestionsParentv2</members>
		<name>LightningComponentBundle</name>
	</types>
	<types>
		<members>EHIS_ALR_Manage_System_Admin_User_PS</members>
		<members>EHIS_CRE_Account_Contact_Asset_Service_PS</members>
		<members>EHIS_Manage_System_Admin_User_PS</members>
		<members>EHIS_Read_Account_PS</members>
		<name>PermissionSet</name>
	</types>
	<types>
		<members>Accounts_Contact_Relationships</members>
		<members>Accounts_with_Cases</members>
		<members>Accounts_with_Conditions</members>
		<members>Business_License_Applications_Fees</members>
		<members>Fees_Fee_Items_Account</members>
		<members>Inspection_Account_Report_Type</members>
		<members>Inspection_Report_Type</members>
		<members>PublicComplaints_With_Related_Accounts_Cases</members>
		<members>Residence_Report_By_Type</members>
		<name>ReportType</name>
	</types>

> Security settings deployment : [EHIS-4567]
 [] Configuration step on SF UI:
         Setup -> Search 'Identity Verification' -> Look for 'Reports and Dashboards' -> Select 'Require periodic step-up authentication'
         Click 'Save'

 [] Deploy these files manually 
     "src-env-specific\production\main\default\transactionSecurityPolicies"
	 "src-env-specific\production\main\default\FileUploadAndDownloadSecurity.settings-meta.xml"
	 "src-env-specific\production\main\default\PlatformEncryption.settings-meta.xml"
	 "src-env-specific\production\main\default\Security.settings-meta.xml"

> Post Deployment Steps

 [] Document Template Upload [EHIS- 4566]
		Go to App launcher -> Search for omnistudio -> Document template designer -> Search for 'PhocsDairyInspectionReport Template'.
		Open the 'Active' version -> Click on 'deactivate' -> replace file with "BCCDC_Dairy_Inspection_Template_Redesign - V6.0.docx"
		Save and Activate 



