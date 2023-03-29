function import-iam_roles { 

  #set default region, if not set this uses us-west-2  < import-iam_roles -region us-east-1  >  (example usage)
  param (
    $region = "us-east-1" 
  )

  # create necessary folder and files for import
  $r = 'aws_iam_role'          #resource we are using 
  $roles = (Get-IAMRoleList).RoleName

  #provider info
  $provider_for_main = @"
// Provider configuration
terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = ">= 3.0"
   }
 }
}
 provider "aws" {
 region = "$region"
 }
"@

  #creates necessary files and folders for importing.
  mkdir ".\$r"
  New-Item -Path ".\$r\imported_$r.tf" 
  New-Item -Path ".\imported_$r.tf" 
  New-Item -Path ".\main.tf"  
  New-Item -Path ".\terraform.tfstate" 
  New-Item -Path ".\$r\variables.tfvars"


  $providerinfo = $provider_for_main | Out-File -FilePath ".\main.tf" -Append 
  $providerinfo && Invoke-Command { terraform init }   #init is needed prior to import

  #foreach role found do this
  foreach ($role in $roles) {
    $Roleid = (Get-IAMRole -RoleName $role).RoleId 
    
    $resourceconfig = @"
resource "$r" "$Roleid" { 
} 
"@
    $resourcecopy = $resourceconfig | Out-File -Path ".\imported_$r.tf" -Append
    $invokethis = Invoke-Command { terraform import aws_iam_role.$Roleid $role } -Verbose
    $copystatefile = Invoke-Command { terraform state show -no-color aws_iam_role.$Roleid } | Out-File -Path ".\$r\imported_$r.tf" -Append 
    $resourcecopy && $invokethis && $copystatefile

  }
  $name = (Get-Content -Path ".\$r\imported_$r.tf") | Select-String -SimpleMatch "="
  $maketfvars = $name | Set-Content -Path ".\$r\variables.tfvars"
  $maketfvars && Remove-Item -Path ".\imported_$r.tf" -Force
} 
