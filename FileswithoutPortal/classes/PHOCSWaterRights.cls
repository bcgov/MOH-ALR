/**
 * =================================================================================================
 *  Class Name      : PHOCSWaterRights
 *  Developer       : Pawan Atri
 *  Title           : Retrieve water license information from the Water Rights Database (WLRS)
 *  User Story      : EHIS-1425
 *  Created Date    : 16-Sept-2025
 *
 *  Summary:
 *  -----------------------------------------------------------------------------------------------
 *  This Apex interface defines a contract for Water Rights integration in PHOCS.
 *  Any implementing class must follow this structure for the integration process.
 *
 *  The interface supports the complete data enrichment flow that fetches and validates
 *  water-related information from external APIs based on License or Application inputs.
 *
 *  Key Responsibilities:
 *  1. runIntegration(String value)
 *      • Starts the integration sequence when a value (License or Application Number) is provided.
 *      • Performs callouts to external Water License / Water Application services.
 *      • Derives Well Tag Number and Aquifer Number from API responses.
 *
 *  2. mappingData(String facility)
 *      • Handles normalization and mapping of response payloads into Salesforce acceptable format.
 *      • Returns a key-value map of structured data for further processing or updates.
 *
 *  3. checkValidation(Object request)
 *      • Validates incoming request parameters before starting the API callout flow.
 *      • Ensures mandatory values (License, Application, etc.) are present and correct.
 *
 *  Why Interface?
 *  -----------------------------------------------------------------------------------------------
 *  • Allows multiple implementations (mock implementation, sandbox, prod-specific logic)
 *  • Ensures consistency for all Water Rights related integrations in PHOCS
 *  • Simplifies unit testing using fake/mocked classes
 *
 *  Usage:
 *  -----------------------------------------------------------------------------------------------
 *  PHOCSWaterRights service = new PHOCSWaterRightsService();
 *  service.runIntegration(account.WaterLicenseNumber__c);
 *
 * =================================================================================================
 */

public interface PHOCSWaterRights {
    Object runIntegration(String value);
    Map<String, Object> mappingData(String facility);
    Boolean checkValidation(Object request);
}