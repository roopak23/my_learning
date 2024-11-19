provider "aws" {
  region = var.aws_region
   default_tags {
   tags = {
     Project     = "hawkeye"
   }
 }
  assume_role {
    role_arn    = var.deployrolearn
    external_id = var.deploysitid
  }
}
 
