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

variable "ssh_public_key_path" {
  type    = string
  default = ""
}

variable "sub_id" {
  type    = string
  default = ""
  sensitive = true
}