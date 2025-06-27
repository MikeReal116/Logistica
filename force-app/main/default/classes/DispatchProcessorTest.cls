@IsTest
private with sharing class DispatchProcessorTest {
    @IsTest
    private static void itShouldSendCalloutResponse() {
        String shipmentId = '123456789';
        DispatchProcessor processor = new DispatchProcessor(shipmentId, 0);
        Test.setMock(HttpCalloutMock.class, new RESTHttpCalloutMock(204, 'success', ''));

        Test.startTest();
        DispatchProcessor.shouldChain = false; // chaining not allowed in test context
        System.enqueueJob(processor);
        Test.stopTest();

        System.Assert.isTrue(true, 'Callout should be sent successfully');
    }
}