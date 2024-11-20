# data "terraform_remote_state" "vpc" {
#     backend = "s3"

#     config = {
#         bucket = "PARAMS.BUCKET"
#         key    = "dm/PARAMS.ENV_NAME/vpc/terraform.tfstate"
#         region = "PARAMS.S3_BUCKET_REGION"
#     }
# }

# data "terraform_remote_state" "eks" {
#     backend = "s3"

#     config = {
#         bucket = "PARAMS.BUCKET"
#         key    = "dm/PARAMS.ENV_NAME/eks/terraform.tfstate"
#         region = "PARAMS.S3_BUCKET_REGION"
#     }
# }