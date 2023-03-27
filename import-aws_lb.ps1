
# Uses the AWS API to retrieve needed info to pipe into 'terraform import' command, copying any previously existing non tf managed resources specified to file
# This is mainly for new imports/customers, but for existing it can still skip over already managed TF ec2 instances and pulls only unmanaged to file/ tfstate.
# This .ps1 when ran gathers ALL the ec2 instances and existing attributes by tagname and imports to tfstate, where 'import' will create to 'imported_ec2.tf'
# check aws config to make sure the account is the proper one.

# requires powershell module AWSPowershell.NetCore
function import-aws_lb { 
  
    param( 
        #location to put all the resources/files in.
        $yourpath = "C:\Users\someguy\myfolderwithstuff" ,
      
        #aws provider version being used
        $providerversion = "3.55" ,
      
        #region of where resources are located.
        $region = "us-west-2" ,
      
        #resource type in terraform 'resource {}' reference we are importing. (i.e. aws_instance, aws_iam_user, aws_alb )
        $tfresourcetype = "aws_lb" , 
  
        #include elb listener yes or no
        $include_listener = "yes"
    ) 
  
    ######id:1 = replace with resource API retrieval matching TF import id needed (resource.nameuwant $ids(thisline))
    $id1 = (Get-ELB2LoadBalancer -Region $region).LoadBalancerArn | Select-Object -Unique
  
  
      
    if ([string]::IsNullOrWhitespace($id1)) { 
        Write-Host "No $tfresourcetype found in account and or region"
    } 
  
    else { 
        Set-Location -Path $yourpath
        $tfresourcetypefolder = "$pwd\$tfresourcetype"
        if (!(Test-Path -Path $tfresourcetypefolder )) {
            New-Item -ItemType directory -Path $tfresourcetypefolder
        }
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
  
        #foreach found do this
        foreach ($number in $id1) { 
            ######id:2 = replace with resource API retrieval matching specific tf name you want (resource.nameuwant(thisline;id:2) $ids(id:1)  
            $id2 = (Get-ELB2LoadBalancer -Region $region -LoadBalancerArn $number).LoadBalancerName
            ####### change id2 to specific value that is needed for terraform import i.e. $number in $tfresourcetype'.'$resourceid'-'$randomness $number ######
            $resourcetags = $id2                      
            $resourceid = $resourcetags -split "/n", ""  
            $randomness = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | % { [char]$_ }) )
            if ([string]::IsNullOrWhitespace($resourcetags)) { $resourceid = $number } 
            Invoke-Command { terraform import -allow-missing-config $tfresourcetype'.'$resourceid'-'$randomness $number } 
            if ($include_listener -eq "yes") { import-aws_lb_listener -aws_lb_arn $number -aws_lb_name $resourceid }
        } 
    
        $thisthing = Invoke-Command { terraform show -no-color }  
        $thisthing | Add-Content -Path "$pwd\imported_$tfresourcetype.tf" 
    } 
} 
  
function import-aws_lb_listener { 
    param( 
        $aws_lb_arn = "" , 
        $aws_lb_name = ""
    ) 
    $tfresourcetype = "aws_alb_listener"
    $ELB2listenerarn = (Get-ELB2Listener -LoadBalancerArn $aws_lb_arn ).ListenerArn 
      
    $resourceid = $ELB2listenerarn -split "/n", ""  
    $randomness = Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count 6 | % { [char]$_ }) )
    if ([string]::IsNullOrWhitespace($resourceid)) { break } 
    Invoke-Command { terraform import -allow-missing-config $tfresourcetype'.'$aws_lb_name'-'$randomness $resourceid } 
} 
