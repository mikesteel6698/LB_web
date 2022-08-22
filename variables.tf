variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "test_vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "test_az" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "ami_id" {
  default = "ami-08d4ac5b634553e16"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "key" {
  type = string
}

variable "root_volume_size" {
  type    = number
  default = 10
}

variable "home_directory" {
  type = string
}

variable "username" {
  type = string
}

variable "nodes_tags" {
  type    = list(string)
  default = ["ubuntu_1", "ubuntu_2"]
}

variable "bucket_name" {
  type    = string
  default = "tfbackendpro"
}

variable "versioning" {
  type    = bool
  default = true

}