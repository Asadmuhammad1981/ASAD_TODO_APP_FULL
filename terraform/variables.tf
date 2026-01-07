variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  sensitive   = false
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true   # This hides the value in logs and output
}