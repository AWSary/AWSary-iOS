"""Polite HTTP fetching with deterministic, inspectable local caching."""

from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
from pathlib import Path
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen


DEFAULT_USER_AGENT = (
    "AWSaryCommunityIndexer/0.1 "
    "(+https://github.com/tiagorodrigues/AWSary-iOS; public-data research)"
)


@dataclass(frozen=True)
class CachedResponse:
    """Cached response body and relevant transport metadata."""

    url: str
    body: bytes
    content_type: str
    retrieved_at: str
    from_cache: bool
    cache_path: Path


class HttpCache:
    """Minimal HTTP client with retries and an on-disk raw response cache."""

    def __init__(
        self,
        cache_dir: Path,
        *,
        timeout: float = 20.0,
        retries: int = 2,
        delay: float = 0.5,
        user_agent: str = DEFAULT_USER_AGENT,
    ) -> None:
        self.cache_dir = cache_dir
        self.timeout = timeout
        self.retries = retries
        self.delay = delay
        self.user_agent = user_agent
        self._last_request_at: float | None = None
        cache_dir.mkdir(parents=True, exist_ok=True)

    def fetch(
        self,
        url: str,
        *,
        refresh: bool = False,
        method: str = "GET",
        headers: dict[str, str] | None = None,
        body: bytes | None = None,
    ) -> CachedResponse:
        """Fetch an HTTP(S) URL, returning a request-specific cached copy."""

        if urlparse(url).scheme not in {"http", "https"}:
            raise ValueError(f"Unsupported URL scheme: {url}")

        method = method.upper()
        stem = _cache_stem(url, method=method, body=body)
        body_path = self.cache_dir / f"{stem}.body"
        metadata_path = self.cache_dir / f"{stem}.meta.json"
        if not refresh and body_path.exists() and metadata_path.exists():
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            return CachedResponse(
                url=metadata["url"],
                body=body_path.read_bytes(),
                content_type=metadata.get("contentType", "application/octet-stream"),
                retrieved_at=metadata["retrievedAt"],
                from_cache=True,
                cache_path=body_path,
            )

        request_headers = {
            "User-Agent": self.user_agent,
            "Accept": "application/json,text/html;q=0.9,*/*;q=0.1",
        }
        request_headers.update(headers or {})
        request = Request(url, data=body, headers=request_headers, method=method)
        error: Exception | None = None
        for attempt in range(self.retries + 1):
            if self._last_request_at is not None:
                remaining_delay = self.delay - (time.monotonic() - self._last_request_at)
                if remaining_delay > 0:
                    time.sleep(remaining_delay)
            self._last_request_at = time.monotonic()
            try:
                with urlopen(request, timeout=self.timeout) as response:  # noqa: S310 - URLs are validated and caller-controlled
                    body = response.read()
                    content_type = response.headers.get_content_type()
                    final_url = response.geturl()
                    retrieved_at = _utc_now()
                body_path.write_bytes(body)
                metadata_path.write_text(
                    json.dumps(
                        {
                            "url": final_url,
                            "requestedUrl": url,
                            "method": method,
                            "contentType": content_type,
                            "retrievedAt": retrieved_at,
                            "sha256": sha256(body).hexdigest(),
                        },
                        indent=2,
                        sort_keys=True,
                    )
                    + "\n",
                    encoding="utf-8",
                )
                return CachedResponse(final_url, body, content_type, retrieved_at, False, body_path)
            except (HTTPError, URLError, TimeoutError) as exc:
                error = exc
                if attempt < self.retries:
                    time.sleep(self.delay * attempt)
        raise RuntimeError(f"Failed to fetch {url}: {error}") from error


def _cache_stem(url: str, *, method: str, body: bytes | None) -> str:
    parsed = urlparse(url)
    readable = "-".join(filter(None, [parsed.netloc, parsed.path.strip("/").replace("/", "-")]))
    readable = "".join(character if character.isalnum() or character in "-_" else "-" for character in readable)
    readable = readable.strip("-")[:80] or "response"
    request_key = b"\0".join([method.encode("ascii"), url.encode("utf-8"), body or b""])
    return f"{readable}-{sha256(request_key).hexdigest()[:12]}"


def _utc_now() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
