
# Uses the AWS API to retrieve needed info to pipe into 'terraform import' command, copying any previously existing non tf managed resources specified to file
# This is mainly for new imports/customers, but for existing it can still skip over already managed TF ec2 instances and pulls only unmanaged to file/ tfstate.
# This .ps1 when ran gathers ALL the ec2 instances and existing attributes by tagname and imports to tfstate, where 'import' will create to 'imported_ec2.tf'
# check aws config to make sure the account is the proper one.

# requires powershell module AWSPowershell.NetCore

function import-aws_lambda_function { 
  param( 
    #location to put all the resources/files in.
    $yourpath = "C:\Users\somedude\thatfolderwithstuff" ,
    #aws provider version being used
    $providerversion = "3.55" ,
    #region of where resources are located.
    $region = "us-west-2" ,
    #resource type in terraform 'resource {}' reference we are importing. (i.e. aws_instance, aws_iam_user, aws_alb )
    $tfresourcetype = "aws_lambda_function"
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
    
  $ids = (Get-LMFunctionList -Region $region).FunctionName | Select-Object -Unique                                    ######replace with resource API retrieval matching TF import id needed (resource.nameuwant $ids(thisline))
    
  #foreach found do this
  foreach ($number in $ids) { 
    $resourcetags = (Get-LMFunction -FunctionName $number).Configuration.FunctionName                                              #### (resource.$nameuwant(thisline) ids)
    $resourceid = $resourcetags -split "/n", ""  
    $randomness = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | % { [char]$_ }) )
    if ([string]::IsNullOrWhitespace($resourcetags)) { $resourceid = $number } 
    Invoke-Command { terraform import -allow-missing-config $tfresourcetype'.'$resourceid'-'$randomness $number } 
  } 
    
  $thisthing = Invoke-Command { terraform show -no-color }  
  $thisthing | Add-Content -Path "$pwd\imported_$tfresourcetype.tf" 
} 
