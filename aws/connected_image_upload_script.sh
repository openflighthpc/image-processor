#!/bin/bash -l

# variables:
final_image_name="Flight Solo 2001.6-29.06.01"
aws_image_name="SOLO2-2023.3-2804231815_aws.raw" #"What is the file name of the image?"
download_path="../downloads/"  #"What is the local file path of the downloaded image?"
bucket_name="repo.openflighthpc.org" # "What is the name of the bucket to upload to?"
s3_image_path="images/FlightSolo/beta/" # "What is the s3 file path within the bucket to upload to?"


while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -p|--parameter) # -p var_name=value   '-p, --parameter "PARAMETERNAME=PARAMETER"   pass a parameter to the program'
      in="$2"
      var=${in%=*}
      val=${in#*=}
      declare "${var}"="$val"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo -e "${RED}Unknown option $1 ${NC}"
      echo "Try '--help' for more information."
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done



#aws s3 cp "$download_path$aws_image_name" "s3://${bucket_name}/${s3_image_path}"

echo "uploaded raw image to bucket"
# wait until it has finished uploading 



# Create trust role

cat <<\EOF > trust-policy.json
{
"Version": "2022-11-03",
"Statement": [
  {
     "Effect": "Allow",
     "Principal": { "Service": "vmie.amazonaws.com" },
     "Action": "sts:AssumeRole",
     "Condition": {
        "StringEquals":{
           "sts:Externalid": "vmimport"
        }
     }
  }
]
}
EOF

aws iam create-role --role-name vmimport --assume-role-policy-document "file://trust-policy.json" 
# An error occurred (EntityAlreadyExists) when calling the CreateRole operation: Role with name vmimport already exists.
echo "created trust role?"


# make role policy

# make a role policy
cat <<EOF > role-policy.json
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetBucketAcl"
        ],
        "Resource": [
            "arn:aws:s3:::${bucket_name}",
            "arn:aws:s3:::${bucket_name}/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:ModifySnapshotAttribute",
            "ec2:CopySnapshot",
            "ec2:RegisterImage",
            "ec2:Describe*"
        ],
        "Resource": "*"
    }
]
}
EOF

aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://role-policy.json"
echo "made role policy?"

cat <<EOF > containers.json
{
"Description": "$aws_image_name",
"Format": "raw",
"UserBucket": {
    "S3Bucket": "$bucket_name",
    "S3Key": "$s3_image_path$aws_image_name"
}
}
EOF

cmdout=$(aws ec2 import-snapshot --description "auto-upload of $aws_image_name" --disk-container "file://containers.json")
echo "imported snapshot?"
echo "$cmdout"


import_snapname="$(echo $cmdout | grep -oe 'import-snap-[0-9a-zA-Z]*')"

echo "import_snapname $import_snapname"

aws ec2 wait snapshot-imported --import-task-ids "$import_snapname"
echo "snapshot imported"

cmdout=$(aws ec2 describe-import-snapshot-tasks --import-task-ids "$import_snapname")

echo "described snapshot:"
echo "$cmdout"

snapname="$(echo $cmdout | grep -oe '\ssnap-[0-9a-zA-Z]*' | xargs)"


aws ec2 wait snapshot-completed --snapshot-ids "${snapname}"

echo "snapshot completed"


echo "Key=\"Name\",Value=\"$final_image_name\""

aws ec2 create-tags \
    --resources "$snapname" \
    --tags "Key=\"Name\",Value=\"$final_image_name\"" # rename the snapshot



aws ec2 register-image --name "$final_image_name" --region=eu-west-2 --description "$final_image_name" --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10, \"SnapshotId\":\"$snapname\"}}]" --root-device-name "/dev/sda1" --architecture x86_64 --ena-support


