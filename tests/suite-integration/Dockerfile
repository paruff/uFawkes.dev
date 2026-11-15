# Offline runner for the suite integration harness (run.sh builds and runs it).
# Same Python as uFawkesObs's dora-api image, so date parsing behaves as in prod.
FROM python:3.13-slim@sha256:e48f59cdba69a3cbd9ed2cf0f348d90d45a8d350d98134cf1070bc106ee9ed90
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash curl git jq make \
  && rm -rf /var/lib/apt/lists/*
# .obs.lock is uFawkesObs's own ingestion lock, copied in by run.sh: the code
# under test runs on the dependency versions it ships with.
COPY .obs.lock requirements.txt /deps/
RUN pip install --no-cache-dir -r /deps/.obs.lock -r /deps/requirements.txt
ENV PYTHONDONTWRITEBYTECODE=1 SUITE_ROOT=/suite
WORKDIR /suite/uFawkes.dev/tests/suite-integration
ENTRYPOINT ["python", "-m", "pytest", "-p", "no:cacheprovider"]
