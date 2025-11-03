# loads env / Config loader

from __future__ import annotations
import os
from dotenv import load_dotenv
from pydantic import BaseModel, Field

load_dotenv(override=True)

class OpenAISettings(BaseModel):
    endpoint: str = Field(validation_alias="AZURE_OPENAI_ENDPOINT")
    api_key: str = Field(validation_alias="AZURE_OPENAI_API_KEY")
    api_version: str = Field(validation_alias="AZURE_OPENAI_API_VERSION", default="2024-08-01-preview")
    chat_deployment: str = Field(validation_alias="AZURE_OPENAI_CHAT_DEPLOYMENT")

class SearchSettings(BaseModel):
    endpoint: str = Field(validation_alias="AZURE_SEARCH_ENDPOINT")
    api_key: str = Field(validation_alias="AZURE_SEARCH_API_KEY")
    index: str = Field(validation_alias="AZURE_SEARCH_INDEX")
    api_version: str = Field(validation_alias="AZURE_SEARCH_API_VERSION", default="2025-09-01")

class SqlSettings(BaseModel):
    server: str = Field(validation_alias="AZURE_SQL_SERVER")
    database: str = Field(validation_alias="AZURE_SQL_DATABASE")
    username: str = Field(validation_alias="AZURE_SQL_USERNAME")
    password: str = Field(validation_alias="AZURE_SQL_PASSWORD")
    odbc_driver: str = Field(validation_alias="AZURE_SQL_ODBC_DRIVER", default="ODBC Driver 18 for SQL Server")

class Settings(BaseModel):
    openai: OpenAISettings = OpenAISettings()
    search: SearchSettings = SearchSettings()
    sql: SqlSettings = SqlSettings()

def get_settings() -> Settings:
    # raises if required envs missing
    return Settings()
