# Resource group
resource "azurerm_resource_group" "resource_group" {
    name = "{var.resource_group}_${var.environment}" 
    location = var.location 
}

# creating the cluster
resource "azurerm_kubernetes_cluster" "terraform-k8s" {
    name = "{var.cluster_name}_${var.environment}"
    location = azurerm_resource_group.resource_group.location
    resource_group_name = azurerm_resource_group.resource_group.name
    dns_prefix = var.dns.dns_prefix

    linux_profile {
        admin_username = "ubuntu"

        ssh_key{
            key_data = file (var.ssh_public_key)
        }
    }

    default_node_pool {
        name = "agentpool"
        node_count = var.node_count
        vm_size = "Standard_DS1_v2"
    }

    service_principle {
        client_id = var.client_id
        client_secret = var.client_secret
    }

    tags = {
        Environment = var.environment
    }

    terraform{
        backend "azurerm" {
            # storage_account_name = "<<storage_account_name>>" #OVERRIDE in TERRAFROM init
            # access_key="<<storage_account_key>>" #OVERRIDE in TERRAFROM init
            # key="<<env_name.k8s.tfstate>>" #OVERRIDE in TERRAFROM init
            # container_name="<<storage_account_container_name>>" #OVERRIDE in TERRAFROM init
        }
    }

}

