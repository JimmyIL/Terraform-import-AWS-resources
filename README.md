# Terraform-import-AWS-resources
### Powershell/pwsh functions that import all the specified resources in an AWS region into its own terraform statefile in it's own folder.

## Prequisits 
<br> MUST not have an existing terraform statefile in current directory. (It will just create a new statefile, just delete after the import and move resource folder .tf to your project's location.
<br>pwsh 7/powershell 7+
<br>Must use Terraform versions <1.3.0 (or was it <= 1.2.8?)
<br>any terraform version higher than those ^ do not have "--allow-missing-config" (sadly was removed by hashicorp.)

## What does this do? How can I use it? 
-each .ps1 file is a functions that imports all of the specified resources in AWS by region.
<br>
-to run, simply create a folder and navigate to a fresh empty directory, open terraform and and run the .ps1 in powershell (linux/mac = pwsh)
<br>
## Problems/issues
-I encourage opening issues/Pull requests.  If something is not working I would like to know!
<br>
-If you do encounter an error or problem ensure you do not use your existing terraform state file, you should be able to just run this locally.
<br>
-You CAN absolutely unintentionally create duplicate resources under different names in terraform, so be sure to check all the resources are not already in your existing state file.
<br>

### TODO
-this is an ongoing project, if I have more time I would make an import file for every resource, but this is what I have so far ⏳
<br>
-Id like to make if for a list of specified regions not just a single region, you could probably do something like:
<br>
[import-aws_instance -region us-west-2 && import-aws_instance -region us-east-1 && import-aws_instance -region us-east-2]

