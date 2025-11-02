param(
    [Parameter(Mandatory = $true)] [string] $SearchServiceName,     # prynaiagenticragsearch
    [Parameter(Mandatory = $true)] [string] $AdminApiKey,
    [string] $IndexerName = "membership-rag-idxr",
    [string] $DataSource = "sql-membership-ds",                # keep existing datasource
    [string] $TargetIndex = "membership-rag-idx",
    [string] $SkillsetName = "membership-rag-ss",
    [string] $ApiVersion = "2025-09-01"
)

$h = @{ "api-key" = $AdminApiKey; "Content-Type" = "application/json" }

# Minimal, explicit mapping: tell the indexer that the *parent key* comes from doc_id in SQL.
# This satisfies indexer validation for the target index key (id).
$fieldMappings = @(
    @{ sourceFieldName = "doc_id"; targetFieldName = "id" }
)

$indexer = @{
    name            = $IndexerName
    dataSourceName  = $DataSource
    targetIndexName = $TargetIndex
    skillsetName    = $SkillsetName
    fieldMappings   = $fieldMappings
    # No outputFieldMappings here: indexProjections in the skillset write child (chunk) docs directly.
} | ConvertTo-Json -Depth 30

$put = "https://$SearchServiceName.search.windows.net/indexers('$IndexerName')?api-version=$ApiVersion"
Invoke-RestMethod -Method Put -Uri $put -Headers $h -Body $indexer
Write-Host "✅ Indexer created: $IndexerName"

# Run now and report status URL
$run = "https://$SearchServiceName.search.windows.net/indexers('$IndexerName')/search.run?api-version=$ApiVersion"
Invoke-RestMethod -Method Post -Uri $run -Headers $h
Write-Host "▶️  Indexer run requested. Check status at:"
Write-Host "GET https://$SearchServiceName.search.windows.net/indexers('$IndexerName')/search.status?api-version=$ApiVersion"