public with sharing class DispatchToCarrier implements Queueable, Database.AllowsCallouts {
    private String shipmentRequestId;

    public DispatchToCarrier(String shipmentRequestId) {
        this.shipmentRequestId = shipmentRequestId;
    }

    public void execute(QueueableContext context) {
        if (String.isNotBlank(shipmentRequestId)) {
            sendRequestToCarrier();
        }
    }

    private void sendRequestToCarrier() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CarrierAPICredential/services/apexrest/CarrierAPI/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"shipmentRequestId": "' + shipmentRequestId + '"}');
        http.send(req);

        // We can have a daily scheduled job to check the status of the shipmentRequest and if is Ready for Dispatch, we can enqueue a new DispatchToCarrier job
        // to send the request to the carrier API.
    }
}