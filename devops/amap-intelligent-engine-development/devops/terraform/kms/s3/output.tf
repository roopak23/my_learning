output "key_arn" {
  description = "kms arn"
  value = module.kms_key.key_arn
}
output "key_id" {
  description = "kms id"
  value = module.kms_key.key_id
}

output "alias_arn" {
  description = "kms id"
  value = module.kms_key.alias_arn
}