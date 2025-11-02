param(
    [Parameter(Mandatory = $true)][string]$SearchServiceName,   # e.g. prynaiagenticragsearch
    [Parameter(Mandatory = $true)][string]$IndexName,           # e.g. membership-rag-idx
    [Parameter(Mandatory = $true)][string]$SearchApiKey,        # Admin or query key
    [string]$Query = "show active memberships in the month of september 2025"
)

$endpoint = "https://$SearchServiceName.search.windows.net"
$uri = "$endpoint/indexes/$IndexName/docs/search?api-version=2025-09-01"

$headers = @{
    "api-key"      = $SearchApiKey
    "Content-Type" = "application/json"
}

$body = @{
    search                = $Query                        # text side
    queryType             = "semantic"
    semanticConfiguration = "mem-semantic"                # your semantic config name
    captions              = "extractive|highlight-true"
    answers               = "extractive|count-3"
    select                = "id,content,chunk,gradeName,hubName,membership_status_original,membership_type_original,special_pricing_reason"
    top                   = 10
    vectorQueries         = @(@{
            kind   = "text"                                   # vectorizable text query
            text   = $Query
            fields = "chunkVector"                            # your vector field
            k      = 50
            weight = 1.0
        })
} | ConvertTo-Json -Depth 10

$result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
$result | ConvertTo-Json -Depth 100
