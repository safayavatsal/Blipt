from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    surepass_api_key: str = ""
    surepass_base_url: str = "https://kyc-api.surepass.io/api/v1"
    api_bearer_token: str = ""
    cache_ttl_seconds: int = 86400  # 24 hours
    rate_limit_requests: int = 10
    rate_limit_window_seconds: int = 60
    environment: str = "development"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
