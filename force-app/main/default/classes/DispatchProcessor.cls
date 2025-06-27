public with sharing class DispatchProcessor implements Queueable, Database.AllowsCallouts {
    private String shipmentId;
    private Integer retryCount = 0;
    @TestVisible
    private static Boolean shouldChain = true;

    public DispatchProcessor(String shipmentId, Integer retryCount) {
        this.shipmentId = shipmentId;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        // Simulate dispatch processing (80% success rate)
        Boolean success = Math.random() > 0.2;
        String newStatus = success ? 'Dispatched' : 'Dispatch Failed';
        sendCallbackResponse(shipmentId, newStatus);
        if (!success && retryCount < 3 && shouldChain) {
            retryCount++;
            System.enqueueJob(new DispatchProcessor(shipmentId, retryCount), 1);
        }
        // After three failed attempts, we could log to a custom future batch object that can be scheduled later to retry
    }

    @TestVisible
    private void sendCallbackResponse(String shipmentId, String newStatus) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:LogisticaCredential/services/data/v64.0/sobjects/ShipmentRequest__c/ShipmentRequest_Id__c/' + shipmentId);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        Date estimatedDelivery = Date.today().addDays(5);
        Map<String, Object> payload = new Map<String, Object>{
            'Status__c' => newStatus,
            'Tracking_ID__c' => newStatus == 'Dispatched' ? String.valueOf(Math.random()).substring(2, 10) : '',
            'Estimated_Delivery__c' => newStatus == 'Dispatched' ? String.valueOf(estimatedDelivery) : ''
        };
        req.setBody(JSON.serialize(payload));
        HttpResponse res = http.send(req);
        // We could log to a custom object  if res status is not 204 to investigate what went wrong using the SF standard API
    }
}