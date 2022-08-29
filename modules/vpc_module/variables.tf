variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zone" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}