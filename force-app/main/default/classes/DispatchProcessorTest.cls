@IsTest
private with sharing class DispatchProcessorTest {
    @IsTest
    private static void itShouldSendCalloutResponse() {
        String shipmentId = '123456789';

        DispatchProcessor processor = new DispatchProcessor(shipmentId, 0);
        RESTHttpCalloutMock mock = new RESTHttpCalloutMock(204, 'Success', '');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        DispatchProcessor.shouldChain = false; // chaining not allowed in test context
        System.enqueueJob(processor);
        System.Assert.isTrue(Limits.getQueueableJobs() > 0, 'Queueable job should be enqueued successfully');
        Test.stopTest();

        System.Assert.isTrue(mock.response.getStatusCode() == 204, 'Callout should return 204 No Content');
    }
}
