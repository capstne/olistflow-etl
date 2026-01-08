locals {
  name = "${var.project}-${var.env}"

  tags = merge(
    {
      Project     = var.project
      Environment = var.env
    },
    var.tags
  )
}
