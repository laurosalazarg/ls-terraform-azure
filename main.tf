# --------------------------------------------------------------------------------- #
# Terraform to create Infrastructure, create K8 cluster, and deploy the application #
# --------------------------------------------------------------------------------- #
# --------------------------------------------------------------------------------- #
# Created by:    Lauro Salazar                                                      #      
# Last Modified: 10/31/2021                                                         #
# --------------------------------------------------------------------------------- #
terraform {
    required_providers {
    azurerm = {
        source  = "hashicorp/azurerm"
        version = "=2.46.0"
    }
    }
    backend "azurerm" {
    resource_group_name  = "dv_aztf_slzrcloud_01"
    storage_account_name = "dv0aztf0slzrcloud001"
    container_name       = "dvterraformstate"
    key                  = "tf_state"
    }
    }
    provider "azurerm" {
    features {}
}
# --------------------------------------------------------
# - Pre-Req 
#---------------------------------------------------------
resource "azurerm_resource_group" "rg" {
    name     = "${var.az_prefix}rg"
    location = var.azurelocation
    tags = {
    terraform   = "${var.managed}"
    environment = "${var.level}"
    }
}

data "azuread_client_config" "current" {}

data "azuread_user" "current" {
    object_id   = data.azuread_client_config.current.object_id
}
resource "azuread_group" "ad_devops_gp" {
    display_name     = "DevOps"
    owners           = [data.azuread_client_config.current.object_id]
    security_enabled = true

    members = [
        data.azuread_user.current.object_id
    ]
}
data "azurerm_client_config" "current" {}
resource "azuread_application" "az_application" {
    display_name = "DevOps"
    owners       = [data.azuread_client_config.current.object_id]
}
resource "azuread_service_principal" "az_servicePrincipal" {
    application_id               = azuread_application.az_application.application_id
    app_role_assignment_required = false
    owners                       = [data.azuread_client_config.current.object_id]
}
resource "azuread_service_principal_certificate" "az_sp_cert" {
    service_principal_id = azuread_service_principal.az_servicePrincipal.id
    type                 = "AsymmetricX509Cert"
    value                = file("../certificates/service-principal.crt")
    end_date             = "2022-05-01T01:02:03Z"
}
resource "azuread_service_principal_password" "az_sp_pwd" {
    service_principal_id = azuread_service_principal.az_servicePrincipal.object_id
}
resource "azuread_application_certificate" "az_app_cert" {
    application_object_id = azuread_application.az_application.id
    type                 = "AsymmetricX509Cert"
    value                = file("../certificates/service-principal.crt")
    end_date             = "2022-05-01T01:02:03Z"
}
resource "azuread_application_password" "az_app_pwd" {
    application_object_id = azuread_application.az_application.object_id
}

resource "azurerm_proximity_placement_group" "pg" {
    name                = "${var.az_prefix}pg"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
    terraform   = "${var.managed}"
    environment = "${var.level}"
    }
}



# --------------------------------------------------------
# - SSH keys 
#---------------------------------------------------------

data "local_file" "public_key" {
    filename = var.public_ssh_key
}
data "local_file" "private_key" {
    filename = var.private_ssh_key
}

# --------------------------------------------------------
# - Azure Vault
#---------------------------------------------------------
resource "random_uuid" "randomuuid" {}

resource "azurerm_key_vault" "vault" {
    name                        = "dv-aztf-slzrcloud-vault"
    location                    = azurerm_resource_group.rg.location
    resource_group_name         = azurerm_resource_group.rg.name
    enabled_for_disk_encryption = true
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false

    sku_name = "standard"

    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = data.azurerm_client_config.current.object_id

        key_permissions = [
            "backup",
            "create",
            "decrypt",
            "delete",
            "encrypt",
            "get",
            "import",
            "list",
            "purge",
            "recover",
            "restore",
            "sign",
            "unwrapKey",
            "update",
            "verify",
            "wrapKey",
        ]

        secret_permissions = [
            "backup",
            "delete",
            "get",
            "list",
            "purge",
            "recover",
            "restore",
            "set",
        ]

        storage_permissions = [
            "backup",
            "delete",
            "get",
            "list",
            "purge",
            "recover",
            "restore",
            "set",
            "setsas",
            "update",
        ]
        certificate_permissions = [
            "create",
            "delete",
            "deleteissuers",
            "get",
            "getissuers",
            "import",
            "list",
            "listissuers",
            "managecontacts",
            "manageissuers",
            "setissuers",
            "update",
            "recover",
            "backup",
            "restore",
            "purge",
        ]

    }

    depends_on = [ azurerm_resource_group.rg]
}
resource "azurerm_key_vault_secret" "vault_key" {
    name         = "${random_uuid.randomuuid.result}"
    key_vault_id = azurerm_key_vault.vault.id 
    value = data.local_file.public_key.content
    depends_on = [azurerm_key_vault.vault, azurerm_resource_group.rg]
} 
resource "azurerm_key_vault_secret" "vault_secret" {
    name         = "${random_uuid.randomuuid.result}"
    value        = "szechuan"
    key_vault_id = azurerm_key_vault.vault.id

    depends_on = [azurerm_key_vault.vault]
}

