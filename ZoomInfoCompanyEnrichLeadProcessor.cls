public class ZoomInfoCompanyEnrichLeadProcessor {
    @future (callout=true)
    public static void enrichLeadsWithZIData(List<Id> leadIDsToProcess){
        ZIAuthCreds__c ziCreds = ZIAuthCreds__c.getValues('ID');

        System.debug('testing');

        String jwtToken = getZoomInfoAuthToken(ziCreds.Username__c, ziCreds.Password__c);
        if(jwtToken == 'failure'){
            return;
        }
        List<Lead> updateList = new List<Lead>();
        List<Id> idListForRunningAssignmentRules = new List<Id>();

        List<Lead> leadsToProcess = generateLeadList(leadIDsToProcess);
        List<Lead> leadListWithConfirmedEmails = removeLeadsWithNoEmail(leadsToProcess);


        for(Lead indLead : leadListWithConfirmedEmails){
            String requestJSONBody = createZoomInfoCompanyEnrichmentRequestBody(indLead);
            String returnedJSON = sendZoomInfoCompanyEnrichmentCallOut(requestJSONBody, jwtToken);

            if(verifyIfZoomInfoReturnedData(returnedJSON) == False){
                notifyLeadsWithNoReturnedData(indLead);
                indLead.ZoomInfo_Auto_Enrich__c = True;
                updateList.add(indLead);
                continue;
            }else{      
                parseAndAddZoomInfoData(indLead,returnedJSON);
                indLead.ZoomInfo_Auto_Enrich__c = True;
                updateList.add(indLead);
                idListForRunningAssignmentRules.add(indLead.Id);
            }
        }
        prepToRunAssignmentRules(updateList);
        update updateList;

    }
    private static List<Lead> generateLeadList(List<Id> idList){
        List<Lead> leadsToProcess = [SELECT Id,Email,DOZISF__ZoomInfo_Company_ID__c,Company,NumberOfEmployees,Street,City,State,Country,NAICS_Code__c,DOZISF__ZoomInfo_Last_Updated__c FROM Lead WHERE ID in :idList];
        return leadsToProcess;
    }
    private static void prepToRunAssignmentRules(List<Lead> assignList){
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule= true;          
        for(Lead indLead:assignList){
            indLead.setOptions(dmo);
        }
    }
    private static String getZoomInfoAuthToken(String username, String password){
        HttpResponse authenticationResponse = ZoomInfoAuthentication.makeCallout(username,password);
        JSONParser tokenParser = JSON.createParser(authenticationResponse.getBody());
        String jwtToken;
        if(authenticationResponse.getStatusCode()!=200){
            jwtToken = 'failure';
        }else{
            while (tokenParser.nextToken() != null){
                if(tokenParser.getCurrentName() == 'jwt' && tokenParser.getText() != 'jwt'){
                    jwtToken = tokenParser.getText();
                }
            }
        }
        return jwtToken;
    }
    private static List<Lead> removeLeadsWithNoEmail(List<Lead> processLeadList){
        List<Lead> removeList = new List<Lead>();
        for(Lead indLead : processLeadList){
            if(indLead.Email == null || indLead.Email == ''){
                removeList.add(indLead);
            }
        }
        if(removeList.size() > 0){
            notifyLeadsWithNoEmail(removeList);
        }
        for(Lead removeLead : removeList){
            processLeadList.remove(processLeadList.indexOf(removeLead));
        }
        return processLeadList;
    }
    private static void notifyLeadsWithNoEmail(List<Lead> leadsWithNoEmail){
        String bodyText = 'When attempting to enrich leads via ZoomInfo, the following leads were unable to be added to the enrichment process due to a lack of an email: ';
        for(Lead noEmailLead:leadsWithNoEmail){
            bodyText += 'https://chromeriver.my.salesforce.com/' + String.valueOf(noEmailLead.Id);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'evan.smith@chromeriver.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Leads without requisite data for ZoomInfo Enrichment');
        mail.setPlainTextBody(bodyText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
    private static void notifyLeadsWithNoReturnedData(Lead leadWithNoReturnedData){
        String bodyText = 'When attempting to enrich leads via ZoomInfo, the following lead resulted in no data found by ZoomInfo: ';
        bodyText += 'https://chromeriver.my.salesforce.com/' + String.valueOf(leadWithNoReturnedData.Id);
        bodyText += ' The lead had the following info when submitted to ZoomInfo: ';
        bodyText += 'Company Name: ' + leadWithNoReturnedData.Company + '  ';
        bodyText += 'Email : ' + leadWithNoReturnedData.Email;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'evan.smith@chromeriver.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Lead returned no data via ZoomInfo Enrichment API');
        mail.setPlainTextBody(bodyText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }
    private static String createZoomInfoCompanyEnrichmentRequestBody(Lead processLead){
        String requestBody = '{"matchCompanyInput":[';
        String leadInputs = '{';
        if(processLead.Company != '[not provided]' || processLead.Company != null){
            leadInputs += '"companyName":"' + processLead.Company + '",';
        }
        if(processLead.Country != null){
            leadInputs += '"companyCountry":"' + processLead.Country + '",';
        }
        String emailString = String.valueOf(processLead.Email);
        String companyWebsiteString = 'http://www.';
        companyWebsiteString += emailString.substring(emailString.indexOfChar(64));
        leadInputs += '"companyWebsite":"' + companyWebsiteString + '"}';

        requestBody += leadInputs;               
        requestBody += '],"outputFields":["id","name","employeeCount","street","city","state","country","naicsCodes","primaryIndustry"]}';

        return requestBody;
    }
    private static String sendZoomInfoCompanyEnrichmentCallOut(String requestBody, String jwtToken){
            HttpResponse enrichmentResponse = ZoomInfoCompanyEnrichLeadCallout.zoominfoCallout(jwtToken,requestBody);
            return enrichmentResponse.getBody();
        }
    private static String extractIndustryValueFromJSONData(String enrichDataJSON){
        String extractedIndustry = enrichDataJSON.substringBetween('"primaryIndustry":["','"');
        return extractedIndustry;

    }
    private static String normalizeIndustryToPicklistValues(String industryBeforeStandardization){
        switch on industryBeforeStandardization{
            when 'Business Services'{
                industryBeforeStandardization = 'Professional Service';
            }
            when 'Consumer Services'{
                industryBeforeStandardization = 'Retail';
            }
            when 'Energy, Utilities & Waste'{
                industryBeforeStandardization = 'Utilities';
            }
            when 'Healthcare Services'{
                industryBeforeStandardization = 'Healthcare';
            }
            when 'Holding Companies & Conglomerates'{
                industryBeforeStandardization = 'Other';
            }
            when 'Hospitals & Physicians Clinics'{
                industryBeforeStandardization = 'Healthcare';
            }
            when 'Law Firms & Legal Services'{
                industryBeforeStandardization = 'Legal';
            }
            when 'Media & Internet'{
                industryBeforeStandardization = 'Media';
            }
            when 'Minerals & Mining'{
                industryBeforeStandardization = 'Agriculture';
            }
            when 'Organizations'{
                industryBeforeStandardization = 'Other';
            }
            when 'Software'{
                industryBeforeStandardization = 'Technology';
            }
            when 'Telecommunications'{
                industryBeforeStandardization = 'Telecom';
            }
        }return industryBeforeStandardization;

    }
    private static void parseAndAddZoomInfoData(Lead leadToEnrich,String enrichDataJSON){
        Integer employeeOccurenceCount = 0;
        Integer idOccurenceCount = 0;
        Integer nameOccurenceCount = 0;
        Boolean firstNAICSValue = True;
        JSONParser parser = JSON.createParser(enrichDataJSON);

        while (parser.nextToken() != null){
            if(parser.getCurrentName() == 'id'){
                if(idOccurenceCount < 1){
                    idOccurenceCount += 1;
                }else if(idOccurenceCount == 1){
                    leadToEnrich.DOZISF__ZoomInfo_Company_ID__c = parser.getText();
                    idOccurenceCount = 99;
                }    
            }
            if(parser.getCurrentName() == 'name'){
                if(nameOccurenceCount < 1){
                    nameOccurenceCount += 1;
                }else if(nameOccurenceCount == 1){
                    leadToEnrich.Company = parser.getText();
                    nameOccurenceCount = 99;
                }    
            }
            if(parser.getCurrentName() == 'employeeCount'){
                if(employeeOccurenceCount < 1){
                    employeeOccurenceCount += 1;
                }else if(employeeOccurenceCount == 1){
                    leadToEnrich.NumberOfEmployees = Integer.valueOf(parser.getText());
                    employeeOccurenceCount = 99;
                }    
            }
            if(parser.getCurrentName() == 'street'){
                leadToEnrich.Street = parser.getText();
            }
            if(parser.getCurrentName() == 'city'){
                leadToEnrich.City = parser.getText();
            }
            if(parser.getCurrentName() == 'state'){
                leadToEnrich.State = parser.getText();
            }
            if(parser.getCurrentName() == 'country'){
                leadToEnrich.Country = parser.getText();
            }
            if(parser.getCurrentName() == 'naicsCodes' && firstNAICSValue == True){
                firstNAICSValue = False;
                parser.nextValue();
                parser.nextValue();
                parser.nextValue();
                leadToEnrich.NAICS_Code__c = parser.getText();
            }
        }
        leadToEnrich.DOZISF__ZoomInfo_Last_Updated__c = System.today();

        String normalizeIndustryToPicklistValues = extractIndustryValueFromJSONData(enrichDataJSON);
        leadToEnrich.Industry = normalizeIndustryToPicklistValues(normalizeIndustryToPicklistValues);

    }
    private static Boolean verifyIfZoomInfoReturnedData(String enrichDataJSON){
        Boolean returnedUsableData = True;
        JSONParser parser = JSON.createParser(enrichDataJSON);

        while (parser.nextToken() != null){
            if(parser.getCurrentName() == 'data' && parser.getCurrentToken() == JSONToken.START_ARRAY && parser.nextToken() == JSONToken.END_ARRAY){
                    returnedUsableData = False;
            }
        }
        return returnedUsableData;
    }





}
