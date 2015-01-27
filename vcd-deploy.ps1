## VMware vCloud configuration. Powershell 4.0 + PowerCLI 5.8 release 1
## Please update vcd-config.xml to suit your environment
## Created by Ranjit RJ Singh - Zero liablity assumed run at your own risk
## www.rjapproves.com @rjapproves
##
##
##

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

Add-PSSnapin Vmware.vimautomation.core
Add-PSSnapin VMware.VimAutomation.Vds
Set-StrictMode -Version 2.0

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#Reading the XML config file

$xml = [XML](Get-Content vcd-config.xml)

#Configure Rest Authentication
 $vcdHost = $xml.Masterconfig.vcdconfig.vcd_fqdn
 $api=$xml.Masterconfig.vcdconfig.vcdapi
 $username = $xml.Masterconfig.vcdconfig.vcduser
 $password = $xml.Masterconfig.vcdconfig.vcdpassword
 $vcdOrg = 'system'
 $amqp_host = $xml.Masterconfig.vcdconfig.amqphost
 $org_name = $xml.Masterconfig.vcdconfig.orgname

 $vcenteruser = $xml.Masterconfig.vcenterconfig.vcenteruser
 $vcenterpassword = $xml.Masterconfig.vcenterconfig.vcenterpassword
 $cluster_name = $xml.Masterconfig.vcenterconfig.cluster_name
 $vcenter_fqdn = $xml.Masterconfig.vcenterconfig.vcenterfqdn
 
 $vshield_fqdn = $xml.Masterconfig.vshieldinfo.vshieldfqdn
 $vshield_user = $xml.Masterconfig.vshieldinfo.vshielduser
 $vshield_password = $xml.Masterconfig.vshieldinfo.vshieldpassword

 $hostcount = $xml.Masterconfig.hostcount
 $hostname = @()
 $hostroot = @()
 $hostpassword = @()
 $hosthrefurl = @()
 $hostMOref = @()

#Picking up all the hosts

 foreach($i in $xml.Masterconfig.hostinfo.hostconfig){

 #for($i = 1; $i -le $hostcount; $i++){
 $hostname += $i.hostname
 $hostroot += $i.hostroot
 $hostpassword += $i.hostpassword
 }

 $authenticate = $username+'@'+$vcdOrg+':'+$password

 
#Connect to the vcenter where vSM will be deployed
Write-host "Connecting to vcenter..."
connect-viserver -server $vcenter_fqdn -protocol https -username $vcenteruser -password $vcenterpassword | Out-Null

$resource_full_id = Get-ResourcePool -Location $cluster_name | Select-Object -ExpandProperty Id | Out-String 
$resourcemoid = $resource_full_id.Replace("ResourcePool-resgroup","resgroup")
$resourcemoid = $resourcemoid.Trim()

 #Encode basic authentication header
 $encoded = [System.Text.Encoding]::UTF8.GetBytes($authenticate)
 $encode_password = [System.Convert]::ToBase64String($encoded)

 #define standard header
 $headers = @{"Accept"="application/*+xml;version=1.5"}

 #issue a request. VCD will allow an unauthenticated GET to the https://VCD/api/versions URL
 $baseurl="https://$vcdHost/api"
 #create full address of resource to be retrieved
 $resource='/versions'
 $url=$baseurl+$resource
 
 $versions = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
 ForEach ($version in $versions.SupportedVersions.VersionInfo)
 {
    if ($version.Version -eq $api)
    {
        $loginURL = $version.LoginUrl
     }
 }
    If ($loginURL -ne $null)
    {
        #do a POST with our headers to the service/login URL, capture the auth toke in a session object
        $headers += @{"Authorization"="Basic $($encode_password)"}
        Invoke-RestMethod -Uri $loginURL -Headers $headers -Method POST -Session MYSESSION | Out-Null
    }

#Function for general settings to be configured

