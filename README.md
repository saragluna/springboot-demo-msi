# SpringBoot-Demo-MSI

**[Table of Contents](http://tableofcontent.eu)**
- [Prerequisites](#prerequisites)
- [Run without MSI](#run-without-msi)
  - [Set up Service Principal and Key Vault](#set-up-service-principal-and-key-vault)
  - [Run Spring Boot application](#run-spring-boot-application)
- [Run with MSI in container](#run-with-msi-in-container)
  - [Set up App Service, MSI and Container Registry](#set-up-app-service-msi-and-container-registry)
  - [Run App Service](#run-app-service)
- [Run JAR application with MSI](#run-jar-application-with-msi)
  - [Set up App Service, MSI and deploy](#set-up-app-service-msi-and-deploy)
  - [Run App Service](#run-app-service)  
- [References](#references)    



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

   > ```json
   > {
   >     "appId": "xxx-sp-app-id-xxx",
   >     "displayName": "demo-sp",
   >     "name": "http://demo",
   >     "password": "xxx-password-xxx",
   >     "tenant": "xxx-tenant-xxx"
   > }
   > ```

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
    
3. Create App Service
   ```shell
   $ az webapp create --resource-group demo-rg \
       --plan demo-plan \
       --name demo-app \ 
       --deployment-container-image-name demoacr.azurecr.io/demo:test
   ```
   
4. Assign identity to App Service
   ```shell
   $ az webapp identity assign --name demo-app \
   		--resource-group demo-rg
   ```
   
5. Grant permission to MSI

   ```shell
   $ az keyvault set-policy --name demo-keyvault \
       --object-id your-managed-identity-objectId \
       --secret-permissions get list
   ```

### Run App Service

1. In application.properties set  

    ```properties
    # Specify if Key Vault should be used to retrieve secrets.
    azure.keyvault.enabled=true
    
    # Specify the URI of your Key Vault (e.g.: https://name.vault.azure.net/).
    azure.keyvault.uri=https://demo-keyvault.vault.azure.net/
    ```

    **Or** you perfer to set via Application Settings

    ```shell
    az webapp config appsettings set \
        --name demo-app \
        --resource-group demo-rg \
        --settings \
            "AZURE_KEYVAULT_URI=https://demo-keyvault.vault.azure.net/"    
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

5. Enable App Service logs and Stream log

   ```shell
   $ az webapp log tail --name demo-app --resource-group demo-rg
   ```




## Run JAR application with MSI

### Set up App Service, MSI and deploy

refer to [this](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity)

1. Create App Service

2. Assign identity to App Service

   ```shell
   $ az webapp identity assign --name demo-app \
   		--resource-group demo-rg
   ```

3. Grant permission to MSI

   ```shell
   $ az keyvault set-policy --name demo-keyvault \
       --object-id your-managed-identity-objectId \
       --secret-permissions get list
   ```

4. Deploy executable JAR file to App Service

   > **Attention**
   >
   > If you're using FTP/S,  the executable JAR must be named as `app.jar`. 

### Run App Service

1. In application.properties set  

   ```properties
   # Specify if Key Vault should be used to retrieve secrets.
   azure.keyvault.enabled=true
   
   # Specify the URI of your Key Vault (e.g.: https://name.vault.azure.net/).
   azure.keyvault.uri=https://demo-keyvault.vault.azure.net/
   ```

   **Or** you perfer to set via Application Settings

   ```shell
   az webapp config appsettings set \
       --name demo-app \
       --resource-group demo-rg \
       --settings \
           "AZURE_KEYVAULT_URI=https://demo-keyvault.vault.azure.net/"
   ```

3. Restart App Service

4. Enable App Service logs and Stream log

   ```shell
   $ az webapp log tail --name demo-app --resource-group demo-rg
   ```
   
4. Check this URL in browser

   ```text
   https://demo-app.azurewebsites.net/get
   ```

   

## References

[Run a custom Linux container in Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-docker-go)

[How to use managed identities for App Service and Azure Functions](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity)
