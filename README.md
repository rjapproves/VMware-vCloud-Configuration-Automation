VMware-vCloud-Configuration-Automation
======================================

VMware vCloud Configuration Automation using PowerCli + Restful API.

++++++
Notice == Script tested on ESXi 5.5 running vCenter 5.5 Update 2. No guarantees. Ensure you run it on test environment before executing in production. Owner assumes ZERO liability.
++++++

Introduction
============

The Script allows you to configure a vCloud Director environment.  Configuration here means that the script allows you to configure Administrative settings and other functions that make a VMware vCloud Director cell usable. The script does the below,

1. Configures Advanced settings of a vCloud director environment including adding a logo theme, extensibility, ip allocation settings etc. 
2. Attaches vCloud director cell to a VMware environment.
3. Prepares hosts
4. Creates Organizations
5. Creates Provider VDCs
6. Creates custom roles

The script does not create Networks or Organizatin VDC's yet which may be worked on in the future versions.

It uses Powershell and vCloud Director 5.6.x Rest API to configure the vCloud Director Cell.

The script was tested against a vCloud Director 5.5.x appliance and should behave the same with a production vCloud installation.

Prerequisites
=============

1. Powershell version 4.0
2. PowerCli version 5.8 Release 1
3. Network able to access vCenter, vCloud Director Cell and vShield IP's. 

Parts
=====
a. vcd-config.xml
b. vcd-deploy.ps1

Execution Method
================

Follow the below steps to properly execute the file.

1. Ensure vcd-config.xml and vcd-deploy.ps1 are in the same folder.
2. Populate vcd-config.xml with all the info as per your vCloud, vcenter, hosts and other relevant info. This allows you to configure your inputs before you execute the script.
3. Execute the script once vcd-config.xml is configured.

Contents VCD-Config.xml
===================
```xml
<?xml version="1.0"?>
<MasterConfig>

<vcenterconfig>
<vcenterfqdn></vcenterfqdn>
<vcenteruser></vcenteruser>
<vcenterpassword></vcenterpassword>
<Cluster_name></Cluster_name>
</vcenterconfig>

<vshieldinfo>
<vshieldfqdn></vshieldfqdn>
<vshielduser></vshielduser>
<vshieldpassword></vshieldpassword>
</vshieldinfo>

<vcdConfig>
<vcd_fqdn></vcd_fqdn>
<vcduser></vcduser>
<vcdpassword></vcdpassword>
<vcdapi>5.5</vcdapi>
<amqphost></amqphost>
<orgname></orgname>
</vcdConfig>


<hostcount>1</hostcount>
<hostinfo>
<hostconfig>
<hostname></hostname>
<hostroot>root</hostroot>
<hostpassword></hostpassword>
</hostconfig>
</hostinfo>

<hostcount>2</hostcount>
<hostinfo>
<hostconfig>
<hostname></hostname>
<hostroot>root</hostroot>
<hostpassword></hostpassword>
</hostconfig>
</hostinfo>
.....

<hostcount>...</hostcount>
<hostinfo>
<hostconfig>
<hostname></hostname>
<hostroot>root</hostroot>
<hostpassword></hostpassword>
</hostconfig>
</hostinfo>

</MasterConfig>
```
Known Issues
============

1. LDAP federation needs to be configured manually as it has been deprecated

2. Organization VDC's need to be created manually.

3. Networks need to be configured manually.




