@RestResource(urlMapping='/CarrierAPI/*')
global with sharing class ShipmentRequestRESTResource {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            String shipmentRequestId = (String) payload.get('shipmentRequestId');

            if (String.isBlank(shipmentRequestId)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('Shipment request number is required');
                return;
            }
            System.enqueueJob(new DispatchProcessor(shipmentRequestId, 0), 1);
            Map<String, String> successResponse = new Map<String, String>{ 'status' => 'success', 'message' => 'Dispatch processing initiated' };
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(successResponse));
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error processing shipment request: ' + e.getMessage());
        }
    }
}