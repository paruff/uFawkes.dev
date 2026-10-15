#!/usr/bin/env bash
# Record docker stats for uFawkes suite mode (Obs + Pipe + DevX on one host).
# Usage: scripts/measure-suite.sh <label> <samples> [interval_s]
#   e.g. scripts/measure-suite.sh idle 30 10   |  scripts/measure-suite.sh pipeline-run 90 10
# Writes CSV to ./suite-measurements/<label>.csv, then prints peak and median per container.
# After 24h of uptime run: scripts/measure-suite.sh disk 0   (prints `docker system df`).
set -euo pipefail
label=${1:?label}
samples=${2:?samples}
interval=${3:-10}
out=suite-measurements
mkdir -p "$out"
csv="$out/$label.csv"

if [ "$samples" -eq 0 ]; then
  docker system df -v | tee "$out/$label.txt"
  exit 0
fi

echo "ts,name,cpu_pct,mem_mib" > "$csv"
for _ in $(seq "$samples"); do
  ts=$(date -u +%FT%TZ)
  docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}}' \
    | awk -F, -v ts="$ts" '{
      gsub(/%/,"",$2); split($3,m," / "); v=m[1]; n=v+0
      if (v ~ /GiB/) n*=1024; else if (v ~ /KiB/) n/=1024; else if (v ~ /B$/ && v !~ /MiB/) n/=1048576
      printf "%s,%s,%s,%.1f\n", ts,$1,$2,n }' >> "$csv"
  sleep "$interval"
done

# Per container: peak and median memory (MiB), peak CPU (%); then suite-wide sum per sample.
awk -F, 'NR>1 { k=$2; mem[k]=mem[k] " " $4; if ($4>pm[k]) pm[k]=$4; if ($3>pc[k]) pc[k]=$3; s[$1]+=$4; c[$1]+=$3 }
  END { printf "%-40s %10s %10s %8s\n","container","peak_MiB","median_MiB","peak_cpu%";
        for (k in mem) { n=split(mem[k],a," "); asort(a); printf "%-40s %10.0f %10.0f %8.1f\n",k,pm[k],a[int((n+1)/2)],pc[k] }
        for (t in s) { if (s[t]>sp) sp=s[t]; if (c[t]>cp) cp=c[t] }
        printf "%-40s %10.0f %10s %8.1f\n","SUITE (peak sample sum)",sp,"-",cp }' "$csv"
