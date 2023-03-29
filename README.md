# Terraform-import-AWS-resources
### Powershell/pwsh functions that import all the specified resources in AWS per region

## Prequisits 
pwsh 7/powershell 7+
Must use Terraform versions <1.3.0 (or was it <= 1.2.8?)
any terraform version higher than those ^ do not have "--allow-missing-config" (sadly was removed by hashicorp.)

## What does this do? How can I use it? 
-each .ps1 file is a functions that imports all of the specified resources in AWS by region.

-to run, simply create a folder and navigate to a fresh empty directory, open terraform and and run the .ps1 in powershell (linux/mac = pwsh)

## Problems/issues
-I encourage opening issues/Pull requests.  If something is not working I would like to know!
-If you do encounter an error or problem ensure you do not use your existing terraform state file, you should be able to just run this locally.
-You CAN absolutely unintentionally create duplicate resources under different names in terraform, so be sure to check all the resources are not already in your existing state file.

### TODO
-this is an ongoing project, if I have more time I would make an import file for every resource, but this is what I have so far ⏳
-Id like to make if for a list of specified regions not just a single region, you could probably do something like:
[import-aws_instance -region us-west-2 && import-aws_instance -region us-east-1 && import-aws_instance -region us-east-2]

