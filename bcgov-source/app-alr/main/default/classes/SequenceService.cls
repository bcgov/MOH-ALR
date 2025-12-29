/**
 * SequenceService
 * Invocable action to atomically increment and return the next sequence number using a single-row Sequence__c record.
 *
 * - Uses FOR UPDATE row lock to prevent duplicate numbers under concurrency.
 * - Creates the singleton Sequence__c row on first use (LastNumber__c initialized to 0).
 *
 * Security & Patterns:
 * - with sharing to respect org sharing (object is org-internal; ensure appropriate perms assigned).
 * - Database methods with SaveResult handling.
 * - Bulkified: accepts up to 200 requests and returns 1:1 outputs.
 * - Early returns and defensive checks.
 *
 * Flow Usage:
 * - Add Apex Action "SequenceService.GetNextNumber".
 * - No inputs required (single global counter).
 * - Outputs: nextNumber (Integer).
 * - You can format with LPAD in Flow formulas as needed.
 */
public with sharing class SequenceService {

    // Invocable input type must be public and top-level (not private/protected)
    public class Request {
        @InvocableVariable(required=false)
        public String sequenceName; // optional future extensibility; ignored for singleton
    }

    // Invocable output type
    public class Response {
        @InvocableVariable(required=true)
        public Integer nextNumber;
    }

    @InvocableMethod(label='GetNextNumber' description='Atomically increments and returns the next global sequence number.')
    public static List<Response> getNextNumber(List<Request> requests) {
        // Defensive: Flows always pass a List; still handle null/empty
        if (requests == null || requests.isEmpty()) {
            return new List<Response>();
        }

        // Pre-size responses
        List<Response> results = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) {
            results.add(new Response());
        }

        try {
            // Lock or create singleton row
            Sequence__c singleton = lockOrCreateSingleton();

            // Compute allocation window
            Integer base = (singleton.LastNumber__c == null) ? 0 : Integer.valueOf(singleton.LastNumber__c);
            Integer size = requests.size();
            Integer newLast = base + size;

            // Update LastNumber__c in one DML using USER_MODE per security rules
            singleton.LastNumber__c = newLast;
            Database.SaveResult sr = Database.update(singleton, AccessLevel.USER_MODE);

            if (!sr.isSuccess()) {
                // Populate nulls to avoid Flow fault
                for (Integer i = 0; i < results.size(); i++) {
                    results[i].nextNumber = null;
                }
                return results;
            }

            // Assign allocated numbers deterministically
            for (Integer i = 0; i < results.size(); i++) {
                results[i].nextNumber = base + (i + 1);
            }
            return results;

        } catch (Exception e) {
            // Return nulls on error to keep Flow resilient
            for (Integer i = 0; i < results.size(); i++) {
                results[i].nextNumber = null;
            }
            return results;
        }
    }

    // Helper to query with row lock; creates singleton if missing.
    private static Sequence__c lockOrCreateSingleton() {
        // Try lock existing
        List<Sequence__c> rows = [SELECT Id, LastNumber__c FROM Sequence__c LIMIT 1 FOR UPDATE];
        if (!rows.isEmpty()) {
            return rows[0];
        }

        // None exists – create it (admin-defined starting number may be on the record; LastNumber__c defaults to 0/null)
        Sequence__c toInsert = new Sequence__c();
        Database.SaveResult ins = Database.insert(toInsert, AccessLevel.USER_MODE);
        if (!ins.isSuccess()) {
            // Bubble as an exception; caller will catch and return nulls
            throw new AuraHandledException('Failed to initialize sequence store.');
        }

        // Requery with lock
        rows = [SELECT Id, LastNumber__c FROM Sequence__c WHERE Id = :ins.getId() FOR UPDATE];
        if (rows.isEmpty()) {
            throw new AuraHandledException('Failed to lock sequence store.');
        }
        return rows[0];
    }
}