# --------------------------------------------------------
# - Container Registry
#---------------------------------------------------------
resource "azurerm_container_registry" "registry" {
    name                = "${var.prefix}registry"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    admin_enabled       = true
    depends_on = [azurerm_resource_group.rg]
}
# --------------------------------------------------------
# - Networks
#---------------------------------------------------------
data "azurerm_resource_group" "vnet" {
    name = azurerm_resource_group.rg.name

    depends_on = [azurerm_resource_group.rg]
}
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.az_prefix}vnet"
    location            = data.azurerm_resource_group.vnet.location
    resource_group_name = data.azurerm_resource_group.vnet.name
    address_space       =  "${var.address_space}"
    tags = {
        terraform   = "${var.managed}"
        environment = "${var.level}"
    } 
    depends_on = [azurerm_resource_group.rg]
}
resource "azurerm_network_security_group" "internal_nsg" {
    name                = "${var.az_prefix}internal_nsg"
    location            = data.azurerm_resource_group.vnet.location
    resource_group_name = data.azurerm_resource_group.vnet.name

    security_rule {
        name                       = "allow_all"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "204.60.15.0/32"
        destination_address_prefix = "*"
    }

    tags = {
        terraform   = "${var.managed}"
        environment = "${var.level}"
    }
    depends_on = [azurerm_resource_group.rg, azurerm_virtual_network.vnet]
}
resource "azurerm_network_security_group" "dmz_nsg" {
    name                = "${var.az_prefix}dmz_nsg"
    location            = data.azurerm_resource_group.vnet.location
    resource_group_name = data.azurerm_resource_group.vnet.name

    tags = {
        terraform   = "${var.managed}"
        environment = "${var.level}"
    }
    depends_on = [azurerm_resource_group.rg, azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "workers" {
    name                 = "${var.az_prefix}subnet_workers"
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.vnet.name
    address_prefixes     = "${var.subnet_workers}"
    depends_on           = [azurerm_virtual_network.vnet]
}
resource "azurerm_subnet" "vip" {
    name                 = "${var.az_prefix}subnet_vip"
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.vnet.name
    address_prefixes     = "${var.subnet_vip}"
    depends_on           = [azurerm_virtual_network.vnet]
}
resource "azurerm_subnet" "appgw" {
    name                 = "${var.az_prefix}subnet_appgw"
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.vnet.name
    address_prefixes     = "${var.subnet_appgw}"
    depends_on           = [azurerm_virtual_network.vnet]
}
resource "azurerm_subnet" "lb" {
    name                 = "${var.az_prefix}subnet_lb"
    virtual_network_name = azurerm_virtual_network.vnet.name
    resource_group_name  = data.azurerm_resource_group.vnet.name
    address_prefixes     = "${var.subnet_lb}"
    depends_on           = [azurerm_virtual_network.vnet]
}
# --------------------------------------------------------
# - Kubernetes
#---------------------------------------------------------
resource "azurerm_kubernetes_cluster" "k8" {
    name                = format("%s-%s", "K8-cluster", var.prefix_k8s)
    location            = data.azurerm_resource_group.vnet.location
    resource_group_name = data.azurerm_resource_group.vnet.name
    dns_prefix          = "${var.prefix}-k8s"
    kubernetes_version  = "1.22.2"
    api_server_authorized_ip_ranges = var.auth_ip


    default_node_pool  {
        name           = "workload"
        node_count     = 1
        min_count      = 1
        max_count      = 2
        vm_size        = "Standard_DS2_v2"
        vnet_subnet_id = azurerm_subnet.workers.id
        os_disk_size_gb = 30
        type = "VirtualMachineScaleSets"
        enable_auto_scaling = "true"
        max_pods = 30
    }
    linux_profile {
        admin_username = "devops"
        ssh_key {
            key_data = file(var.public_ssh_key)
        }
    }
    
    
    network_profile {
        network_plugin = "azure"
        network_policy = "azure" 
    }

    identity {
        type = "SystemAssigned"
    }

    addon_profile {
            
        aci_connector_linux {
            enabled = false
        }

        azure_policy {
            enabled = false
        }

        http_application_routing {
            enabled = false
        }

        oms_agent {
            enabled = false
        }
    }

    depends_on = [azuread_service_principal.az_servicePrincipal,azuread_service_principal_certificate.az_sp_cert,azuread_service_principal_password.az_sp_pwd,azurerm_key_vault_secret.vault_key,azurerm_resource_group.rg,azurerm_container_registry.registry, azurerm_network_security_group.internal_nsg, azurerm_network_security_group.dmz_nsg,azurerm_subnet.workers, azurerm_subnet.vip, azurerm_subnet.appgw, azurerm_subnet.lb]
}
