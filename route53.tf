resource "aws_route53_zone" "easy_aws" {
name = "innovativewebservices.site"

tags = {
Environment = "test"
}
}
resource "aws_route53_record" "www" {
zone_id = aws_route53_zone.easy_aws.zone_id
name    = "www.innovativewebservices.site"
    type    = "A"
    ttl     = "300"
    records = ["xx.xx.xx.xx"]
}


