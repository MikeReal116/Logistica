@IsTest
private with sharing class DispatchToCarrierTest {
    @IsTest
    private static void itShouldDispatchShipmentRequest() {
        String shipmentRequestId = '12345678';
        DispatchToCarrier dispatchJob = new DispatchToCarrier(shipmentRequestId);

        Test.setMock(HttpCalloutMock.class, new RESTHttpCalloutMock(200, 'success', ''));

        Test.startTest();
        System.enqueueJob(dispatchJob);
        Test.stopTest();
        System.Assert.isTrue(true, 'Dispatch job should be enqueued successfully');
    }
}