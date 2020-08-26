@isTest
public class ZoomInfoCompanyEnrichLeadProcessorTest {
    class SuccesfulEnrichLeadProcessMockCallout implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            if(req.getEndpoint().endsWith('authenticate')){
                mockResponse.setHeader('Content-Type', 'application/json');
                mockResponse.setStatusCode(200);
                mockResponse.setBody('{"success":true,"jwt":"testresponse"}');
            }else if(req.getEndpoint().endsWith('enrich/company')){
                mockResponse.setHeader('Content-Type', 'application/json');
                mockResponse.setStatusCode(200);
                mockResponse.setBody('{"success":true,"data":{"outputFields":[["id","name","employeecount","street","city","state","country","naicscodes","primaryindustry"]],"result":[{"input":{"companycountry":"united states","companyname":"salesforce","companywebsite":"http://www.salesforce.com"},"data":[{"id":239305146,"name":"Salesforce","employeeCount":36000,"street":"415 Mission St, Fl 3","city":"San Francisco","state":"California","country":"United States","naicsCodes":[{"id":"541511","name":"Custom Computer Programming Services"},{"id":"511","name":"Publishing Industries (except Internet)"},{"id":"5415","name":"Computer Systems Design and Related Services"},{"id":"5182","name":"Data Processing, Hosting, and Related Services"},{"id":"51","name":"Information"},{"id":"54151","name":"Computer Systems Design and Related Services"},{"id":"511210","name":"Software Publishers"},{"id":"5112","name":"Software Publishers"},{"id":"51821","name":"Data Processing, Hosting, and Related Services"},{"id":"518","name":"Data Processing, Hosting, and Related Services"},{"id":"51121","name":"Software Publishers"},{"id":"518210","name":"Data Processing, Hosting, and Related Services"}],"primaryIndustry":["Software","Customer Relationship Management (CRM) Software"]}]}]}}');

            } return mockResponse;
        }
    }
    class EnrichLeadProcessMockCalloutNoData implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            if(req.getEndpoint().endsWith('authenticate')){
                mockResponse.setHeader('Content-Type', 'application/json');
                mockResponse.setStatusCode(200);
                mockResponse.setBody('{"success":true,"jwt":"testresponse"}');
            }else if(req.getEndpoint().endsWith('enrich/company')){
                mockResponse.setHeader('Content-Type', 'application/json');
                mockResponse.setStatusCode(200);
                mockResponse.setBody('{"success":true,"data":{"outputFields":[["id","name","employeecount","street","city","state","country","naicscodes","primaryindustry"]],"result":[{"input":{"companycountry":"united states","companyname":"asdasdsa","companywebsite":"asdasd"},"data":[]}]}}');

            } return mockResponse;
        }
    }
    class UnsuccesfulAuthenticationLeadProcessMockCallout implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse mockResponse = new HttpResponse();
            if(req.getEndpoint().endsWith('authenticate')){
                mockResponse.setHeader('Content-Type', 'application/json');
                mockResponse.setStatusCode(400);
                mockResponse.setBody('fail');
            } return mockResponse;
        }
    }
    @TestSetup
    static void makeData(){

        ZIAuthCreds__c creds = new ZIAuthCreds__c(SetupOwnerId = '0051B00000DUTTEQA5',Username__c = 'test',Password__c = 'test');
        insert creds;

        List<Lead> testLeadList = new List<Lead>();

        Lead badAuthCredentialsTest = new Lead(LastName = 'Test',LeadSource = 'Advertisement',Company = 'TestCompanybadAuth');

        testLeadList.add(badAuthCredentialsTest);

        Lead companyListedAsNotProvided = new Lead(LastName = 'Test',LeadSource = 'Advertisement', Company = '[not provided]',Email = 'companynotprovided@salesforce.com',Country = 'United States');

        testLeadList.add(companyListedAsNotProvided);

        Lead countryNotProvided = new Lead(LastName = 'Test',LeadSource = 'Advertisement', Company = 'Salesforce',Email = 'countrynotprovided@salesforce.com',Country = 'United States');

        testLeadList.add(countryNotProvided);

        Lead emailAbsent = new Lead(LastName = 'Test',LeadSource = 'Advertisement', Company = 'EmailNotProvided',Country = 'United States');

        testLeadList.add(emailAbsent);

        Lead badLeadData = new Lead(LastName = 'Test',LeadSource = 'Advertisement', Company = 'asdjakaasd',Email = 'asjdaskdja@aslkdasd.com',Country = 'United States');

        testLeadList.add(badLeadData);

        insert testLeadList;

    }
    @isTest static void enrichWithBadAuthCredentials() {
        /* The purpose of this test is to prove out that an attempt to enrich with bad authentication credentials results in no update to the Lead, and results in a futureInvocation with an email send to notify the SFDC admin */
        Lead queryLead = [SELECT Id FROM Lead WHERE Company = 'TestCompanybadAuth' limit 1];
        List<Id> idList = new List<Id>();
        idList.add(queryLead.Id);

        Test.setMock(HttpCalloutMock.class, new UnsuccesfulAuthenticationLeadProcessMockCallout());

        Test.startTest();

        ZoomInfoCompanyEnrichLeadProcessor.enrichLeadsWithZIData(idList);

        Integer futureInvocations = Limits.getFutureCalls();
        Test.stopTest();

        Lead queryLeadAfterUpdate = [SELECT Id,NAICS_Code__c,Company,NumberOfEmployees,Industry,DOZISF__ZoomInfo_Company_ID__c,Street,City,State,Country,ZoomInfo_Auto_Enrich__c FROM Lead WHERE Company = 'TestCompanybadAuth' limit 1];

        System.assertEquals(1, futureInvocations);

        System.assertEquals(null, queryLeadAfterUpdate.NAICS_Code__c);
        System.assertEquals('TestCompanybadAuth', queryLeadAfterUpdate.Company);
        System.assertEquals(null, queryLeadAfterUpdate.NumberOfEmployees);
        System.assertEquals(null,queryLeadAfterUpdate.Industry);
        System.assertEquals(null,queryLeadAfterUpdate.DOZISF__ZoomInfo_Company_ID__c);
        System.assertEquals(null, queryLeadAfterUpdate.Street);
        System.assertEquals(null, queryLeadAfterUpdate.City);
        System.assertEquals(null, queryLeadAfterUpdate.State);
        System.assertEquals(null, queryLeadAfterUpdate.Country);
        System.assertEquals(False, queryLeadAfterUpdate.ZoomInfo_Auto_Enrich__c);
        
    }
    @isTest static void enrichWithCompanyNotProvided() {
        /* This test is to prove out that a query with the Company field left blank will still yield a successful returned JSON that the Lead can be succesfully updated with */
        Lead queryLead = [SELECT Id FROM Lead WHERE Email = 'companynotprovided@salesforce.com' limit 1];
        List<Id> idList = new List<Id>();
        idList.add(queryLead.Id);

        Test.setMock(HttpCalloutMock.class, new SuccesfulEnrichLeadProcessMockCallout());

        Test.startTest();

        ZoomInfoCompanyEnrichLeadProcessor.enrichLeadsWithZIData(idList);

        Test.stopTest();

        Lead queryLeadAfterUpdate = [SELECT Id,NAICS_Code__c,Company,NumberOfEmployees,Industry,DOZISF__ZoomInfo_Company_ID__c,Street,City,State,Country,ZoomInfo_Auto_Enrich__c FROM Lead WHERE Email = 'companynotprovided@salesforce.com' limit 1];

        System.assertEquals('541511', queryLeadAfterUpdate.NAICS_Code__c);
        System.assertEquals('Salesforce', queryLeadAfterUpdate.Company);
        System.assertEquals(36000, queryLeadAfterUpdate.NumberOfEmployees);
        System.assertEquals('Technology',queryLeadAfterUpdate.Industry);
        System.assertEquals('239305146',queryLeadAfterUpdate.DOZISF__ZoomInfo_Company_ID__c);
        System.assertEquals('415 Mission St, Fl 3', queryLeadAfterUpdate.Street);
        System.assertEquals('San Francisco', queryLeadAfterUpdate.City);
        System.assertEquals('California', queryLeadAfterUpdate.State);
        System.assertEquals('United States', queryLeadAfterUpdate.Country);
        System.assertEquals(True, queryLeadAfterUpdate.ZoomInfo_Auto_Enrich__c);
        
    }
    @isTest static void enrichWithCountryNotProvided() {
        /* This test is to prove out that a query with the Country field left blank will still yield a successful returned JSON that the Lead can be successfully updated with */
        Lead queryLead = [SELECT Id FROM Lead WHERE Email = 'countrynotprovided@salesforce.com' limit 1];
        List<Id> idList = new List<Id>();
        idList.add(queryLead.Id);

        Test.setMock(HttpCalloutMock.class, new SuccesfulEnrichLeadProcessMockCallout());

        Test.startTest();

        ZoomInfoCompanyEnrichLeadProcessor.enrichLeadsWithZIData(idList);

        Test.stopTest();

        Lead queryLeadAfterUpdate = [SELECT Id,NAICS_Code__c,Company,NumberOfEmployees,Industry,DOZISF__ZoomInfo_Company_ID__c,Street,City,State,Country,ZoomInfo_Auto_Enrich__c FROM Lead WHERE Email = 'countrynotprovided@salesforce.com' limit 1];

        System.assertEquals('541511', queryLeadAfterUpdate.NAICS_Code__c);
        System.assertEquals('Salesforce', queryLeadAfterUpdate.Company);
        System.assertEquals(36000, queryLeadAfterUpdate.NumberOfEmployees);
        System.assertEquals('Technology',queryLeadAfterUpdate.Industry);
        System.assertEquals('239305146',queryLeadAfterUpdate.DOZISF__ZoomInfo_Company_ID__c);
        System.assertEquals('415 Mission St, Fl 3', queryLeadAfterUpdate.Street);
        System.assertEquals('San Francisco', queryLeadAfterUpdate.City);
        System.assertEquals('California', queryLeadAfterUpdate.State);
        System.assertEquals('United States', queryLeadAfterUpdate.Country);
        System.assertEquals(True, queryLeadAfterUpdate.ZoomInfo_Auto_Enrich__c);
    }
    @isTest static void enrichWithEmailNotProvided() {
        /* This test is to prove out that calling the ZoomInfoCompanyEnrichLead Processor with a blank or no email provided will not result in a callout being made, an email will be sent to the SFDC admin notifying them that the callout was unable to be made (proven by the assertion with futureInvocations) and the Lead will not be updated with any enriched data */
        Lead queryLead = [SELECT Id FROM Lead WHERE Company = 'EmailNotProvided' limit 1];
        List<Id> idList = new List<Id>();
        idList.add(queryLead.Id);

        Test.setMock(HttpCalloutMock.class, new SuccesfulEnrichLeadProcessMockCallout());

        Test.startTest();

        ZoomInfoCompanyEnrichLeadProcessor.enrichLeadsWithZIData(idList);

        Integer futureInvocations = Limits.getFutureCalls();

        Test.stopTest();

        Lead queryLeadAfterUpdate = [SELECT Id,NAICS_Code__c,Company,NumberOfEmployees,Industry,DOZISF__ZoomInfo_Company_ID__c,Street,City,State,Country,ZoomInfo_Auto_Enrich__c FROM Lead WHERE Company = 'EmailNotProvided' limit 1];

        System.assertEquals(1, futureInvocations);

        System.assertEquals(null, queryLeadAfterUpdate.NAICS_Code__c);
        System.assertEquals('EmailNotProvided', queryLeadAfterUpdate.Company);
        System.assertEquals(null, queryLeadAfterUpdate.NumberOfEmployees);
        System.assertEquals(null,queryLeadAfterUpdate.Industry);
        System.assertEquals(null,queryLeadAfterUpdate.DOZISF__ZoomInfo_Company_ID__c);
        System.assertEquals(null, queryLeadAfterUpdate.Street);
        System.assertEquals(null, queryLeadAfterUpdate.City);
        System.assertEquals(null, queryLeadAfterUpdate.State);
        System.assertEquals('United States', queryLeadAfterUpdate.Country);
        System.assertEquals(False, queryLeadAfterUpdate.ZoomInfo_Auto_Enrich__c);
    }
    @isTest static void noDataReturned() {
        /* This test is to prove out that in the event an enrichment callout is successfuly made and no data is returned, the Lead will not be updated and an email will be sent to the SFDC admin notifying them that no data could be found */
        Lead queryLead = [SELECT Id FROM Lead WHERE Email = 'asjdaskdja@aslkdasd.com' limit 1];
        List<Id> idList = new List<Id>();
        idList.add(queryLead.Id);

        Test.setMock(HttpCalloutMock.class, new EnrichLeadProcessMockCalloutNoData());

        Test.startTest();

        ZoomInfoCompanyEnrichLeadProcessor.enrichLeadsWithZIData(idList);

        Integer futureInvocations = Limits.getFutureCalls();

        Test.stopTest();

        Lead queryLeadAfterUpdate = [SELECT Id,NAICS_Code__c,Company,NumberOfEmployees,Industry,DOZISF__ZoomInfo_Company_ID__c,Street,City,State,Country,ZoomInfo_Auto_Enrich__c FROM Lead WHERE Email = 'asjdaskdja@aslkdasd.com' limit 1];

        System.assertEquals(1, futureInvocations);

        System.assertEquals(null, queryLeadAfterUpdate.NAICS_Code__c);
        System.assertEquals('asdjakaasd', queryLeadAfterUpdate.Company);
        System.assertEquals(null, queryLeadAfterUpdate.NumberOfEmployees);
        System.assertEquals(null,queryLeadAfterUpdate.Industry);
        System.assertEquals(null,queryLeadAfterUpdate.DOZISF__ZoomInfo_Company_ID__c);
        System.assertEquals(null, queryLeadAfterUpdate.Street);
        System.assertEquals(null, queryLeadAfterUpdate.City);
        System.assertEquals(null, queryLeadAfterUpdate.State);
        System.assertEquals('United States', queryLeadAfterUpdate.Country);
        System.assertEquals(True, queryLeadAfterUpdate.ZoomInfo_Auto_Enrich__c);
    }
}