Function General-settings(){
$general_settings_url = "https://"+$vcdhost+"/api/admin/extension/settings/general"

$body = @"
<?xml version="1.0" encoding="UTF-8"?>
<vmext:GeneralSettings xmlns:vmext="http://www.vmware.com/vcloud/extension/v1.5" xmlns:vcloud="http://www.vmware.com/vcloud/v1.5" type="application/vnd.vmware.admin.generalSettings+xml" href="https://${vcdhost}/api/admin/extension/settings/general" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/extension/v1.5 http://${vcdhost}/api/v1.5/schema/vmwextensions.xsd http://www.vmware.com/vcloud/v1.5 http://${vcdhost}/api/v1.5/schema/master.xsd">
<vcloud:Link rel="truststore:update" type="application/vnd.vmware.admin.vcTrustStoreUpdateParams+xml" href="https://${vcdhost}/api/admin/extension/settings/general/action/updateVcTrustsore" /> 
<vcloud:Link rel="truststore:reset" href="https://${vcdhost}/api/admin/extension/settings/general/action/resetVcTrustsore" /> 
<vmext:AbsoluteSessionTimeoutMinutes>1440</vmext:AbsoluteSessionTimeoutMinutes> 
<vmext:ActivityLogDisplayDays>30</vmext:ActivityLogDisplayDays> 
<vmext:ActivityLogKeepDays>90</vmext:ActivityLogKeepDays> 
<vmext:AllowOverlappingExtNets>false</vmext:AllowOverlappingExtNets> 
<vmext:ChargebackEventsKeepDays>365</vmext:ChargebackEventsKeepDays> 
<vmext:ChargebackTablesCleanupJobTimeInSeconds>10800</vmext:ChargebackTablesCleanupJobTimeInSeconds> 
<vmext:ConsoleProxyExternalAddress /> 
<vmext:HostCheckDelayInSeconds>300</vmext:HostCheckDelayInSeconds> 
<vmext:HostCheckTimeoutSeconds>30</vmext:HostCheckTimeoutSeconds> 
<vmext:InstallationId>1</vmext:InstallationId> 
<vmext:IpReservationTimeoutSeconds>7200</vmext:IpReservationTimeoutSeconds> 
<vmext:SyslogServerSettings /> <vmext:LoginNameOnly>false</vmext:LoginNameOnly> 
<vmext:PrePopDefaultName>true</vmext:PrePopDefaultName> 
<vmext:QuarantineEnabled>false</vmext:QuarantineEnabled> 
<vmext:QuarantineResponseTimeoutSeconds>21600</vmext:QuarantineResponseTimeoutSeconds> 
<vmext:RestApiBaseUri /> <vmext:SessionTimeoutMinutes>30</vmext:SessionTimeoutMinutes> 
<vmext:ShowStackTraces>false</vmext:ShowStackTraces> 
<vmext:SyncStartDate>9999-12-31T23:59:59.997-05:00</vmext:SyncStartDate> 
<vmext:SyncIntervalInHours>24</vmext:SyncIntervalInHours> 
<vmext:TransferSessionTimeoutSeconds>3600</vmext:TransferSessionTimeoutSeconds> 
<vmext:VerifyVcCertificates>false</vmext:VerifyVcCertificates> 
<vmext:VcTruststoreType>JCEKS</vmext:VcTruststoreType> 
<vmext:VerifyVsmCertificates>false</vmext:VerifyVsmCertificates>
<vmext:ElasticAllocationPool>false</vmext:ElasticAllocationPool></vmext:GeneralSettings>
"@

Invoke-RestMethod -Uri $general_settings_url -Headers $headers -Body $body -Method PUT -ContentType "application/vnd.vmware.admin.generalSettings+xml" -WebSession $MYSESSION
}

#Branding function - if you dont have one then comment this out - default commented out.
#function branding-settings(){
#$branding_url =  "https://"+$vcdhost+"/api/admin/extension/settings/branding"
### Enter hex code for the css theme below in the $theme1 variable
#$theme1 = ""
#$body = @"
#<?xml version="1.0" encoding="UTF-8"?>
#<BrandingSettings xmlns="http://www.vmware.com/vcloud/extension/v1.5" xmlns:vcloud="http://www.vmware.com/vcloud/v1.5" type="application/vnd.vmware.admin.brandingSettings+xml" href="https://192.168.1.21/api/admin/extension/settings/branding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/extension/v1.5 http://${vcdhost}/api/v1.5/schema/vmwextensions.xsd http://www.vmware.com/vcloud/v1.5 http://${vcdhost}/api/v1.5/schema/master.xsd">
#<CompanyName>TEST</CompanyName>
#    <LoginPageCustomizationTheme>${theme1}</LoginPageCustomizationTheme>
#</BrandingSettings>
#"@
#Invoke-RestMethod -Uri $branding_url -Headers $headers -Body $body -Method PUT -ContentType "application/vnd.vmware.admin.brandingSettings+xml" -WebSession $MYSESSION
#}

