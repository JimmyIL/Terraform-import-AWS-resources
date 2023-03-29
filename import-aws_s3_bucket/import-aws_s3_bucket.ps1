#currently this is region specific unless the bucket has CORS enabled, terraform will give an error otherwise
function import-aws_s3_bucket { 
    param(
        $yourpath = $pwd , #path you want the imported s3 bucket folder to go to. *must have no loose terraform files like main.tf, or statefiles.
        $providerversion = "3.55" ,
        $region = "us-east-1" ,

        #resource type in terraform 'resource {}' reference we are importing. (i.e. aws_instance, aws_iam_user, aws_alb )
        $tfresourcetype = "aws_s3_bucket"
    )
  
    Set-Location -Path $yourpath &&
    New-Item -ItemType Directory -Path "$pwd\$tfresourcetype"   
    $provider_for_main = @"
  // Provider configuration
  terraform {
   required_providers {
     aws = {
       source  = "hashicorp/aws"
       version = "~> $providerversion"
     }
   }
  }
   
  provider "aws" {
   region = "$region"
  }
"@
  
    Set-Content -Path "$pwd\$tfresourcetype\provider.tf" -Value $provider_for_main -Force && 
    Set-Location -Path "$pwd\$tfresourcetype" && 
    Invoke-Command { terraform init }
   
    $bucketnames = ((Get-S3Bucket -Region $region).BucketName)  #| select -First 4 <--you can use this to test/select a few at a time instead of all at once

    foreach ($name in $bucketnames) { 
        $name = $name -split " ", ""
        $randomness = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | % { [char]$_ }) )
        $invoke = Invoke-Command { terraform import -allow-missing-config $tfresourcetype'.'$name'-'$randomness $name } 

        $thisthing = Invoke-Command { terraform show -no-color }  
        $thisthing | Add-Content -Path "$pwd\imported_$tfresourcetype.tf" 

        #runs in this order exactly if all completes as needed
        $invoke && $copystatefile
    }
} 
