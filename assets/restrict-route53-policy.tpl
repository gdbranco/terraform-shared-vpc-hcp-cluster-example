{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ChangeResourceRecordSetsRestrictedRecordNames",
            "Effect": "Deny",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "NotResource": [
                "${ingress_hosted_zone_arn}",
                "${hcp_internal_communication_hosted_zone_arn}"
            ]
        },
        {
            "Sid": "ChangeTagsForResourceNoCondition",
            "Effect": "Deny",
            "Action": [
                "route53:ChangeTagsForResource"
            ],
            "NotResource": [
                "${ingress_hosted_zone_arn}",
                "${hcp_internal_communication_hosted_zone_arn}"
            ]
        }
    ]
}