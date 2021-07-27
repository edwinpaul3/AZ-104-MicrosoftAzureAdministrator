
# https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator/blob/master/Instructions/Labs/LAB_06-Implement_Network_Traffic_Management.md
# Establish initial connection and choose subscription
$ROOTdir = "C:\Edwin\SCRIPTSREPO\AZURE_LAB_104\AZ-104-MicrosoftAzureAdministrator\Allfiles\Labs\06"

#Connect-Azaccount

Connect-AzAccount -TenantId 580e5d00-6b0a-4041-970e-2ddb226547ec
$Context = Get-azsubscription -SubscriptionId b28fc060-d738-4e8e-a217-e57375b71841
Set-AzContext $Context

# Get locations

(Get-AzLocation).Location


# Create resoure group

$location = 'centralindia'
$rgName = 'az104-06-rg1'
New-AzResourceGroup -Name $rgName -Location $location


# run the following to create the three virtual networks and four Azure VMs into them by using the template and parameter files you uploaded:

New-AzResourceGroupDeployment `
   -ResourceGroupName $rgName `
   -TemplateFile $ROOTdir/az104-06-vms-loop-template.json `
   -TemplateParameterFile $ROOTdir/az104-06-vms-loop-parameters.json

# Resources are created

# Checking Which VM is mapped to which vnet

$vms = Get-AzVM -ResourceGroupName $rgName
foreach ($vm in $vms) {


    $nic = get-aznetworkinterface -resourceid $vm.NetworkProfile[0].NetworkInterfaces[0].Id
    $subnetresourceid = $nic.IpConfigurations[0].Subnet.id
    $split = $subnetresourceid.split("/")
    $vnetresourceid = [string]::Join("/", $split[0..($split.Count - 3)])
    Write-host "$($Vm.name) - $($vnetresourceid.split("/")[-1])"
}


# VM             VNET
# ---            ---------------
# az104-06-vm0 - az104-06-vnet01
# az104-06-vm1 - az104-06-vnet01
# az104-06-vm2 - az104-06-vnet2
# az104-06-vm3 - az104-06-vnet3


#    From the Cloud Shell pane, run the following to install the Network Watcher extension on the Azure VMs deployed in the previous step:


   $rgName = 'az104-06-rg1'
   $location = (Get-AzResourceGroup -ResourceGroupName $rgName).location
   $vmNames = (Get-AzVM -ResourceGroupName $rgName).Name



   foreach ($vmName in $vmNames) {
     Set-AzVMExtension `
     -ResourceGroupName $rgName `
     -Location $location `
     -VMName $vmName `
     -Name 'networkWatcherAgent' `
     -Publisher 'Microsoft.Azure.NetworkWatcher' `
     -Type 'NetworkWatcherAgentWindows' `
     -TypeHandlerVersion '1.4'
   }


   # Go to a VM > extensions > you should be able to see networkWatcherAgent

   # ensures that the IP address ranges of the three virtual networks do not overlap.


   Get-azvirtualnetwork | Select-Object Id, @{N='VnetName' ; E={$_.name}}, @{N='AddressSpace' ; E={$_.addressspace.AddressPrefixes}}

#    Id                                                                                                                                          VnetName        AddressSpace
#    --                                                                                                                                          --------        ------------
#    /subscriptions/b28fc060-d738-4e8e-a217-e57375b71841/resourceGroups/az104-06-rg1/providers/Microsoft.Network/virtualNetworks/az104-06-vnet01 az104-06-vnet01 10.60.0.0/22
#    /subscriptions/b28fc060-d738-4e8e-a217-e57375b71841/resourceGroups/az104-06-rg1/providers/Microsoft.Network/virtualNetworks/az104-06-vnet2  az104-06-vnet2  10.62.0.0/22
#    /subscriptions/b28fc060-d738-4e8e-a217-e57375b71841/resourceGroups/az104-06-rg1/providers/Microsoft.Network/virtualNetworks/az104-06-vnet3  az104-06-vnet3  10.63.0.0/22



                    #
                    #                     > VNET02
                    #           - - - -
                    #        <
                    # VNET01
                    #        <
                    #          - - - - -
                    #                    > VNET03