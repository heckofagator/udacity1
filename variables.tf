# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "prefix" {
  description = "The name prefix which should be used for all resources in this example"
  default     = "udacity-project"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "admin_username" {
  description = "The admin username for the VM being created."
  default     = "azureuser"
}

variable "admin_password" {
  description = "The password for the VM being created."
  default     = "Azurepassword1!"
}

variable "vm_count" {
  description = "Number of VMs in this deployment"
  type        = number
  default     = 2
}

variable "tag_name" {
  description = "Tag Name"
  type        = string
  default     = "Environment"
}

variable "tag_value" {
  description = "Tag Value"
  type        = string
  default     = "Test"
}

variable "vm_size" {
  description = "azure SKU for VM size"
  default     = "Standard_B1s"
}

variable "man_disk_size" {
  description = "size of the VM managed disk"
  default     = 1
}

variable "storage_account_type" {
  description = "type of storage" 
  default     = "Standard_LRS"
}

variable "mandisk_caching" {
  description = "type of caching for the managed disk"
  default     = "ReadWrite"
}

variable "create_option" {
  description = "the create_option value for the managed disk"
  default     = "Empty"
}

variable "subscription_id" {
  description = "Azure subscription id where the resources will be built"
  default     = "b6a27b6d-3141-46ad-871e-7a588457c248"
}