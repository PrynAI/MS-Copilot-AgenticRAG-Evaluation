# =====  Provision Azure AI Search (Standard S1) =====
$subscriptionId = "3b8267a4-344b-47c2-9831-6489f8c5b551"  # replace with your subscription ID
$rg = "copilot-agenticrag-rg"
$loc = "uksouth"
$svc = "prynaiagenticragsearch"  # must be globally unique

az account set --subscription $subscriptionId

# Create (or reuse) the resource group
az group create -n $rg -l $loc | Out-Null

# Create Search service with system-assigned managed identity
az search service create `
  --name $svc `
  --resource-group $rg `
  --location $loc `
  --sku standard `
  --partition-count 1 `
  --replica-count 1 `
  --identity-type SystemAssigned | Out-Null

# Show endpoint and admin key you’ll need in Step 2B
$endpoint = "https://$svc.search.windows.net"
$adminKey = az search admin-key show  --service-name $svc --resource-group $rg --query primaryKey -o tsv
Write-Host "Search endpoint: $endpoint"
Write-Host "Admin key: $adminKey"