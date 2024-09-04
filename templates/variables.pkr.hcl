variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "template_user_password" {
  type      = string
  sensitive = true
}

variable "pm_api_url" {
  type    = string
  default = "https://10.0.1.10:8006/api2/json"
}

variable "iso_filename" {
  type = string
}

variable "iso_hash" {
  type = string
}

variable "vm_id" {
  type = string
}