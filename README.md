# SpringBoot-Demo-MSI

[TOC]

## Prerequisites

1. Login and set subscription

   ```shell
   $ az login
   $ az account set -s “mysubscription”
   ```

2. Create resource group

   ```shell
   $ az group create --name demo-rg --location westus
   ```

   

## Run without MSI

### Set up Service Principal and Key Vault

1. Create Service Principal

   ```shell
   $ az ad sp create-for-rbac --name "demo-sp"
   ```

   > {
   >     "appId": "xxx-sp-app-id-xxx",
   >     "displayName": "demo-sp",
   >     "name": "http://demo",
   >     "password": "xxx-password-xxx",
   >     "tenant": "xxx-tenant-xxx"
   > }

2. Create Key Vault

   ```shell
   $ az keyvault create --name demo-keyvault --resource-group demo-rg
   ```

3. Grant permission to demo-sp

   ```shell
   $ az keyvault set-policy --name demo-keyvault \
       --secret-permission set get list delete \
       --spn "xxx-sp-app-id-xxx"
   ```

   

4. Add secret to Key Vault

   ```shell
   $ az keyvault secret set --vault-name demo-keyvault \
       --name your-key \
       --value your-value
   ```

   


### Run Spring Boot application

1. In application.properties set
    ```properties
    # Specify if Key Vault should be used to retrieve secrets.
    azure.keyvault.enabled=true
    
    # Specify the URI of your Key Vault (e.g.: https://name.vault.azure.net/).
    azure.keyvault.uri=https://demo-keyvault.vault.azure.net/
    
    # Specify the Service Principal Client ID with access to your Key Vault.
    azure.keyvault.client-id=xxx-sp-app-id-xxx
    
    # Specify the Service Principal Client Secret.
    azure.keyvault.client-key=xxx-password-xxx
    ```
2. Run application
    ```shell script
    $ mvn clean package
    $ mvn spring-boot:run
    ```



## Run with MSI in container

### Set up App Service, MSI and Container Registry

1. Create Azure Container Registry (*for App Service to pull image from*)

    ```shell
    $ az acr create --name demoacr \
        --resource-group demo-rg \
        --sku Basic \
        --admin-enabled true \
        --location westus
    ```
    
2. Create App Service plan

    ```shell
    $ az appservice plan create --name demo-plan \
        --resource-group demo-rg \
        --sku B1 \
        --is-linux
    ```
    
7. Create App Service
   ```shell
   $ az webapp create --resource-group demo-rg \
       --plan demo-plan \
       --name demo-app \ 
       --deployment-container-image-name demoacr.azurecr.io/demo:test
   ```
   
8. Assign identity to App Service
   ```shell
   $ az webapp identity assign --name demo-app \
   		--resource-group demo-rg
```
   
9. Grant permission to MSI
   ```shell
   $ az keyvault set-policy --name demo-keyvault \
       --object-id your-managed-identity-objectId \
    --secret-permissions get
   ```

### Run App Service

1.  In application.properties set

   ```properties
   # Specify if Key Vault should be used to retrieve secrets.
   azure.keyvault.enabled=true
   
   # Specify the URI of your Key Vault (e.g.: https://name.vault.azure.net/).
   azure.keyvault.uri=https://demo-keyvault.vault.azure.net/
   ```

2. Build docker image and push

   ```shell
   $ mvn clean package
   $ docker build -t demoacr.azurecr.io/demo:test .  
   $ docker push demoacr.azurecr.io/demo:test
   ```

3. Add config to App Service

   ```shell
   az webapp config appsettings set --resource-group demo-rg \
       --name demo-app \
       --settings WEBSITES_PORT=8080
   ```

4. Restart App Service

5. Log stream

   ```shell
   $ az webapp log tail --name demo-app --resource-group demo-rg
   ```

   

## References

[https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-intro](https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-intro)