#Extensibility settings
Function AMQP-Settings(){
$AMQP_url = "https://"+$vcdhost+"/api/admin/extension/settings/amqp"
$notification_url = "https://"+$vcdhost+"/api/admin/extension/settings/notifications"
$body = @"
<?xml version="1.0" encoding="UTF-8"?>
<vmext:AmqpSettings xmlns:vmext="http://www.vmware.com/vcloud/extension/v1.5" xmlns:vcloud="http://www.vmware.com/vcloud/v1.5" type="application/vnd.vmware.admin.amqpSettings+xml" href="https://${vcdhost}/api/admin/extension/settings/amqp" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/extension/v1.5 http://${vcdhost}/api/v1.5/schema/vmwextensions.xsd http://www.vmware.com/vcloud/v1.5 http://${vcdhost}/api/v1.5/schema/master.xsd">
<vcloud:Link rel="test" type="application/vnd.vmware.admin.amqpSettings+xml" href="https://192.168.1.21/api/admin/extension/settings/amqp/action/test" />
<vcloud:Link rel="certificate:update" type="application/vnd.vmware.admin.certificateUpdateParams+xml" href="https://${vcdhost}/api/admin/extension/settings/amqp/action/updateAmqpCertificate" />
<vcloud:Link rel="certificate:reset" href="https://${vcdhost}/api/admin/extension/settings/amqp/action/resetAmqpCertificate" />
<vcloud:Link rel="truststore:update" type="application/vnd.vmware.admin.trustStoreUpdateParams+xml" href="https://${vcdhost}/api/admin/extension/settings/amqp/action/updateAmqpTruststore" />
<vcloud:Link rel="truststore:reset" href="https://${vcdhost}/api/admin/extension/settings/amqp/action/resetAmqpTruststore" />
<vmext:AmqpHost>${amqp_host}</vmext:AmqpHost>
<vmext:AmqpPort>5672</vmext:AmqpPort>
<vmext:AmqpUsername>guest</vmext:AmqpUsername>
<vmext:AmqpExchange>systemExchange</vmext:AmqpExchange>
<vmext:AmqpVHost>v1.api.rvi.rackspace.com</vmext:AmqpVHost>
<vmext:AmqpUseSSL>false</vmext:AmqpUseSSL>
<vmext:AmqpSslAcceptAll>false</vmext:AmqpSslAcceptAll>
<vmext:AmqpPrefix>vcd</vmext:AmqpPrefix>
</vmext:AmqpSettings>
"@

$notificationbody = @"
<?xml version="1.0" encoding="UTF-8"?>
<vmext:NotificationsSettings xmlns:vmext="http://www.vmware.com/vcloud/extension/v1.5" xmlns:vcloud="http://www.vmware.com/vcloud/v1.5" type="application/vnd.vmware.admin.notificationsSettings+xml" href="https://${vcdhost}/api/admin/extension/settings/notifications" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vmware.com/vcloud/extension/v1.5 http://${vcdhost}/api/v1.5/schema/vmwextensions.xsd http://www.vmware.com/vcloud/v1.5 http://${vcdhost}/api/v1.5/schema/master.xsd">
<vcloud:Link rel="edit" type="application/vnd.vmware.admin.notificationsSettings+xml" href="https://${vcdhost}/api/admin/extension/settings/notifications" />
<vmext:EnableNotifications>true</vmext:EnableNotifications>
</vmext:NotificationsSettings>
"@
Invoke-RestMethod -Uri $notification_url -Headers $headers -Body $notificationbody -Method Put -WebSession $MYSESSION
Invoke-RestMethod -Uri $AMQP_url -Headers $headers -Body $body -Method Put -WebSession $MYSESSION
}


#Adding vcenter function
Function Add-vcenter(){
$reg_vcenter_url = "https://"+$vcdhost+"/api/admin/extension/action/registervimserver"
$body = @"
<?xml version="1.0" encoding="UTF-8"?>
<vmext:RegisterVimServerParams
 xmlns:vmext="http://www.vmware.com/vcloud/extension/v1.5"
 xmlns:vcloud="http://www.vmware.com/vcloud/v1.5">
 <vmext:VimServer
 name="${vcenter_fqdn}">
 <vmext:Username>${vcenteruser}</vmext:Username>
 <vmext:Password>${vcenterpassword}</vmext:Password>
 <vmext:Url>https://${vcenter_fqdn}:443</vmext:Url>
 <vmext:IsEnabled>true</vmext:IsEnabled>
 </vmext:VimServer>
 <vmext:ShieldManager
 name="${vshield_fqdn}">
 <vmext:Username>${vshield_user}</vmext:Username>
 <vmext:Password>${vshield_password}</vmext:Password>
 <vmext:Url>https://${vshield_fqdn}</vmext:Url>
 </vmext:ShieldManager>
</vmext:RegisterVimServerParams>
"@


Invoke-RestMethod -Uri $reg_vcenter_url -Headers $headers -Body $body -Method Post -ContentType  "application/vnd.vmware.admin.registerVimServerParams+xml" -WebSession $MYSESSION
}

