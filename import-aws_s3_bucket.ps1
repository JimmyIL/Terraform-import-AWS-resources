#currently this is region specific unless the bucket has CORS enabled, terraform will give an error otherwise
#customize the .tfvars file to your liking.
#create necessary folder and files for import
function import-s3 { 

$backendfilename = "dev_tfstate.config"
$region = "us-east-1" 
$env:AWS_DEFAULT_REGION = $region

New-Item -Path $pwd -ItemType Directory -Name "aws_s3_bucket" &&

New-Item -Path ".\aws_s3_bucket\imported_s3buckets.tf" -ItemType File

Set-DefaultAWSRegion -Region $region
Invoke-Command { terraform init --backend-config=$backendfilename }

$global:bucketnames = ((Get-S3Bucket -Region $region).BucketName) | Select -First 4

foreach ($name in $bucketnames) { 

    #$resourcetags = (Get-S3Bucket -BucketName $name).BucketName

    #not used for this function #if ([string]::IsNullOrWhitespace($resourcetags)) { $instancename = $number } 
    $invoke = Invoke-Command { terraform import --allow-missing-config aws_s3_bucket.$name $name } 
    $copystatefile = Invoke-Command { terraform state show -no-color aws_s3_bucket.$name } | Add-Content -Path ".\aws_s3_bucket\imported_s3buckets.tf" 

    #runs in this order exactly if all completes as needed
    $invoke && $copystatefile
 }
} 
