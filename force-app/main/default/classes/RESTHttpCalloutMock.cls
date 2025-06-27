@IsTest
public with sharing class RESTHttpCalloutMock implements HttpCalloutMock {
    public HttpResponse response = new HttpResponse();
    public RESTHttpCalloutMock(Integer code, String status, String bodyAsString) {
        this.response = RESTHttpCalloutMock.generateHttpResponse(code, status, bodyAsString);
    }

    public HttpResponse respond(HttpRequest req) {
        return this.response;
    }

    public static HttpResponse generateHttpResponse(Integer code, String status, String bodyAsString) {
        HttpResponse res = new HttpResponse();
        res.setStatus(status);
        res.setStatusCode(code);
        res.setBody(bodyAsString);
        return res;
    }
}