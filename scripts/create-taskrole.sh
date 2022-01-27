#!/bin/bash

SERVICE=$1
ENV=$2
METHOD=$3

if [ -z "$METHOD" ]; then
	METHOD="s3"
fi

aws iam get-role --role-name credentials-$SERVICE-$ENV

if [ "$?" -eq "0" ]; then
	echo "Taskrole already exists"
	exit 0
fi

POLICY=$(cat <<EOT
{
	"Version": "2012-10-17",
		"Statement": [
		{
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "ecs-tasks.amazonaws.com"
			},
			"Effect": "Allow",
			"Sid": ""
		}
		]
}
EOT
)

aws iam create-role --role-name credentials-$SERVICE-$ENV --assume-role-policy-document "$POLICY"


if [[ "$METHOD" == "iam" ]]; then
    echo "Using IAM method, no IAM policy needed"
elif [[ "$METHOD" == "s3" ]]; then
    echo "Using S3 method, creating IAM policy"
    ROLE=$(cat <<EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "s3:GetObjectVersionTorrent",
                    "s3:GetObjectAcl",
                    "s3:GetObject",
                    "s3:GetObjectTorrent",
                    "s3:GetObjectVersionTagging",
                    "s3:GetObjectVersionAcl",
                    "s3:GetObjectTagging",
                    "s3:GetObjectVersionForReplication",
                    "s3:GetObjectVersion"
                ],
                "Resource": "arn:aws:s3:::vault-credentials/$SERVICE-$ENV"
            }
        ]
    }
EOT
    )
    aws iam put-role-policy --role-name credentials-$SERVICE-$ENV --policy-name credentials-$SERVICE-$ENV --policy-document "$ROLE"
else
	echo "Method '$METHOD' unknown"
	exit 1
fi


