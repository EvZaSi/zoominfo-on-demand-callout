public class ZoomInfoAuthentication {

    public static HttpResponse makeCallout(String username, String password){

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.zoominfo.com/authenticate');   
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"username":"' + username + '","password":"' + password + '"}');
        HttpResponse response = http.send(request);

        if(response.getStatusCode()!=200){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'evan.smith@chromeriver.com'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('ZoomInfo Authentication Failed');
            mail.setPlainTextBody('When attempting to make a callout via the ZoomInfo API, authentication failed. Please navigate to the "Custom Settings" element in Setup and take a look at the Custom Settng titled "ZoomInfo Authentication Setting" and change the Username and Password combo. The errors were as follows: ' + response.getBody() + 'The error status was: ' + response.getStatus()+ ' The error code was: ' + response.getStatusCode());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});

        }
        return response;

    }
        
}