#Creating an organization
Function Create-org(){
$create_org_url = "https://"+$vcdhost+"/api/admin/orgs"
$body = @"
<?xml version="1.0" encoding="UTF-8"?>
<AdminOrg
 xmlns="http://www.vmware.com/vcloud/v1.5"
 name="${org_name}"
 type="application/vnd.vmware.admin.organization+xml">
 <Description>${org_name}</Description>
 <FullName>${org_name}</FullName>
 <IsEnabled>1</IsEnabled>
 <Settings>
 <OrgGeneralSettings>
 <CanPublishCatalogs>false</CanPublishCatalogs>
 <CanPublishExternally>true</CanPublishExternally>
 <CanSubscribe>true</CanSubscribe>
 <DeployedVMQuota>0</DeployedVMQuota>
 <StoredVmQuota>0</StoredVmQuota>
 <UseServerBootSequence>false</UseServerBootSequence>
 <DelayAfterPowerOnSeconds>0</DelayAfterPowerOnSeconds>
 </OrgGeneralSettings>
 <OrgLdapSettings>
 <OrgLdapMode>SYSTEM</OrgLdapMode>
 <CustomUsersOu />
 </OrgLdapSettings>
 <OrgEmailSettings>
 <IsDefaultSmtpServer>true</IsDefaultSmtpServer>
 <IsDefaultOrgEmail>true</IsDefaultOrgEmail>
 <FromEmailAddress />
 <DefaultSubjectPrefix />
 <IsAlertEmailToAllAdmins>true</IsAlertEmailToAllAdmins>
 </OrgEmailSettings>
 </Settings>
</AdminOrg>
"@
Invoke-RestMethod -Uri $create_org_url -Headers $headers -Body $body -Method Post -ContentType "application/vnd.vmware.admin.organization+xml" -WebSession $MYSESSION
}

Function Vcenter-endpoint-href(){
$vcenter_ref_url = "https://"+$vcdhost+"/api/admin/extension/vimServerReferences"

$reader = Invoke-RestMethod -Uri $vcenter_ref_url -Headers $headers -Method GET -WebSession $MYSESSION
[xml]$xmloutput = $reader



return $xmloutput.VMWVimServerReferences.VimServerReference.href

}

Function vcenter-endpoint-urls($vc_endpoint_url){
$reader = Invoke-RestMethod -Uri $vc_endpoint_url -Headers $headers -Method GET -WebSession $MYSESSION
[xml]$xmloutput = $reader

foreach($vim_obj_references in $xmloutput.VimServer.link){
        if($vim_obj_references.type -eq "application/vnd.vmware.admin.vmwHostReferences+xml"){
         $global:host_reference_url = $vim_obj_references.href
         }
        if($vim_obj_references.type -eq "application/vnd.vmware.admin.vimServerNetworks+xml"){
        $global:network_reference_url = $vim_obj_references.href
        }
        if($vim_obj_references.type -eq "application/vnd.vmware.admin.vmwStorageProfiles+xml"){
        $global:storage_profiles_reference_url = $vim_obj_references.href
        }
    }
}

#creating a provider vdc
Function create_providervdc($vc_endpoint_ref){
$url = "https://"+$vcdhost+"/api/admin/extension/providervdcsparams"


$primarybody=@"
<VMWProviderVdcParams xmlns="http://www.vmware.com/vcloud/extension/v1.5" xmlns:vcloud_v1.5="http://www.vmware.com/vcloud/v1.5" name="${org_name}">
    <ResourcePoolRefs>
        <VimObjectRef>
            <VimServerRef xmlns="http://www.vmware.com/vcloud/extension/v1.5" href="${vc_endpoint_ref}" />
            <MoRef>${resourcemoid}</MoRef>
            <VimObjectType>RESOURCE_POOL</VimObjectType>
        </VimObjectRef>
    </ResourcePoolRefs>
    <VimServer xmlns="http://www.vmware.com/vcloud/extension/v1.5" href="${vc_endpoint_ref}" />
    <IsEnabled>1</IsEnabled>
    <StorageProfile>Gold</StorageProfile>
    <HostRefs>
"@

foreach($unitofhost in $hostname){

$primarybody +=@"
<HostObjectRef>
            <VimServerRef xmlns="http://www.vmware.com/vcloud/extension/v1.5" href="${vc_endpoint_ref}" />
            <MoRef>${hostMoref}</MoRef>
            <VimObjectType>HOST</VimObjectType>
            <Username>${hostroot}</Username>
            <Password>${hostpassword}</Password>
        </HostObjectRef>
"@

$primarybody +=@"
    </HostRefs>
</VMWProviderVdcParams>
"@
Invoke-RestMethod -Uri $url -Headers $headers -Body $primarybody -Method Post -ContentType "application/vnd.vmware.admin.createProviderVdcParams+xml" -WebSession $MYSESSION
}
}

