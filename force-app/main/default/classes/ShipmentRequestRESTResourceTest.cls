@IsTest
private with sharing class ShipmentRequestRESTResourceTest {
    @IsTest
    private static void itShouldProcessShipmentRequest() {
        String shipmentRequestId = '12345678';
        String requestBody = JSON.serialize(new Map<String, Object>{ 'shipmentRequestId' => shipmentRequestId });
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CarrierAPI/';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new RESTHttpCalloutMock(200, 'success', ''));
        Test.startTest();
        DispatchProcessor.shouldChain = false;
        ShipmentRequestRESTResource.doPost();
        Test.stopTest();
        System.Assert.areEqual(200, res.statusCode, 'Response status code should be 200');
    }

    @IsTest
    private static void itShouldReturnErrorForMissingShipmentRequestId() {
        String requestBody = JSON.serialize(new Map<String, Object>{ 'shipmentRequestId' => '' });
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CarrierAPI/';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        ShipmentRequestRESTResource.doPost();
        Test.stopTest();

        System.Assert.areEqual(400, res.statusCode, 'Response status code should be 400 for missing shipment request ID');
    }

    @IsTest
    private static void itShouldReturnErrorForException() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('Invalid JSON');
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CarrierAPI/';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        ShipmentRequestRESTResource.doPost();
        Test.stopTest();

        System.Assert.areEqual(500, res.statusCode, 'Response status code should be 500 for exception');
    }
}