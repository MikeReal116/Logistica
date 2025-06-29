@IsTest
private with sharing class DispatchToCarrierTest {
    @IsTest
    private static void itShouldDispatchShipmentRequest() {
        String shipmentRequestId = '12345678';
        DispatchToCarrier dispatchJob = new DispatchToCarrier(shipmentRequestId);
        RESTHttpCalloutMock mock = new RESTHttpCalloutMock(200, 'success', '');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        System.enqueueJob(dispatchJob);
        System.Assert.isTrue(Limits.getQueueableJobs() > 0, 'Queueable job should be enqueued successfully');
        Test.stopTest();

        System.Assert.areEqual(200, mock.response.getStatusCode(), 'Callout should return 200 OK');
    }
}
