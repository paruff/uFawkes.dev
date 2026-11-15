"""The real uFawkesObs dora-api, in-process.

The app is served over an ASGI transport without its lifespan, so the
background worker and compute loops never start. Tests run both by hand
(drain, metrics): no sleeps, no polling, nothing that depends on timing.
"""

import asyncio
import contextlib
import os
import sqlite3
from datetime import datetime

import httpx


class ObsStack:
    def __init__(self, db_path):
        self.db_path = str(db_path)
        os.environ["DATABASE_URL"] = f"sqlite:///{self.db_path}"
        from ingestion.api.main import app

        self._loop = asyncio.new_event_loop()
        self._client = httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://dora-api"
        )

    def _run(self, coro):
        return self._loop.run_until_complete(coro)

    def post(self, path, payload, **kwargs) -> httpx.Response:
        return self._run(self._client.post(path, json=payload, **kwargs))

    def get(self, path) -> httpx.Response:
        return self._run(self._client.get(path))

    def drain(self) -> int:
        """Run the real worker over every pending event. Returns how many."""
        from ingestion.api.queue import dequeue_next
        from ingestion.processor.worker import process_event

        async def _drain():
            count = 0
            while (event := await dequeue_next()) is not None:
                assert await process_event(event), f"worker failed on {event}"
                count += 1
            return count

        return self._run(_drain())

    def claim(self) -> dict | None:
        """Take the next event off the queue the way the worker does, and stop
        there: what a worker killed mid-event leaves behind."""
        from ingestion.api.queue import dequeue_next

        return self._run(dequeue_next())

    def worker_mid_dequeue(self) -> None:
        """Leave the worker where a request can interleave with it: its claim
        statement (the one in dequeue_next) has run and its row is not read yet.
        The worker and the API share one connection, so this is a real state."""
        import inspect

        from ingestion.api import queue_sqlite
        from ingestion.api.queue import get_pool

        claim = (
            "UPDATE event_queue SET status = 'processing' WHERE id = ( "
            "SELECT id FROM event_queue WHERE status = 'pending' ORDER BY received_at LIMIT 1 "
            ") RETURNING id, payload, event_type, source, attempts"
        )
        # This is a copy of dequeue_next's statement; fail loudly if dora-api changes it.
        assert claim in " ".join(inspect.getsource(queue_sqlite.dequeue_next).split())

        async def _claim() -> None:
            conn = await get_pool()
            self._open_cursor = await conn.execute(claim)

        self._run(_claim())

    def deliver(self, event: dict, ingested_at: datetime | None = None) -> int:
        """POST one event, process it, and return its queue id.

        ingested_at moves the moment dora-api received it (raw_events.recorded_at),
        which is how a test delivers events late or out of order.
        """
        response = self.post("/event", event)
        assert response.status_code == 201, response.text
        event_id = response.json()["id"]
        self.drain()
        if ingested_at is not None:
            self.sql(
                "UPDATE raw_events SET recorded_at = ? WHERE event_queue_id = ?",
                (ingested_at.replace(tzinfo=None).isoformat(" "), event_id),
            )
        return event_id

    def metrics(
        self, window_days: int = 30, team: str | None = None
    ) -> dict[str, dict]:
        """Run the real compute cycle. Returns its records keyed by team_id."""
        from compute.metrics import compute_all_metrics

        return {
            r["team_id"]: r for r in self._run(compute_all_metrics(window_days, team))
        }

    def sql(self, query: str, params=()) -> list[tuple]:
        with contextlib.closing(sqlite3.connect(self.db_path)) as conn, conn:
            return conn.execute(query, params).fetchall()

    def close(self) -> None:
        from ingestion.api.queue import close_pool

        cursor = getattr(self, "_open_cursor", None)
        if cursor is not None:
            self._run(cursor.close())
        self._run(self._client.aclose())
        self._run(close_pool())
        self._loop.close()
