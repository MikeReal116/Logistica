@IsTest
private with sharing class ShipmentRequestControllerTest {
    @TestSetup
    private static void makeData() {
        List<ShipmentRequest__c> shipmentRequests = new List<ShipmentRequest__c>{
            new ShipmentRequest__c(Destination__c = 'Finland', Origin__c = 'Finland', Carrier__c = 'Carrier A', Region__c = 'EMEA'),
            new ShipmentRequest__c(Destination__c = 'Sweden', Origin__c = 'Finland', Carrier__c = 'Carrier B', Region__c = 'EMEA')
        };
        insert shipmentRequests;
    }

    @IsTest
    private static void itShouldReturnShipmentRequests() {
        User currentUser = [SELECT Id, Region__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        currentUser.Region__c = 'EMEA';
        update currentUser;

        Test.startTest();
        List<ShipmentRequest__c> shipmentRequests = ShipmentRequestController.getShipmentRequests();
        Test.stopTest();

        System.Assert.isTrue(shipmentRequests.size() > 0, 'Shipment requests should not be empty');
    }

    @IsTest
    private static void itShouldNotReturnShipmentRequest() {
        User currentUser = [SELECT Id, Region__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
        currentUser.Region__c = null;
        update currentUser;

        Test.startTest();
        List<ShipmentRequest__c> shipmentRequests = ShipmentRequestController.getShipmentRequests();
        Test.stopTest();

        System.Assert.isTrue(shipmentRequests.isEmpty(), 'Shipment requests should be empty for this region');
    }

    @IsTest
    private static void itShouldUpdateShipmentRequest() {
        ShipmentRequest__c shipmentRequest = [SELECT Id, Status__c FROM ShipmentRequest__c LIMIT 1];
        String newStatus = 'In Review';
        shipmentRequest.Status__c = newStatus;

        Test.startTest();
        String result = ShipmentRequestController.updateShipmentRequest(shipmentRequest);
        Test.stopTest();

        ShipmentRequest__c updatedShipmentRequest = [SELECT Id, Status__c FROM ShipmentRequest__c WHERE Id = :shipmentRequest.Id LIMIT 1];
        System.Assert.areEqual(newStatus, updatedShipmentRequest.Status__c, 'Shipment request status should be updated to In Review');
    }
}