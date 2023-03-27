#must use terraform versions <= 1.3.0 since 'allow missing config' was not implemented in newer version (yet..)
#function used to import AWS subnets by subnet id and move them to a module if -modulelocation parameter is selected.
#terraform code must be already in place within module prior to importing (using this code.) 
#if terraform code is NOT already part of the module and the subnet your importing is new then run the 'terraform show <importedsubnetlocation(modulelocation)> 
#this function autogenerates the .tfvars file for multiple env variables use case.
function import-subnet {
    param(
        $env,
        $region,               
        $subnetid, #subnet id we are importing
        $tflocation, #where terraform is saving the subnet i.e aws_subnet.<this>
        $varfile, #your variable file for deploys (.tfvars)
        $modulelocation        #is this going to a module? if so we need to move from $tflocation into the actual $modulelocation 
    )

    $fromlocation = "aws_subnet.$tflocation"

    $erroractionpreference = 'Stop'

    if (($null -eq $varfile) -or ($varfile.length -le 4) -and ($modulelocation.length -ge 5)) {

        & terraform import --allow-missing-config --var "region=$region" $fromlocation $subnetid

        move-tfresource -tolocation $modulelocation -fromlocation $fromlocation
    }

    elseif (($null -ne $varfile) -and ($varfile.length -ge 5) -and ($modulelocation.length -ge 5)) {
        try { 
            planapply -env $env && 
            & terraform import --var-file=$varfile --allow-missing-config --var "region=$region" $fromlocation $subnetid
        }
        catch {
            & terraform import --var-file=$varfile --allow-missing-config --var "region=$region" $fromlocation $subnetid
        } 
        move-tfresource -tolocation $modulelocation -fromlocation $fromlocation
    }
    else { 
        terraform import --var-file=$varfile --allow-missing-config --var "region=$region" $fromlocation $subnetid | Write-Progress 

    }


}

function move-tfresource {
    param(
        $tolocation, 
        $fromlocation
    )

    & terraform state mv $fromlocation $tolocation
} 
