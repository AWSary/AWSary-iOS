variable "organisation" {
  type        = string
  default     = ""
  description = "Name of the customer organisation."
}

variable "system" {
  type        = string
  default     = ""
  description = "Name of a dedicated system or application"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "common tags from project"
}