Function grab-host-metadata($vc_endpoint_url){
$hostrefurl = $vc_endpoint_url+"/hostReferences"
$reader = Invoke-RestMethod -Uri $hostrefurl -Headers $headers -Method GET -contentType "application/vnd.vmware.admin.vmwHostReferences+xml" -WebSession $MYSESSION
[xml]$xmloutput = $reader
$xmloutput | Export-Clixml c:\hostmoref1.xml

for($i=0; $i -le $hostname.Length; $i++){
foreach($hostxmlinfo in $xmloutput.VMWHostReferences.HostReference){
        if($hostxmlinfo.name -eq $hostname[$i]){
         $global:hosthrefurl += [String[]]$hostxmlinfo.href
        
         }
        }
    }

foreach($abc in $hosthrefurl){

$hostinforeader = Invoke-RestMethod -Uri $abc -Headers $headers -Method GET -ContentType "application/vnd.vmware.admin.host+xml" -WebSession $MYSESSION
[xml]$xmloutput = $hostinforeader
foreach ($unit in $xmloutput.host){
    $global:hostMOref += [String[]]$unit.VmMoRef
     }
    }
}

#Create a custom role
Function create_customer_role(){
$rolename = @()
$rolehref = @()
$url = "https://"+$vcdhost+"/api/admin"
$reader = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ContentType "application/vnd.vmware.admin.right+xml" -WebSession $MYSESSION 
[xml]$xmloutput = $reader
foreach($unit in $xmloutput.vcloud.RightReferences.Rightreference){
if($unit.Name -eq "Catalog: Change Owner"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: Create / Delete a Catalog"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: Edit Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: Sharing"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: Publish"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: View Private and Shared Catalogs"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Catalog: View Published Catalogs"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp Template: Checkout"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp Template / Media: Copy"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp Template / Media: Create / Upload"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp Template / Media: Edit"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp Template / Media: View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Disk: Change Owner"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Disk: Create"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Disk: Delete"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Disk: Edit Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Disk: View Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "General: Administrator View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Organization vDC Network: View Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Organization Network: View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Organization: View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Organization vDC: View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "Group / User: View"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Use Console"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Change Owner"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Create / Reconfigure"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Snapshot Operations"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Delete"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit VM Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit VM CPU"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit VM Hard Disk"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit VM Memory"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit VM Network"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Edit Properties"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Manage VM Password Settings"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Sharing"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Power Operations"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}if($unit.Name -eq "vApp: Upload"){
    $rolename +=$unit.name
    $rolehref +=$unit.href
}
}

$roleurl = "https://"+$vcdhost+"/api/admin/roles"
$body += @"
<?xml version="1.0" encoding="UTF-8"?>
<Role name="Customer Role" xmlns="http://www.vmware.com/vcloud/v1.5"><Description>Customer Role</Description>
<RightReferences>
"@
for($i=0; $i -lt $rolename.length; $i++){
$nameofrole = $rolename[$i]
$hrefofrole = $rolehref[$i]
$body +=@"
<RightReference type="application/vnd.vmware.admin.right+xml" name="${nameofrole}" href="${hrefofrole}" />
"@
}
$body +=@"
</RightReferences></Role>
"@
Invoke-RestMethod -Uri $roleurl -body $body -Headers $headers -Method POST -ContentType "application/vnd.vmware.admin.role+xml" -WebSession $MYSESSION 

}

### Code begins execution here..


General-settings
#branding-settings
AMQP-Settings
Add-vcenter
Create-org
$vcenter_endpoint = Vcenter-endpoint-href
write-host $vcenter_endpoint
grab-host-metadata($vcenter_endpoint)
create_providervdc($vcenter_endpoint)
Create_customer_role





