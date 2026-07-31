import pytest
from httpx import AsyncClient


async def test_app_instance(client: AsyncClient):
    assert client is not None
