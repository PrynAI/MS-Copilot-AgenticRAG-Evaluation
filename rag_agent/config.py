from __future__ import annotations
from pydantic_settings import BaseSettings, SettingsConfigDict

# Each section reads from .env automatically.
class OpenAISettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AZURE_OPENAI_", env_file=".env", extra="ignore")
    endpoint: str                 # e.g. https://<your-openai>.openai.azure.com/
    api_key: str                  # key string
    api_version: str = "2024-08-01-preview"
    chat_deployment: str          # e.g. gpt-5-mini

class SearchSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AZURE_SEARCH_", env_file=".env", extra="ignore")
    endpoint: str                 # https://<your-search>.search.windows.net
    api_key: str
    index: str                    # membership-rag-idx
    api_version: str = "2025-09-01"

class SqlSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AZURE_SQL_", env_file=".env", extra="ignore")
    server: str                   # copilotrag.database.windows.net
    database: str                 # copilotrag
    username: str                 # dev SQL login for local use
    password: str
    odbc_driver: str = "ODBC Driver 18 for SQL Server"

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    openai: OpenAISettings = OpenAISettings()
    search: SearchSettings = SearchSettings()
    sql: SqlSettings = SqlSettings()

def get_settings() -> Settings:
    return Settings()