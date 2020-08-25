@isTest
public class ZoomInfoAuthenticationTest {
    class ZoomInfoHTTPAuthenticationResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('Content-Type', 'application/json');
            mockResponse.setStatusCode(200);
            mockResponse.setBody('{"success":true,"jwt":"testresponse"}');
            return mockResponse;
        }
    }
    class ZoomInfoHTTPAuthenticationErrorResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockErrorResponse = new HttpResponse();
            mockErrorResponse.setHeader('Content-Type', 'application/json');
            mockErrorResponse.setStatusCode(401);
            mockErrorResponse.setBody('Invalid username and/or password - please try again.');
            return mockErrorResponse;
        }
    }
    @isTest static void ZoomInfoAuthenticationCorrectCredentials() {
        Test.setMock(HttpCalloutMock.class, new ZoomInfoHTTPAuthenticationResponse());
        Test.startTest();
        String correctUsername = 'testUsername';
        String correctPassword = 'testPassword';
        HttpResponse testResponse = ZoomInfoAuthentication.makeCallout(correctUsername,correctPassword);
        Test.stopTest();

        System.assertEquals(200, testResponse.getStatusCode());
    }
    @isTest static void ZoomInfoAuthenticationWrongCredentials() {
        Test.setMock(HttpCalloutMock.class, new ZoomInfoHTTPAuthenticationErrorResponse());
        Test.startTest();
        String wrongUsername = 'testUsername';
        String wrongPassword = 'testPassword';
        HttpResponse testResponse = ZoomInfoAuthentication.makeCallout(wrongUsername,wrongPassword);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations);
        System.assertEquals(401,testResponse.getStatusCode());
    }
}

