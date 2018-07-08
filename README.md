# Integrate Azure Monitor logs with a SIEM, Analytics Tool, or Monitoring Solution

AzureMonitor4Siem makes it easy to setup [Azure Monitor](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-overview-azure-monitor) and download the Azure activity logs it provides to a Windows, macOS, or Linux computer.  From there, you can quickly setup a log file-based integration with a SIEM, analytics tool, or monitoring solution of your choice.  

Want to do more?  Need to replace AzLog?  No problem!  Feel free to use our project and source code as a starter kit.   

## How It Works
Azure Monitor enables you to [stream Azure activity logs](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-stream-activity-logs-event-hubs) into an [Azure Event Hub](https://azure.microsoft.com/en-us/services/event-hubs/).  A client application can then connect to Event Hub and download the activity logs placed into it.  

Our AzureMonitor4Siem project has two components: a script to setup the resources in Azure to support log streaming, and an application to download the logs to a computer.

***setupAzureMonitor&#46;sh*** is a Bash shell script that automates the creation and configuration of the Azure resources required to support activity log streaming from Azure Monitor into Event Hub.  Our Azure CLI powered script:

* Creates an Azure Resource Group that will contain all the Azure-based resources required to support the integration
* Creates an Event Hub namespace 
* Configures Azure Monitor to export and stream activity logs into a new Event Hub within the just-created Event Hub namespace 
* Creates and configures an Azure Blob Storage account, and within that Storage account a Storage Container, which will be used to manage the synchronization state of the client application
* Generates Shared Access Signatures for both the Event Hub and Blob Storage account, eliminating the need to use master account keys in the client application
* Generates a configuration file (***azureMonitor4SiemSettings&#46;json***) storing all connection parameters required by the client application.

NOTE: If you don't want to use our setup script to create and configure the required Azure resources, no problem!  We'll describe manual the steps required and the settings you need to place into ***azureMonitor4SiemSettings&#46;json***

***AzureMonitor4Siem***, the client application, is built using [.NET Core](https://www.microsoft.com/net/) and can be run on Windows, macOS, and Linux.  It connects to the Event Hub created by Azure Monitor and downloads Azure activity logs to the local filesystem of the computer it's running on.  This application makes use of:

*  [Generic Host](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/host/generic-host) feaure introduced in .NET Core 2.1 
*  [Event Hub Processor Host](https://www.nuget.org/packages/Microsoft.Azure.ServiceBus.EventProcessorHost), part of the Event Hub .NET SDK, which integrates with Azure Storage to support checkpointing and parallel receives
*  Connectivity values within ***azureMonitor4SiemSettings&#46;json*** configuration file as generated by the ***setupAzureMonitor&#46;sh*** script

Let's get started! 

## Identify your working environment

Identify an Azure Environment and User Account
* You'll need an Azure account that has privileges to create and configure the Azure resources and services we've described 
* If you don’t already have an Azure account, [register for a free trial](https://azure.microsoft.com/en-us/free/) that includes $200 in credits.

Identify how you want to setup the Azure resources required to support Azure log streaming.
   * Recommended: Use our  ***setupAzureMonitor&#46;sh*** script on a computer or environment that has Bash
   * Alternative: Manually setup the Azure resources using the directions we provide through the Azure Portal.  This is also a good option if you don't want to setup a Bash environment.

Identify where you want to want to build and run the ***AzureMonitor4Siem*** client application
*  Your Own Environment:  This can be a VM you setup in Azure, your own computer, or any physical or virtual machine with connectivity to Azure and the Internet.  You'll need to:
   *  Clone this GitHub repository.    
      *  This will also include the ***setupAzureMonitor&#46;sh*** setup script. 
   *  [Download](https://www.microsoft.com/net/download/core) and install .NET Core 2.1 SDK, which is necessary to build and run the ***AzureMonitor4Siem*** application that downloads logs from Azure your computer

*  Easy Setup - Azure Virtual Machine: Don't want to setup our use your own compute?  We can also create an Ubuntu virtual machine in Azure that:
   * Contains a clone of this GitHub Repository  
      * This will also include the ***setupAzureMonitor&#46;sh*** setup script. 
   * Downloads and installs .NET Core 2.1 SDK on your behalf
   
   * Click the Deploy to Azure button below to get started
      * We've pre-selected a low-cost VM series (Standard_A1) available in all Azure regions.
      * If you change it, make sure the VM Series you enter is available in the Azure region you target. Need help? The Azure VM Comparision website will show you the VMs available in a given region https://azureprice.net/
      * Azure supports data disks of up to 4TB (4095 GB). We've defaulted you to 512 GB.
      * DNS Label Prefix is the public-facing hostname of the machine.  It must be unique to the Azure region you are deploying to.  
         * If you deploy to West US 2, for example, the fully-qualified hostname will be: your-hostname.westus2.cloudapp.azure.com
         * Creatively challenged?  Just leave it blank.  We'll generate a unique one for you.  You can change it later.
         * Picking one yourself?
            * Unfortunately, we're unable to determine if the value you enter is already being used at this time.  
            * We suggest you append the month, day, year to achieve uniqueness.  For example: your-hostname-01012018
            * After the machine has been created, you can go back and change it through the Azure Portal
      * Before you deploy, you'll need to Agree to the terms and click Purchase to begin deployment.  As a reminder, you're not actually paying to use this free template. However, the resources that you deploy and make use of will be billed to your subscription.

         <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftamhinsf%2FAzureMonitor4Siem%2Fmaster%2Fazuredeploy.json" target="_blank"> <img alt="Deploy to Azure" src="http://azuredeploy.net/deploybutton.png"/>
</a>&nbsp;&nbsp;<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Ftamhinsf%2FAzureMonitor4Siem%2Fmaster%2Fazuredeploy.json" target="_blank"> <img src="http://armviz.io/visualizebutton.png"/></a>

     * Once you've begun your deployment, you can remain in the Azure Portal or navigate away and come back. Either way, you'll receive a notification in the Azure Portal upon completion. Once this has occured:
        * Navigate to the Azure Resource Group you targeted
        * Look for a virtual machine called "azmo4siem".   Click it.
        * On the "Overview" Pane for "azmo4siem", you can click:
           * DNS Name if you don't like the unique value we generated for the public-facing hostname
           * Connect to see the username@hostname value you can supply to your SSH client.
        * Connect using your SSH credentials
     * After you login, look for a file called "done" in your home directory. This is an indication that the scripts used for configuration and deployment have completed. 
     * Review the file called /tmp/azuredeploy.log.xxxx where xxxx is a random four digit number. Check for errors. The operations performed by our scripts may have failed due to unexpected network timeouts or other reasons.


## Setup Azure resources with ***setupAzureMonitor&#46;sh*** (recommended)

Follow these steps if you want to use our ***setupAzureMonitor&#46;sh*** script to setup the Azure resources required to enable log streaming.  

### Setup Bash Environment 

You will need a Bash environment and Azure CLI 2.0 to run the ***setupAzureMonitor&#46;sh*** setup script

   *  Mac and Linux environments inclue Bash
      * [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and install Azure CLI 2.0.
   *  Windows Server and Windows 10
      * [Windows 10 Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) and [Windows Server Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-on-server), known as "WSL", provides a Bash environment that can run in a Windows 10 and Windows Server environment
      * If you're using WSL, you'll need to install the Linux version of Azure CLI.
      *  [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and install Azure CLI 2.0.
   *  Easy Setup - Azure Virtual Machine
      * If you chose our Easy Setup option, the Ubuntu-based Azure Virtual machine we created for you has bash installed and setup as the default shell.
   *  Alternatively, ***setupAzureMonitor&#46;sh*** does not have to run on the same computer as the client application.  You can run it elsewhere, as long as that environment has Bash and Azure CLI installed.  For instance:
      * [Azure Cloud Shell](https://shell.azure.com) provides you a browser-based Bash environment with Azure CLI pre-installed.   
      * You can also [deploy](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal) a Linux Virtual machine in Azure

### Review and Run setupAzureMonitor&#46;sh

*  Go to the folder containing your local clone of this repository
   * If you used our Easy Setup - Azure Virtual Machine option, the path to the local clone will be /azmo/AzureMonitor4Siem
*  In a text editor, open ***setupAzureMonitor&#46;sh***  
*  There are a number of variables you may wish to alter.  The values provided can probably be used as-is - but let's be sure!  
      * ***AZ_RESOURCE_GROUP*** is the name of the Azure Resource group that will contain the Azure resources created and used.  The name you use must be unique to your Azure subscription.
      *  ***AZ_REGION*** is the name of the Azure region in which the Resource Group and all of the supporting resources will be deployed.  By default, the script deploys to "westus2".  You can a list of region names through the Azure CLI as follows:
         * az login
         * az account list-locations --query [*].name
   *  Two variables must be unique across all of Azure.  To help you, we automatically append the current date and time, using a variable called ***DATE_TIME*** to the following values
      * ***AZ_STORAGE_ACCOUNT*** - the name of the Azure Storage account to create
      * ***AZ_EVENTHUB_NAMESPACE***  - the name of the Azure Event Hub namespace
*  Optional: If you need to run ***setupAzureMonitor&#46;sh*** elsewhere (i.e. your computer doesn't have Bash), copy it to the destination environment. You can also consider copying-and-pasting its content to a file of the same name.
*  Change the permissions on ***setupAzureMonitor&#46;sh*** to make sure it can be run:
   * chmod +x ***setupAzureMonitor&#46;sh***
* Run ***setupAzureMonitor&#46;sh*** as follows:
   * ./setupAzureMonitor.sh
      *  Follow the directions to log in to Azure.  If you have logged in to Azure using Azure CLI before ("az login"), you have the option of using locally cached credentials.  
      *  You will be given the option of destroying any resource group that has the same name as the one you wish to use.  Deleting the resource group will also destroy all resources within it.  This is particularly useful if you plan to run the ***setupAzureMonitor&#46;sh*** script multiple times for testing and demo purposes.
*  The script will take 5 to 10 minutes to complete
   * You may see "Waiting for Event Hub Creation to complete" several times
*  You'll be given the option of identifying the folder where downloaded activity log files are stored.  
   *  If you change your mind, alter the value of ***az_local_logs_dir*** in ***azureMonitor4SiemSettings&#46;json***.
   *  If you don't provide a value, we'll create a temporary folder each time you start the application
* A file named ***azureMonitor4SiemSettings&#46;json*** will be created containing all of the connection parameters needed by ***AzureMonitor4Siem*** to download Azure activity logs. 
   *  If you are running ***setupAzureMonitor&#46;sh*** in a different environment than where you will build and run AzureMonitor4Siem, you must copy  ***azureMonitor4SiemSettings&#46;json*** back to it.  Alternatvely, you can copy-and-paste the content into a file of the same name.

## Setup Azure resources manually (optional)


If you've already followed the directions in the section called "Setup Azure Environment with ***setupAzureMonitor&#46;sh***" you can skip to the "Build and Run AzureMonitor4Siem" section.   

The process below describes the steps required to manually configure the Azure resources needed to support Azure Monitor log streaming.  

* Navigate to the folder containing your local clone of this repository
   * Create a copy of the file name ***azureMonitor4SiemSettings&#46;sample&#46;json*** named ***azureMonitor4SiemSettings&#46;json*** 
   * ***azureMonitor4SiemSettings&#46;json***  will contain the connection parameters required by the client application to connect to Azure
   * If you used our Easy Setup - Azure Virtual Machine option, the path to the local clone will be /azmo/AzureMonitor4Siem

We'll assume that you have a working familiarity with how to access the Azure portal and setup resources.   The steps below are meant to provide you high-level guidance. 

* Login to the Azure portal
* Create or identify the Resource Group you want to place the supporting Azure components into, and make use of it as you create them.  
* Create an Event Hub namespace
  * ***azureMonitor4SiemSettings&#46;json***  - Assign the Event Hub namespace name to the value ***az_event_hub_name***
  * ***azureMonitor4SiemSettings&#46;json***  - Shared access policies -> RootManageSharedAccessKey -> Assign an Event Hub connection string to the value ***az_event_hub_connection_string***
  * Note: When you setup Azure Monitor (next step), an Event Hub within the Event Hub namespace will automatically be created with the name "insights-operational-logs".  Do not create an Azure Event Hub at this time.  
* Setup Azure Monitor
  * Navigate to Azure Monitor -> Activity Log -> Export
  * Export activity log
     * Regions -> Select all
     * Export to an event hub -> Select
     * Service bus namespace 
        * Select event hub namespace -> Pick the Event Hub namespace you just created
        * Select event hub policy name -> Pick RootManageSharedAccessKey
     * In the background, the process to create an Event Hub named "insights-operational-logs" will automatically be started.
* Setup Azure Storage
  * Create an Azure Storage account
     * ***azureMonitor4SiemSettings&#46;json***  - Access Keys -> Assign the Storage Account name to the value ***az_storage_account***
     * ***azureMonitor4SiemSettings&#46;json*** - Access Keys -> Assign the Storage Account connecting string to ***az_storage_account_connection_string***     
  * Within the Azure Storage account, create a Blob Storage Container
     * ***azureMonitor4SiemSettings&#46;json***  - Assign the Blob Storage Container name to the value ***az_storage_account_blob_container***
* Identify Log File Location
     * ***azureMonitor4SiemSettings&#46;json***  - Assign the file system path where downloaded logs should be stored to  az_local_logs_dir

#### Manual Setup Advanced Security (Optional)

Azure Event Hubs and Storage Accounts support the use of Shared Access Signatures (SAS).  These enable you to reduce the level and duration of access a client application has to these two resources.  You can create a SAS for the Event Hub and Storage Account connection used by ***AzureMonitor4Siem***.

* Event Hub - You can create a SAS at the Event Hub (insights-operational-logs) or Event Hub namespace level.  The only permission required by ***AzureMonitor4Siem*** is Listen.  Apply the associated connection string to the value of ***az_event_hub_connection_string*** in ***azureMonitor4SiemSettings&#46;json***
* Storage Account - Generate a SAS at the Storage Account level. Grant access to: 
   * Blob service
   * Service, Container, Object resource types
   * Read, Write, Delete, List, Add, Create permissions
   * Set a Start time prior to the current date and time (to be safe)
   * Set an End expiry time sufficiently far into the future
   * Allowed IP addresses, Allowed protocols, and Signing key can be set to your needs
   * Click Generate SAS and connection string.  Copy the Connection string into the value of ***az_storage_account_connection_string*** in ***azureMonitor4SiemSettings&#46;json***
 
## Build and Run AzureMonitor4Siem
*  Navigate to the folder containing your local clone of this repository
   * If you used our Easy Setup - Azure Virtual Machine option, the path to the local clone will be /azmo/AzureMonitor4Siem
*  Make sure that ***azureMonitor4SiemSettings&#46;json***, as created by ***setupAzureMonitor&#46;sh*** is present.  If you manually setup the supporting Azure resources, make sure this file is present and contains the values listed the section "Setup Azure Environment manually". 
*  Run these commands to build and run the client application that will download Activity logs to your computer:
    *  dotnet clean
    *  dotnet build
    *  dotnet run

* Upon successful startup, you should see something like this:

```
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Log directory is /path/you/identified info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      OnStarted has been called.
Application started. Press Ctrl+C to shut down.
Hosting environment: Development
Content root path: /path/to/your/cloned/repo/AzureMonitor4Siem/bin/Debug/netcoreapp2.1/
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      SimpleEventProcessor initialized. Partition: '0'
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      SimpleEventProcessor initialized. Partition: '1'
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      SimpleEventProcessor initialized. Partition: '2'
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      SimpleEventProcessor initialized. Partition: '3'
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
To exit the program, simpy type Control-C
```

Whenever ***AzureMonitor4Siem*** downloads a new log file from Event Hub, you'll see a notice similiar to this on your screen

```
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
File written in /path/you/identified/1528870414.74773 at 6/12/18 11:13:34 PM
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
File written in /path/you/identified/1528870414.74775 at 6/12/18 11:13:34 PM
```

Pressing Control-C will shut down AzureMonitor4Siem.   
```
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      OnStopping has been called.
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Processor Shutting Down. Partition '1', Reason: 'Shutdown'.
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Processor Shutting Down. Partition '3', Reason: 'Shutdown'.
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Processor Shutting Down. Partition '0', Reason: 'Shutdown'.
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Processor Shutting Down. Partition '2', Reason: 'Shutdown'.
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      Log directory is /path/you/identified
info: AzureMonitor4Siem.LifetimeEventsHostedService[0]
      OnStopped has been called.
```

## Publish and Install AzureMonitor4Siem

If you're happy with the results, you can optionally publish AzureMonitor4Siem into a self-contained application.  This will enable you to run AzureMonitor4Siem from another folder or  another computer of the same operating system.
*  Navigate to the folder containing your local clone of this repository
   * If you used our Easy Setup - Azure Virtual Machine option, the path to the local clone will be /azmo/AzureMonitor4Siem
*  Determine the directory you want to publish and install AzureMonitor4Siem into.
*  Find the "Runtime Identifier" (RID) that corresponds to your operating system environment on the following website https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
   * Here are the RIDs for some popular operating systems
      * Windows 10 / Windows Server 2016 is win10-x64
      * Mac OS X is osx-x64
      * Ubuntu is ubuntu-x64
* Run the dotnet publish command, supply the RID for your environment, and your installation folder
   * dotnet publish -c Release --self-contained -r your-RID -o /your/destination/folder
   * Here's an example for Ubuntu
      * dotnet publish -c Release --self-contained -r ubuntu-x64 -o /your/destination/folder
   * The publish command will copy your configuration file ***azureMonitor4SiemSettings&#46;json*** to the destination folder as well.
   * Now, you can run AzureMonitor4Siem simply like this:
      * /your/destination/folder/AzureMonitor4Siem

## Customizing AzureMonitor4Siem

***LifetimeEventsHostedService.cs*** contains the code that manages the lifecycle of the ***AzureMonitor4Siem***.  There are event handlers where you can add additional activities that occur upon startup (OnStarted), during shut down (OnStopping), and after shut down (OnStop). 

***SimpleEventProcessor.cs*** manages the processing of the activity logs placed into Azure Event Hub.  It is registered within ***LifetimeEventsHostedService*** inside OnStarted and un-registerered through OnStopping.  Within ***SimpleEventProcessor*** ***ProcessEventsAsync*** is responsible for iterating over the Azure activity logs placed by Azure Monitor into Event Hub and writing them to a local file.   As such, ***ProcessEventsAsync*** is a great place to author your own custom action.   

## Acknowledgements

AzureMonitor4Siem is based upon the code contained in the following GitHub repositories.   Thank you the individuals involved in creating and providing Open Source solutions on Azure.

* [Receive events with the Event Processor Host in .NET Standard](https://github.com/Azure/azure-event-hubs/tree/master/samples/DotNet/Microsoft.Azure.EventHubs/SampleEphReceiver)
* [ASP.NET Generic Host Sample](https://github.com/aspnet/Docs/tree/master/aspnetcore/fundamentals/host/generic-host/samples/2.x/GenericHostSample)


## Questions and comments
We'd love to get your feedback about this sample. You can send your questions and suggestions to us in the Issues section of this repository.

Questions about Azure Monitor development in general should be posted to Stack Overflow. Make sure that your questions or comments are tagged with [azure-monitoring](https://stackoverflow.com/questions/tagged/azure-monitoring).

## Resources

*  [Azure Monitor](https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-overview-azure-monitor)
*  [Azure Event Hubs](https://azure.microsoft.com/en-us/services/event-hubs/)
*  [Azure Storage](https://azure.microsoft.com/en-us/services/storage/)
*  [Azure CLI 2.0](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
*  [.NET Core](https://www.microsoft.com/net/)

## Copyright

Copyright (c) 2018 Tam Huynh. All rights reserved. 


### Disclaimer ###
**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
