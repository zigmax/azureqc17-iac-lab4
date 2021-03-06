resource "azurerm_resource_group" "test" {
  name     = "acctestrg"
  location = "West US 2"
}
resource "azurerm_virtual_network" "test" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}
resource "azurerm_subnet" "test" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}
resource "azurerm_public_ip" "test" {
  name                         = "pubip"
  location                     = "${azurerm_resource_group.test.location}"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "test"
  }
}
resource "azurerm_network_interface" "test" {
  name                = "acctni"
  location            = "West US 2"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "static"
    private_ip_address = "10.0.2.5"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}
resource "azurerm_managed_disk" "test" {
  name                 = "datadisk_existing"
  location             = "West US 2"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}
resource "azurerm_virtual_machine" "test" {
  name                  = "acctvm"
  location              = "West US 2"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_DS1_v2"

storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
# Optional data disks
  storage_data_disk {
    name              = "datadisk_new"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.test.name}"
    managed_disk_id = "${azurerm_managed_disk.test.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.test.disk_size_gb}"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "qcazureadmin"
    admin_password = "QuebecMeetupAzure!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "demomeetupazure"
  }
}
data "azurerm_public_ip" "test" {
  name                = "${azurerm_public_ip.test.name}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  depends_on          = ["azurerm_virtual_machine.test"]
}

output "ip_address" {
  value = "${data.azurerm_public_ip.test.ip_address}"
}
