function import-aws_iam_role { 
  param( 
    #location to put all the resources/files in.
    $yourpath = "C:\Users\liljohn\folderdirwiththings" ,
    #aws provider version being used
    $providerversion = "3.55" ,
    #region of where resources are located.
    $region = "us-east-1" ,
    #resource type in terraform 'resource {}' reference we are importing. (i.e. aws_instance, aws_iam_user, aws_alb )
    $tfresourcetype = "aws_iam_role"
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
  
  $ids = (Get-IamRoleList -region $region).RoleName | Select-Object -Unique 
  
  #foreach found do this
  foreach ($number in $ids) { 
    $resourcetags = (Get-IamRole -Region $region -RoleName $number).RoleName 
    $resourceid = $resourcetags -split " ", ""  
    $randomness = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | % { [char]$_ }) )
    if ([string]::IsNullOrWhitespace($resourceid)) { $resourceid = $number } 
    Invoke-Command { terraform import -allow-missing-config $tfresourcetype'.'$resourceid'-'$randomness $number } 
  } 
  
  $thisthing = Invoke-Command { terraform show -no-color }  
  $thisthing | Add-Content -Path "$pwd\imported_$tfresourcetype.tf"
} 
