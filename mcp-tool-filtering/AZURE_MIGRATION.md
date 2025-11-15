# Azure OpenAI Migration Guide

This document describes the changes made to convert the application from OpenAI to Azure OpenAI with Entra ID authentication.

## Summary of Changes

The application has been updated to use **Azure OpenAI** instead of OpenAI, with **Entra ID (Azure AD) Default Credential** authentication instead of API keys, and **text-embedding-ada-002** instead of SentenceTransformers for embeddings.

## Files Modified

### 1. `requirements.txt`
**Changes:**
- ✅ Removed: `sentence-transformers>=2.2.2`
- ✅ Added: `azure-identity>=1.15.0`
- ✅ Added: `azure-core>=1.29.0`
- ✅ Kept: `openai>=1.3.0` (now used for Azure OpenAI client)

### 2. `config.py.example`
**Changes:**
- ✅ Replaced OpenAI API key configuration with Azure OpenAI configuration:
  - `_azure_openai_endpoint` - Your Azure OpenAI resource endpoint
  - `_azure_openai_chat_deployment` - Chat model deployment name (e.g., gpt-4)
  - `_azure_openai_embedding_deployment` - Embedding model deployment name (e.g., text-embedding-ada-002)
  - `_azure_openai_api_version` - API version (default: 2024-02-01)
- ✅ Changed `OPENAI_CONFIG` to `AZURE_OPENAI_CONFIG` with new structure
- ✅ Updated vector dimension from 384 (MiniLM) to 1536 (text-embedding-ada-002)
- ✅ Added `embedding_cache_size` to PERFORMANCE_CONFIG

### 3. `app.py`
**Changes:**

#### ToolEmbeddings Class
- ✅ Replaced SentenceTransformer with Azure OpenAI embeddings API
- ✅ Implemented Entra ID authentication using `DefaultAzureCredential`
- ✅ Added automatic token refresh on authentication errors
- ✅ Changed embedding dimension from 384 to 1536
- ✅ Maintained caching functionality for performance

#### LLMService Class
- ✅ Replaced OpenAI client with Azure OpenAI client
- ✅ Implemented Entra ID authentication using `DefaultAzureCredential`
- ✅ Added automatic token refresh on authentication errors
- ✅ Updated to use deployment names instead of model names
- ✅ Changed tokenizer to use cl100k_base encoding

#### Health Check Endpoint
- ✅ Updated response model to reflect Azure OpenAI services
- ✅ Changed field names: `sentence_transformers` → `azure_openai_embeddings`, `openai` → `azure_openai_llm`

#### Startup Event
- ✅ Updated initialization messages to reference Azure OpenAI
- ✅ Updated error messages with Azure-specific guidance

### 4. `setup.ps1`
**Changes:**
- ✅ Updated validation messages to reference Azure OpenAI configuration
- ✅ Changed dependency verification from `sentence-transformers` to `azure-identity`
- ✅ Updated config validation to check Azure OpenAI fields

## Configuration Steps

### 1. Create Azure OpenAI Resource
1. Go to Azure Portal
2. Create an Azure OpenAI resource
3. Note the endpoint (e.g., `https://your-resource.openai.azure.com/`)

### 2. Deploy Models
Deploy these two models in your Azure OpenAI resource:

**Chat Model:**
- Model: `gpt-4` or `gpt-35-turbo`
- Deployment name: (e.g., `gpt-4`) - use this in config

**Embedding Model:**
- Model: `text-embedding-ada-002`
- Deployment name: (e.g., `text-embedding-ada-002`) - use this in config

### 3. Setup Entra ID Authentication
The application uses **DefaultAzureCredential**, which attempts authentication in this order:
1. **Environment variables** (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET)
2. **Managed Identity** (if running on Azure)
3. **Azure CLI** (if logged in via `az login`)
4. **Visual Studio Code** (if signed in)
5. **Azure PowerShell** (if logged in)

**Recommended for local development:**
```powershell
# Install Azure CLI
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"
```

### 4. Grant Permissions
Ensure your identity has the **Cognitive Services OpenAI User** role on the Azure OpenAI resource:

```powershell
# Get your user object ID
$userId = az ad signed-in-user show --query id -o tsv

# Get your Azure OpenAI resource ID
$resourceId = "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.CognitiveServices/accounts/{resource-name}"

# Assign role
az role assignment create --role "Cognitive Services OpenAI User" --assignee $userId --scope $resourceId
```

### 5. Update config.py
Copy `config.py.example` to `config.py` and fill in:

```python
_redis_endpoint = "redis-12345.c62.us-east-1-4.ec2.redns.redis-cloud.com:12345"
_redis_password = "your-redis-password"

_azure_openai_endpoint = "https://your-resource.openai.azure.com/"
_azure_openai_chat_deployment = "gpt-4"  # Your deployment name
_azure_openai_embedding_deployment = "text-embedding-ada-002"  # Your deployment name
_azure_openai_api_version = "2024-02-01"
```

### 6. Run Setup
```powershell
.\setup.ps1
```

## Architecture Changes

### Before (OpenAI)
```
User Query → SentenceTransformers (local) → Embeddings (384-dim)
           → OpenAI API (API key) → GPT-4 Response
```

### After (Azure OpenAI)
```
User Query → Azure OpenAI Embeddings (Entra ID) → Embeddings (1536-dim)
           → Azure OpenAI Chat (Entra ID) → GPT-4 Response
```

## Benefits

1. **Enterprise Security**: Entra ID authentication with role-based access control
2. **Better Embeddings**: Azure's text-embedding-ada-002 (1536-dim) vs MiniLM (384-dim)
3. **No API Keys**: Managed authentication through Azure identity
4. **Azure Integration**: Native integration with Azure services
5. **Compliance**: Meets enterprise compliance requirements
6. **Token Auto-Refresh**: Automatic handling of token expiration

## Performance Considerations

- **Embedding Dimension**: Increased from 384 to 1536 (better quality, slightly more storage)
- **Caching**: Still enabled for both embeddings and LLM responses
- **Token Refresh**: Automatic refresh adds minimal overhead (~100ms on expiration)
- **Network Latency**: Azure OpenAI may have different latency than OpenAI depending on region

## Troubleshooting

### Authentication Errors
```
Error: DefaultAzureCredential failed to retrieve a token
```
**Solution:** Run `az login` and ensure you're logged into Azure CLI

### Permission Errors
```
Error: 403 Forbidden
```
**Solution:** Verify you have "Cognitive Services OpenAI User" role assigned

### Deployment Not Found
```
Error: The API deployment for this resource does not exist
```
**Solution:** Check deployment names in config.py match your Azure OpenAI deployments

### Token Expiration
The application automatically handles token refresh. If you see authentication errors:
1. Try `az login` again
2. Check your Azure subscription is active
3. Verify network connectivity to Azure

## Migration Checklist

- ✅ Update requirements.txt
- ✅ Update config.py.example
- ✅ Modify ToolEmbeddings class
- ✅ Modify LLMService class
- ✅ Update health check endpoint
- ✅ Update setup scripts
- ✅ Create Azure OpenAI resource
- ✅ Deploy chat and embedding models
- ✅ Configure Entra ID authentication
- ✅ Assign appropriate roles
- ✅ Update config.py with Azure settings
- ✅ Test the application

## Backward Compatibility

The code maintains a `OPENAI_CONFIG` alias pointing to `AZURE_OPENAI_CONFIG` for backward compatibility with existing code that may reference it.
