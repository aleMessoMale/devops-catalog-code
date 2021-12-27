variable "region" {
  type    = string
  default = "ue-west-1"
}

variable "cluster_name" {
  type    = string
  default = "casula-cluster"
}

variable "min_node_count" {
  type    = number
  default = 3
}

variable "max_node_count" {
  type    = number
  default = 9
}

variable "machine_type" {
  type    = string
  default = "t2.micro"
}

variable "k8s_version" {
  type = string
  default = "1.20"
}

variable "release_version" {
  type = string
  default = ""
}

# variable "ingress_nginx" {
#   type    = bool
#   default = false
# }
