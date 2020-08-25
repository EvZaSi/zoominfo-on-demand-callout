public class ZoomInfoCompanyEnrichLeadCallout {
    public static HttpResponse zoominfoCallout(String jwtToken, String requestBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.zoominfo.com/enrich/company');   
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + jwtToken);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);

        String ErrorString = 'Invalid username and/or password - please try again.';

        if(response.getStatusCode()!=200 && response.getBody() == ErrorString){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'evan.smith@chromeriver.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('ZoomInfo CallOut Failed');
            mail.setPlainTextBody('When attempting to make a callout via the ZoomInfo API, authentication failed. Please navigate to the "Custom Settings" element in Setup and take a look at the Custom Settng titled "ZoomInfo Authentication Setting" and change the Username and Password combo. The errors were as follows: ' + response.getBody() + 'The error status was: ' + response.getStatus()+ ' The error code was: ' + response.getStatusCode());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});

        }
        if(response.getStatusCode()!=200 && response.getBody() != ErrorString){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'evan.smith@chromeriver.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('ZoomInfo CallOut Failed');
            mail.setPlainTextBody('When attempting to make a callout via the ZoomInfo API, the body of your callout JSON was improperly formatted. Please re-attempt with proper JSON format: ' + response.getBody() + 'The error status was: ' + response.getStatus()+ ' The error code was: ' + response.getStatusCode());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
        return response;

    }
}