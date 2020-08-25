# zoominfo-on-demand-callout

Our company was running into a problem where the data we had in Salesforce was enough to auto-enrich the vast majority of leads. But our data coverage for companies under 1000 employees wasn't enough to cover the last 15-20% that came into Salesforce. In order to fill this gap, we needed on-demand data and we needed it bad!

Since our company had a ZoomInfo subscription, I requested access to their API as they didn't have a great solution for on-demand data enrichment. Putting together this integration was a ton of fun and was pretty immediately put to good use (upon completion and thorough testing of course)!

To get a better understanding of ZoomInfo's API, please see their API docs here: [ZoomInfo API Docs](https://api-docs.zoominfo.com/)

My plan of attack was structured like so:

1. Build out a class to make callouts to their Authentication API endpoint (as found in the ZoomInfoAuthentication class)
2. Build out a class that uses the returned JSON web token from the ZoomInfoAuthentication class to make a callout to their Company Enrich endpoint (as found in the ZoomInfoCompanyEnrichLeadCallout class)
3. Make a few sample callouts to their Company Enrich endpoint and gather enough sample JSON to understand how I'll tackle parsing the body of the http response. This involved making callouts with funky data with no returned companies.
4. Build out the on-demand ZoomInfoLeadProcessor class to have a future method called that executes the ZoomInfoAuthenication callout, executes the subsequent ZoomInfoCompanyEnrichLeadCallout callout, parses the data and standardizes fields to our picklist values, and finally updates the leads.
5. Test, test, test!!

As a note, you'll see in the ZoomInfoLeadProcessor class that I query an object called ZIAuthCreds__c to gather the values for the username and password for the Authentication endpoint. This design choice was made to ensure that Admins could easily modify the Custom Setting object rather than reference some hardcoded user credentials. It's also meant to provide a layer of security so that I can post this code on GitHub!

For reference, the ZoomInfoLeadProcessor class is called by a Lead trigger in our instance. I didn't include this trigger as it is unremarkable and just references a few custom fields in our instance.
