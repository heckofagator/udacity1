# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Once you have the dependancies complete, we can begin with the disk image creation via Packer.

Pre-Req for Packer work
1. Create New or Use Existing Azure Resource Group
2. Create a Service Principle in Azure Extra with proper Write Permissions
  More info here:
  https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals

Image File Creation using Packer
In the Builders stanza (building the new base OS image):
1. Enter your Service Principal client ID, secret and subscription ID into the demo.json file (lines 10-12)
2. Edit image sku, location, tags and VM size (lines 13-23)
3. Enter the Azure resource group where this image will be stored (line 20)
4. Enter the name of the image file (line 21)

In the Provisioners stanza (post-boot install and config to be included in the image):
1. include any additional inline shell commands to be run post-boot
The current config creates a very simple index.html file and configured busybox

More info can be found here:
https://developer.hashicorp.com/packer/docs/templates/hcl_templates/syntax-json

To Create the new Disk Image:
1. run 'packer build demo.json'
2. Watch for any errors

Verify Disk Image
1. Check your Azure Resouce group for the new disk image


Infrastructure Build Using Terraform and the main.tf and variables.tf files

The main.tf file contains all of the azure teraform code to build a small, dynamic 
web server(s) solution in Microsoft Azure.  The Infrastructure as Code has be written
so that variables can be used to change the way the infrastructure is configured.

Below is a list of all changable variables from the variables.tf file.  
You are welcome to leave the IaC as-is (default will be used), but if you like to change a variable, please skip to the next section "TERRAFORM USAGE" where you can specify
your own values for the variables.

variable "prefix" 
  description = "The name prefix which should be used for all resources in this example"
  default     = "udacity-project"

variable "location"
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"

variable "admin_username"
  description = "The admin username for the VM being created."
  default     = "azureuser"

variable "admin_password"
  description = "The password for the VM being created."
  default     = "Azurepassword1!"

variable "vm_count"
  description = "Number of VMs in this deployment"
  default     = 2

variable "tag_name"
  description = "Tag Name"
  default     = "Environment"

variable "tag_value"
  description = "Tag Value"
  default     = "Test"

variable "vm_size"
  description = "azure SKU for VM size"
  default     = "Standard_B1s"

variable "man_disk_size"
  description = "size of the VM managed disk"
  default     = 1

variable "storage_account_type"
  description = "type of storage" 
  default     = "Standard_LRS"

variable "mandisk_caching"
  description = "type of caching for the managed disk"
  default     = "ReadWrite"

variable "create_option"
  description = "the create_option value for the managed disk"
  default     = "Empty"

variable "subscription_id"
  description = "Azure subscription id where the resources will be built"
  default     = "b6a27b6d-3141-46ad-871e-7a588457c248"


Terraform Usage 
(more info here https://developer.hashicorp.com/terraform/intro/core-workflow)
To initialize the system, run:
'terraform init'

to have terraform sync up the infrastrucre with its state file, run:
'terraform plan'

to then have terraform build the infrastructure, run:
'terraform apply'

If you would like to edit any of the above mentioned variables, you can add the 
following to the plan and apply statement
'-var "name-value"'

For example, if you'd like to change the Managed Disk size, your terraform syntax would be:
'terraform plan -var "man_disk_size=20"'
'terraform apply -var "man_disk_size=20"'

Once the 'terraform apply' is complete, your infrastructure build in Azure should be complete.

When you are ready to tear down the newly build infrastructure, you can run
'terraform destroy'

### Output
The Infrastrucre as Code main.tf will build the following:

At a high level:
A fully functional, secure, redundant and scalable web server

At a lower level:
* An Azure Resource group, virtual network and subnet
* a Network Security Group (NSG) applied to the subnet with explicit and default rules
* 2 (or more) Virtual Machines with an OS Disk, Data Disk and a private/internal NIC
* A Public IP which can be reached from the Internet
* A Load Balancer which takes application traffic fro the Public IP and forwards to the VMs
* An availability set for redundancy

