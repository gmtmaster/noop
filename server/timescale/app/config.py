from functools import lru_cache
from os import getenv

from pydantic import BaseModel


class Settings(BaseModel):
    database_url: str
    api_token: str | None = None


@lru_cache
def settings() -> Settings:
    return Settings(
        database_url=getenv(
            "NOOP_TIMESCALE_DATABASE_URL",
            "postgresql://noop:noop@localhost:5432/noop",
        ),
        api_token=getenv("NOOP_TIMESCALE_API_TOKEN"),
    )
