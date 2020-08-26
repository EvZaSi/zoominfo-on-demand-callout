@isTest
public class ZoomInfoCompanyEnrichLeadCalloutTest {
    class ZoomInfoHTTPEnrichmentResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('Content-Type', 'application/json');
            mockResponse.setStatusCode(200);
            mockResponse.setBody('{"success":true,"data":{"outputFields":[["id","name","employeecount","street","city","state","country","naicscodes","primaryindustry"]],"result":[{"input":{"companycountry":"united states","companyname":"salesforce","companywebsite":"http://www.salesforce.com"},"data":[{"id":239305146,"name":"Salesforce","employeeCount":36000,"street":"415 Mission St, Fl 3","city":"San Francisco","state":"California","country":"United States","naicsCodes":[{"id":"541511","name":"Custom Computer Programming Services"},{"id":"511","name":"Publishing Industries (except Internet)"},{"id":"5415","name":"Computer Systems Design and Related Services"},{"id":"5182","name":"Data Processing, Hosting, and Related Services"},{"id":"51","name":"Information"},{"id":"54151","name":"Computer Systems Design and Related Services"},{"id":"511210","name":"Software Publishers"},{"id":"5112","name":"Software Publishers"},{"id":"51821","name":"Data Processing, Hosting, and Related Services"},{"id":"518","name":"Data Processing, Hosting, and Related Services"},{"id":"51121","name":"Software Publishers"},{"id":"518210","name":"Data Processing, Hosting, and Related Services"}],"primaryIndustry":["Software","Customer Relationship Management (CRM) Software"]}]}]}}');
            return mockResponse;
        }
    }
    class ZoomInfoHTTPEnrichmentErrorResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('Content-Type', 'application/json');
            mockResponse.setStatusCode(401);
            mockResponse.setBody('Invalid username and/or password - please try again.');
            return mockResponse;
        }
    }
    class ZoomInfoHTTPEnrichmentJSONErrorResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('Content-Type', 'application/json');
            mockResponse.setStatusCode(400);
            mockResponse.setBody('{"success":false,"error":"Missing required field \'outputFields\'","statusCode":400}');
            return mockResponse;
        }
    }
    @isTest static void ZoomInfoEnrichCorrectCredentialsAndJSON() {
        /* The purpose of this test is to demonstrate that in the situation where we make a callout to the ZoomInfo Company Enrich endpoint with the correct credentials and our JSON request is correctly formatted, our returned status code should be 200 */
        Test.setMock(HttpCalloutMock.class, new ZoomInfoHTTPEnrichmentResponse());
        Test.startTest();
        String correctJwtToken = 'testToken';
        String correctJSON = '{"matchCompanyInput":[{"companyName":"Salesforce","companyCountry":"United States","companyWebsite":"http://www.salesforce.com"}],"outputFields":["id","name","employeeCount","street","city","state","country","naicsCodes","primaryIndustry"]}';
        HttpResponse testResponse = ZoomInfoCompanyEnrichLeadCallout.zoominfoCallout(correctJwtToken,correctJSON);
        Test.stopTest();

        System.assertEquals(200, testResponse.getStatusCode());
    }
    @isTest static void ZoomInfoEnrichWrongCredentials() {
        /* The purpose of this test is to demonstrate that when we make a callout to the ZoomInfo Company Enrich endpoint with the incorrect credentials, the returned status code is 401 and that an email notification was sent to the SFDC admin to alert them (as determined by the email invocations assert statement) */
        Test.setMock(HttpCalloutMock.class, new ZoomInfoHTTPEnrichmentErrorResponse());
        Test.startTest();
        String wrongJwtToken = 'testToken';
        String correctJSON = '{"matchCompanyInput":[{"companyName":"Salesforce","companyCountry":"United States","companyWebsite":"http://www.salesforce.com"}],"outputFields":["id","name","employeeCount","street","city","state","country","naicsCodes","primaryIndustry"]}';
        HttpResponse testResponse = ZoomInfoCompanyEnrichLeadCallout.zoominfoCallout(wrongJwtToken,correctJSON);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations);
        System.assertEquals(401,testResponse.getStatusCode());
    }
    @isTest static void ZoomInfoEnrichIncorrectJSON() {
        /* The purpose of this test is the demonstrate that when we make a callout to the ZoomInfo Company Enrich endpoint with the correct credentials but incorrectly formatted JSON, that the reponse will have a 400 status code and that an email will be sent to the SFDC admin to alert them (as determined by the email invocations assert statement) */
        Test.setMock(HttpCalloutMock.class, new ZoomInfoHTTPEnrichmentJSONErrorResponse());
        Test.startTest();
        String correctJwtToken = 'testToken';
        String incorrectJSON = '{"matchCompanyInput":[{"companyName":"Salesforce","companyCountry":"United States","companyWebsite":"http://www.salesforce.com"}]["id","name","employeeCount","street","city","state","country","naicsCodes","primaryIndustry"]}';
        HttpResponse testResponse = ZoomInfoCompanyEnrichLeadCallout.zoominfoCallout(correctJwtToken,incorrectJSON);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations);
        System.assertEquals(400,testResponse.getStatusCode());
    }
}

