# README.md

## HOWTO enable FileAppender in CloudHub 2.0
https://help.salesforce.com/s/articleView?id=001119412&type=1
CloudHub 2.0 | Anypoint monitoring custom file appender disabled
Publish Date: 2024年3月2日

`customFileAppender.enable=true`

検索条件： 「log appender cloudhub 2.0」

## How to Send Logs via Log4j2.xml to AWS S3 in Mule 4
https://help.salesforce.com/s/articleView?id=001115774&type=1

### AWS IAM Policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::ysk-mule-log-to-s3/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
```