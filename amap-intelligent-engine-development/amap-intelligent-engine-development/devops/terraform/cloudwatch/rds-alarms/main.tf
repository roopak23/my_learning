module "rds-alarms" {
  source            = "lorenzoaiello/rds-alarms/aws"
  version           = "2.2.0"
  actions_alarm     = ["${var.actions_alarm}"]
  actions_ok        = ["${var.actions_ok}"]
  db_instance_id    = var.db_instance_id
  db_instance_class = var.db_instance_class
}
