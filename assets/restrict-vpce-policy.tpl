{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyCreateSecurityGroupOutsideVpc",
            "Effect": "Deny",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:vpc/*"
            ],
            "Condition": {
                "StringNotLike": {
                    "ec2:VpcId": "${aws_vpc_id}"
                }
            }
        }
    ]
}