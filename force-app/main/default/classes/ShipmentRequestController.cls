public with sharing class ShipmentRequestController {
    @AuraEnabled
    public static List<ShipmentRequest__c> getShipmentRequests() {
        try {
            User currentUser = [SELECT Id, Region__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            return [
                SELECT Id, Name, Destination__c, Carrier__c, Status__c, Tracking_ID__c, Estimated_Delivery__c, Region__c, ShipmentRequest_Id__c
                FROM ShipmentRequest__c
                WHERE Region__c = :currentUser.Region__c AND Region__c != NULL
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error querying ShipmentRequest: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static string updateShipmentRequest(ShipmentRequest__c shipmentRequest) {
        try {
            DML updateDml = new DML()
                .setOperation(DML.DMLOperation.UPDATE_OPERATION)
                .setRecord(shipmentRequest)
                .setAllowPartialSuccess(false)
                .setDmlAccessLevel(AccessLevel.USER_MODE);
            updateDml.execute();
            if (shipmentRequest.Status__c == 'Ready for Dispatch' && shipmentRequest.ShipmentRequest_Id__c != null) {
                System.enqueueJob(new DispatchToCarrier(shipmentRequest.ShipmentRequest_Id__c));
            }
            return 'ShipmentRequest updated successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error updating ShipmentRequest: ' + e.getMessage());
        }
    }
}