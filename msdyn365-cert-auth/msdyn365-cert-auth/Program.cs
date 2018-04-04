using Microsoft.Crm.Sdk.Messages;
using Microsoft.Xrm.Tooling.Connector;
using System;
using System.Security.Cryptography.X509Certificates;
using static System.Configuration.ConfigurationManager;

namespace msdyn365_cert_auth
{
    class Program
    {
        static void Main(string[] args)
        {
            // Environment variables
            var thumbPrint = AppSettings["CertificateThumbPrint"];
            var crmUrl = new Uri(AppSettings["DynamicsUrl"]);
            var clientId = AppSettings["ClientId"];
            var redirectUri = new Uri(AppSettings["RedirectUri"]);

            // Retrieve certificate from personal store
            var myCertStore = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            myCertStore.Open(OpenFlags.ReadOnly);
            var cert = myCertStore.Certificates.Find(X509FindType.FindByThumbprint, thumbPrint, false)[0];

            // Authenticate with 
            var client = new CrmServiceClient(
                certificate: cert,
                certificateStoreName: StoreName.My,
                certificateThumbPrint: thumbPrint,
                instanceUrl: crmUrl, 
                useUniqueInstance: true, 
                orgDetail: null, 
                clientId: clientId, 
                redirectUri: redirectUri, 
                tokenCachePath: "c:\\cache");


            var result = client.Execute(new WhoAmIRequest());
        }
    }
}
