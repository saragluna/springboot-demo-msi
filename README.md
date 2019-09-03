# springboot-demo-msi

[TOC]

## Run without MSI

### Set up Service Principal and Key Vault

1. az login
2. az account set -s “mysubscription”
3. az group create --name demo-rg --location westus
4. az ad sp create-for-rbac --name "demo-sp"
        {
          "appId": "xxx-sp-app-id-xxx",
          "displayName": "demo-sp",
          "name": "http://demo",
          "password": "xxx-password-xxx",
          "tenant": "xxx-tenant-xxx"
        }
5. az keyvault create --name demo-keyvault --resource-group demo-rg
6. az keyvault set-policy --name demo-keyvault --secret-permission set get list delete --spn "xxx-sp-app-id-xxx"
7. az keyvault secret set --vault-name "demo-keyvault" --name "azure-cosmosdb-key" –value


### Start Spring Boot application

1. In application.properties set
    > 
        # Specify if Key Vault should be used to retrieve secrets.
        azure.keyvault.enabled=true
    
        # Specify the URI of your Key Vault (e.g.: https://name.vault.azure.net/).
        azure.keyvault.uri=https://demo-keyvault.vault.azure.net/
        
        # Specify the Service Principal Client ID with access to your Key Vault.
        azure.keyvault.client-id=xxx-sp-app-id-xxx
        
        # Specify the Service Principal Client Secret.
        azure.keyvault.client-key=xxx-password-xxx
2. Run application
    ```shell script
    $ mvn clean package
    $ mvn spring-boot:run
    ```



## Run with MSI

1. Create Container Registry

    ```shell
    az acr create --name demo-acr \
    	--resource-group demo-rg \
      --sku Basic \
      --admin-enabled true \
      --location westus
    ```
    
2. Create App Service plan

    ```shell
    az appservice plan create --name demo-app-service \
    	--resource-group demo-rg \
    	--sku B1 \
    	--is-linux
    ```
    
3. Create Application Insights

   ```shell
    az resource create --resource-group demo-rg \
    	--resource-type "Microsoft.Insights/components" \
    	--name demo_Insights \
    	--location "West US" \
    	--properties '{"Application_Type": "Node.JS", "Flow_Type": "Redfield", "Request_Source": "IbizaAIExtension"}'
   ```
   
4. Show instrumentation key
    ```shell
    az resource show -g "demo-rg" -n "demo_Insights" --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey
    # "700acbcd-018a-4865-8d29-248f91b5c9ff" // App Insights Key
   ```

5. Add secret to Key Vault
   ```shell
   az keyvault secret set --vault-name demo-keyvault \
   	--name "AppInsightsInstrumentationKey" \
   	--value "700acbcd-018a-4865-8d29-248f91b5c9ff"
   ```
   
6. Grant permissions (**not needed,** since MSI is being used)
   ```shell
   az keyvault set-policy --name demo-keyvault \ 
   	--secret-permissions get \
   	--spn xxx-your-sp-app-id-xxx
   ```
   
7. Create App Service
   ```shell
   az webapp create --resource-group demo-rg \
   	--plan demoheliumapp \
     --name demohelium \ 
     --deployment-container-image-name demoheliumacr.azurecr.io/helium:canary
   ```
    >                                                                                                                                                                        
        {
          "principalId": "e1a3f8a5-fa24-412a-8585-acb61bce1e5a",
          "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47",
       "type": "SystemAssigned",
          "userAssignedIdentities": null
        }
   
8. Assign identity 
   ```shell
   az webapp identity assign --name demohelium --resource-group demoheliumresources
   ```

9. Create Service Principal (**not needed**, since MSI is being used)
   ```shell 
   az ad sp list --display-name demohelium
   ```

10. Query Object Id of Service Principal  (**not needed**, since MSI is being used)
   ```shell
   az ad sp list --display-name demohelium \
   	--query "[:1].objectId" \
   	--out tsv // e1a3f8a5-fa24-412a-8585-acb61bce1e5a
   ```

11. Grant permission to MSI
    ```shell
    az keyvault set-policy --name demo-keyvault \
    	--object-id e1a3f8a5-fa24-412a-8585-acb61bce1e5a \
    	--secret-permissions get
    ```

12. Show key

    ```shell
    az keyvault secret show --vault-name demoheliumkeyvault --name azure-cosmosdb-key
    ```


export AzureServicesAuthConnectionString="RunAs=App;AppId=452af109-c8fb-4dc7-b79c-9f617a98d288;TenantId=72f988bf-86f1-41af-91ab-2d7cd011db47;AppKey=87a0251a-58ec-4c2c-99c7-b112308f4652"



Build

```shell
docker build -t xiadacr.azurecr.io/demo:test .  
docker push xiadacr.azurecr.io/demo:test
```





https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-intro