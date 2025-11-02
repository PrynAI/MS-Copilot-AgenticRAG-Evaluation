param(
    [Parameter(Mandatory = $true)] [string] $SearchServiceName,
    [Parameter(Mandatory = $true)] [string] $AdminApiKey,

    # Azure OpenAI (Foundry/Portal) endpoint MUST be *.openai.azure.com for the skill
    [Parameter(Mandatory = $true)] [string] $AoaiEndpoint,          # e.g., https://agenticragtesting.openai.azure.com
    [Parameter(Mandatory = $true)] [string] $AoaiApiKey,
    [Parameter(Mandatory = $true)] [string] $AoaiEmbeddingDeployment, # e.g., text-embedding-3-small

    [string] $SkillsetName = "membership-rag-ss",
    [string] $TargetIndex = "membership-rag-idx",
    [int]    $Dims = 1536,
    [int]    $MaxChars = 1200,   # ≈ 256 tokens
    [int]    $OverlapChars = 300,
    [string] $ApiVersion = "2025-09-01"
)

$h = @{ "api-key" = $AdminApiKey; "Content-Type" = "application/json" }

# 1) Split SQL row's /document/content into "pages"
$split = @{
    "@odata.type"     = "#Microsoft.Skills.Text.SplitSkill"
    name              = "splitPages"
    description       = "Split content into character-sized pages"
    context           = "/document"
    textSplitMode     = "pages"
    maximumPageLength = $MaxChars
    pageOverlapLength = $OverlapChars
    inputs            = @(@{ name = "text"; source = "/document/content" })
    outputs           = @(@{ name = "textItems"; targetName = "pages" })       # -> /document/pages/*
}

# 2) Embed each page (fan-out context)
$embed = @{
    "@odata.type" = "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill"
    name          = "aoaiEmbedding"
    context       = "/document/pages/*"
    resourceUri   = $AoaiEndpoint                                    # must be openai.azure.com for the skill
    apiKey        = $AoaiApiKey
    deploymentId  = $AoaiEmbeddingDeployment
    modelName     = "text-embedding-3-small"
    dimensions    = $Dims
    inputs        = @(@{ name = "text"; source = "/document/pages/*" })
    outputs       = @(@{ name = "embedding"; targetName = "embedding" })    # -> /document/pages/*/embedding
}

# 3) Index projections: one child doc per page
$projections = @{
    selectors  = @(
        @{
            targetIndexName    = $TargetIndex
            parentKeyFieldName = "parent_id"         # required in the index
            sourceContext      = "/document/pages/*"
            mappings           = @(
                @{ name = "chunk"; source = "/document/pages/*" },
                @{ name = "chunkVector"; source = "/document/pages/*/embedding" },

                # repeat parent-level metadata onto each chunk doc (optional but useful)
                @{ name = "content"; source = "/document/content" },
                @{ name = "membership_status_original"; source = "/document/membership_status_original" },
                @{ name = "membership_type_original"; source = "/document/membership_type_original" },
                @{ name = "special_pricing_reason"; source = "/document/special_pricing_reason" }
            )
        }
    )
    parameters = @{ projectionMode = "skipIndexingParentDocuments" }
}

$body = @{
    name             = $SkillsetName
    description      = "Split to pages, embed, then project pages as chunk docs"
    skills           = @($split, $embed)
    indexProjections = $projections
} | ConvertTo-Json -Depth 100

$uri = "https://$SearchServiceName.search.windows.net/skillsets('$SkillsetName')?api-version=$ApiVersion"
Invoke-RestMethod -Method Put -Uri $uri -Headers $h -Body $body
Write-Host "Skillset created: $SkillsetName"