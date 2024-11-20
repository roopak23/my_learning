# data "terraform_remote_state" "vpc" {
#     backend = "s3"

#     config = {
#         bucket = "PARAMS.BUCKET"
#         key    = "dm/PARAMS.ENV_NAME/vpc/terraform.tfstate"
#         region = "PARAMS.S3_BUCKET_REGION"
#     }
# }

# data "terraform_remote_state" "ec2_common" {
#     backend = "s3"

#     config = {
#         bucket = "PARAMS.BUCKET"
#         key    = "dm/PARAMS.ENV_NAME/ec2/common/terraform.tfstate"
#         region = "PARAMS.S3_BUCKET_REGION"
#     }
# }