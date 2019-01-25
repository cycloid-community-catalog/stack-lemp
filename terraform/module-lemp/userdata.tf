data "template_file" "user_data_front" {
  template = "${file("${path.module}/templates/userdata.sh.tpl")}"

  vars {
    env                = "${var.env}"
    project            = "${var.project}"
    customer           = "${var.customer}"
    role               = "front"
    signal_stack_name  = "${var.project}-front-${var.env}"
    signal_resource_id = "Fronts${var.env}"
    vault_password     = "${var.vault_password}"
  }
}
