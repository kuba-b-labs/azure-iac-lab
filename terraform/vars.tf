variable "grafana_user" {
  type      = string
  default   = ""
  sensitive = true
}

variable "grafana_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "sub_id" {
  type      = string
  default   = ""
  sensitive = true
}
variable "ssh_public_key" {
  type    = string
  default = ""
  sensitive = true
}
variable "my_ip" {
  type      = string
  default   = ""
  sensitive = true
}
variable "storage_account_key" {
  type      = string
  default   = ""
  sensitive = true
}