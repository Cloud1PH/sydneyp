# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "Sydney8hrsVMUbnt" {
    name     = "Sydney8hrsVMUbnt"
    location = "eastus2"

    tags = {
        environment = "Sydney Terraform LinuxVM Ubnt"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "Sydney8hrsVMUbntnetwork" {
    name                = "Sydney8hrsVMUbntVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Sydney8hrsVMUbnt.name

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Create subnet
resource "azurerm_subnet" "Sydney8hrsVMUbntsubnet" {
    name                 = "Sydney8hrsVMUbntSubnet"
    resource_group_name  = azurerm_resource_group.Sydney8hrsVMUbnt.name
    virtual_network_name = azurerm_virtual_network.Sydney8hrsVMUbntnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "Sydney8hrsVMUbntpublicip" {
    name                         = "Sydney8hrsVMUbntPublicIP"
    location                     = "eastus2"
    resource_group_name          = azurerm_resource_group.Sydney8hrsVMUbnt.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Sydney8hrsVMUbntnsg" {
    name                = "Sydney8hrsVMUbntNetworkSecurityGroup"
    location            = "eastus2"
    resource_group_name = azurerm_resource_group.Sydney8hrsVMUbnt.name

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
		

    }

    security_rule {
        name                       = "DSA1"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
	
	
   security_rule {
        name                       = "SIEM1"
        priority                   = 103
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "514"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
		
   security_rule {
        name                       = "DSA_Onprem1"
        priority                   = 105
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "4118"
        source_address_prefix      = "*"
        destination_address_prefix = "*"		

    }
	

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Create network interface
resource "azurerm_network_interface" "Sydney8hrsVMUbntnic" {
    name                      = "Sydney8hrsVMUbntNIC"
    location                  = "eastus2"
    resource_group_name       = azurerm_resource_group.Sydney8hrsVMUbnt.name

    ip_configuration {
        name                          = "Sydney8hrsVMUbntNicConfiguration"
        subnet_id                     = azurerm_subnet.Sydney8hrsVMUbntsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.Sydney8hrsVMUbntpublicip.id
    }

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Sydney8hrsVMUbntnsg" {
    network_interface_id      = azurerm_network_interface.Sydney8hrsVMUbntnic.id
    network_security_group_id = azurerm_network_security_group.Sydney8hrsVMUbntnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.Sydney8hrsVMUbnt.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Sydney8hrsVMUbntstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.Sydney8hrsVMUbnt.name
    location                    = "eastus2"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Create (and display) an SSH key  (Uncomment this if you wish to use SSH keys)
#resource "tls_private_key" "example_ssh" {
#  algorithm = "RSA"
#  rsa_bits = 4096
#}
#output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "Sydney8hrsVMUbntvm" {
    name                  = "Sydney8hrsVMUbntvm"
    location              = "eastus2"
    resource_group_name   = azurerm_resource_group.Sydney8hrsVMUbnt.name
    network_interface_ids = [azurerm_network_interface.Sydney8hrsVMUbntnic.id]
    size                  = "Standard_B1ms"

    os_disk {
        name              = "Sydney8hrsVMOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "Sydney8hrsVMUbntvm"
    admin_username = "cloud1ph"
    disable_password_authentication = false
        admin_password = "Ch4ngeMe!"

#    admin_ssh_key { (Uncomment this if you wish to use SSH keys)
#        username       = "cloud1ph"
#       public_key     = tls_private_key.example_ssh.public_key_openssh
#    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.Sydney8hrsVMUbntstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Sydney Terraform LinuxVM"
    }
}

# Uncomment this section if you wish to install DS agent and add it on TMCS cloud one console

resource "azurerm_virtual_machine_extension" "Sydney8hrsVMUbntvm" {
  name                 = "Sydney8hrsVMUbntvm"
  virtual_machine_id   = azurerm_linux_virtual_machine.Sydney8hrsVMUbntvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
	"fileUris": ["https://raw.githubusercontent.com/Cloud1PH/Public-Raw-Scripts/AgentDeploymentScript/linux.sh"],
        "commandToExecute": "sudo ./linux.sh",
	"skipDos2Unix": true
    }
SETTINGS


  tags = {
    environment = "Sydney Terraform LinuxVM"
  }
}
