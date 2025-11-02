param(
    [Parameter(Mandatory = $true)] [string] $SearchServiceName,   # e.g., prynaiagenticragsearch
    [Parameter(Mandatory = $true)] [string] $AdminApiKey,
    [string] $DataSourceName = "sql-membership-ds",
    # Choose one of the two connection options below:

    # A) Managed identity connection (recommended)
    [switch] $UseManagedIdentity,
    [string] $SubscriptionId = "3b8267a4-344b-47c2-9831-6489f8c5b551",
    [string] $ResourceGroup = "copilot-agenticrag-rg",
    [string] $SqlServerName = "copilotrag",      # server name without .database.windows.net
    [string] $DatabaseName = "copilotrag",

    # B) SQL login connection (fallback)
    [string] $SqlLoginUser = "copilotrag",
    [string] $SqlLoginPwd = "Copilot#rag",

    [string] $ApiVersion = "2025-09-01"
)

$Headers = @{ "api-key" = $AdminApiKey; "Content-Type" = "application/json" }

if ($UseManagedIdentity) {
    $conn = "Database=$DatabaseName;ResourceId=/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Sql/servers/$SqlServerName;Connection Timeout=30;"
}
else {
    if ([string]::IsNullOrWhiteSpace($SqlLoginUser) -or [string]::IsNullOrWhiteSpace($SqlLoginPwd)) {
        throw "Provide -SqlLoginUser and -SqlLoginPwd when not using -UseManagedIdentity."
    }
    $conn = "Server=tcp:$SqlServerName.database.windows.net,1433;Database=$DatabaseName;User ID=$SqlLoginUser;Password=$SqlLoginPwd;Encrypt=true;Connection Timeout=30"
}

$body = @{
    name        = $DataSourceName
    type        = "azuresql"
    credentials = @{ connectionString = $conn }
    container   = @{ name = "report.vw_membership_rag" }  # view as the source table
    # Optional: enable SQL Integrated Change Tracking later if you turn it on in the DB.
    # dataChangeDetectionPolicy = @{ "@odata.type" = "#Microsoft.Azure.Search.SqlIntegratedChangeTrackingPolicy" }
} | ConvertTo-Json -Depth 10

$uri = "https://$SearchServiceName.search.windows.net/datasources('$DataSourceName')?api-version=$ApiVersion"
# $uri = "https://$SearchServiceName.search.windows.net/datasources/$DataSourceName?api-version=${ApiVersion}"
Invoke-RestMethod -Method Put -Uri $uri -Headers $Headers -Body $body
Write-Host "Data source created: $DataSourceName"