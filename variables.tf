variable "lambda_policies_arn" {
  default = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}

variable "username" {
    type = string
    default = "Dan"
}

variable "region" {
    type = string
    default = "eu-west-1"
}

variable "user_policy" {
    type = string
    default = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

variable "src_dir" {
    type = string
    default = "zzzzz"
}

variable "pattern_file" {
    type = string
    default = "eventPattern.json"
}

variable "lambda_python_file" {
    type = string
    default = "removeCreds"
}

variable "lambda_role_name" {
    type = string
    default = "lambda_exec_role"
}

variable "ev_bridge_r_name" {
    type = string
    default = "GuardDutyKaliFinding"
}

variable "lambda_func_name" {
    type = string
    default = "RemoveKaliCredentials"
}

variable "bucket_name" {
    type = string
    default = "sens1t1ve-1nfo"
}

variable "s3_dir_name" {
    type = string
    default = "info/"
}

variable "file_name" {
    type = string
    default = "Boom.gif"
}