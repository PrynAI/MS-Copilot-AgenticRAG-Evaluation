# Index design

# content: full row summary from report.vw_membership_rag.

# chunk: token‑chunks for rerank and answers.

# chunkVector: 1536‑dim vectors for ANN search (HNSW).

# Filter fields: keep what you’ll need for guardrails in queries.

# Vector search over 1,536‑dim “text‑embedding‑3‑small” vectors.

# Full‑text search over both chunk and content (BM25).

# Hybrid: combine keyword + vector queries in one call.

# Semantic rank & captions using chunk as the primary content and membership_name as the title;

# domain keywords (status/type/pricing/grade/hub) are prioritized for better factual answers

# The fields referenced in the semantic config exist in the warehouse:

# membership_name, membership_status_original, membership_type_original, special_pricing_reason (in dwh.fact_membership),

# and grade_name / local_hub (in dwh.dim_grade and dwh.dim_hub)

# ===== Step 2B: Create the index (content + chunk + chunkVector) =====
<# 
Creates / updates a hybrid (text + vector) index with semantic config
API: 2025-09-01 (latest stable)
Docs: Indexes - Create or Update; Search POST (vector queries); Configure semantic ranker
#>
param(
    [Parameter(Mandatory = $true)] [string] $SearchServiceName,     # e.g., prynaiagenticragsearch
    [Parameter(Mandatory = $true)] [string] $AdminApiKey,
    [string] $IndexName = "membership-rag-idx",
    [int]    $Dims = 1536,                                        # text-embedding-3-small
    [int]    $HnswM = 8,                                          # valid range 4..10
    [int]    $EfConstruction = 400,
    [int]    $EfSearch = 100,
    [string] $ApiVersion = "2025-09-01"
)

$headers = @{ "api-key" = $AdminApiKey; "Content-Type" = "application/json" }

$index = @{
    name         = $IndexName
    fields       = @(
        # Key: must be searchable:true with analyzer:"keyword" for indexProjections
        @{ name = "id"; type = "Edm.String"; key = $true; searchable = $true; analyzer = "keyword";
            filterable = $false; sortable = $false; facetable = $false 
        },

        # Parent link used by indexProjections (must be filterable, not the key)
        @{ name = "parent_id"; type = "Edm.String"; searchable = $false; filterable = $true; sortable = $false; facetable = $false },

        # Text retrieval
        @{ name = "content"; type = "Edm.String"; searchable = $true; retrievable = $true },
        @{ name = "chunk"; type = "Edm.String"; searchable = $true; retrievable = $true },

        # Vector retrieval
        @{ name = "chunkVector"; type = "Collection(Edm.Single)"; searchable = $true; retrievable = $false; stored = $false;
            dimensions = $Dims; vectorSearchProfile = "mem-hnsw-pro" 
        },

        # Domain fields (filters + semantic keywords)
        @{ name = "gradeName"; type = "Edm.String"; searchable = $false; filterable = $true; facetable = $true },
        @{ name = "hubName"; type = "Edm.String"; searchable = $false; filterable = $true; facetable = $true },
        @{ name = "membership_status_original"; type = "Edm.String"; searchable = $false; filterable = $true; facetable = $true },
        @{ name = "membership_type_original"; type = "Edm.String"; searchable = $false; filterable = $true; facetable = $true },
        @{ name = "special_pricing_reason"; type = "Edm.String"; searchable = $false; filterable = $true; facetable = $true },

        @{ name = "created_utc"; type = "Edm.DateTimeOffset"; searchable = $false; filterable = $true; facetable = $false; sortable = $true }
    )

    vectorSearch = @{
        algorithms = @(
            @{ name = "mem-hnsw"; kind = "hnsw";
                hnswParameters = @{ m = $HnswM; efConstruction = $EfConstruction; efSearch = $EfSearch; metric = "cosine" } 
            }
        )
        profiles   = @(
            @{ name = "mem-hnsw-pro"; algorithm = "mem-hnsw" }
        )
    }

    similarity   = @{
        "@odata.type" = "#Microsoft.Azure.Search.BM25Similarity"; k1 = 1.2; b = 0.75
    }

    # 'semantic' for 2025-09-01
    semantic     = @{
        configurations       = @(
            @{
                name              = "mem-semantic"
                prioritizedFields = @{
                    titleField                = @{ fieldName = "content" }
                    prioritizedContentFields  = @(@{ fieldName = "chunk" }, @{ fieldName = "content" })
                    prioritizedKeywordsFields = @(
                        @{ fieldName = "membership_status_original" },
                        @{ fieldName = "membership_type_original" },
                        @{ fieldName = "special_pricing_reason" },
                        @{ fieldName = "gradeName" },
                        @{ fieldName = "hubName" }
                    )
                }
            }
        )
        defaultConfiguration = "mem-semantic"
    }
} | ConvertTo-Json -Depth 100

$uri = "https://$SearchServiceName.search.windows.net/indexes('$IndexName')?api-version=$ApiVersion"

# If you want to be explicit about deleting first (recommended during dev):
# Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers -ErrorAction SilentlyContinue | Out-Null

Invoke-RestMethod -Method Put -Uri "$uri&allowIndexDowntime=true" -Headers $headers -Body $index
Write-Host "Index created: $IndexName with key analyzer=keyword"
