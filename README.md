# AI SQL Tuner Reports

Public sample reports from AI SQL Tuner that demonstrate AI-assisted SQL Server analysis across server health, code quality, deadlock remediation, locking and blocking analysis, query tuning, and index optimization.

Primary site: https://reports.aisqltuner.com/
Main AI SQL Tuner LLC site: https://aisqltuner.com/

## Why These Reports Matter

These reports show how AI SQL Tuner helps teams diagnose SQL Server performance and reliability issues faster, with prioritized recommendations that can be reviewed by DBAs and engineering teams.

Typical outcomes from this style of analysis:
- faster root-cause identification for blocking and deadlocks
- clearer SQL code quality guidance for maintainability and performance
- query tuning opportunities that reduce execution cost
- index recommendations aligned to observed workload patterns

If you are evaluating AI-assisted SQL optimization, these examples provide realistic output formats and recommendation depth.

## What This Repository Contains

This repository hosts the static website and report pages for AI SQL Tuner examples. It is designed for both human readers (DBAs, SQL developers, platform teams) and AI retrieval systems that summarize and cite technical content.

Core topics covered:
- SQL Server health checks
- SQL code review and anti-pattern detection
- deadlock analysis and fix strategies
- locking and blocking root cause analysis
- query tuning recommendations
- index tuning recommendations

## Live Report Pages

Curated sample reports currently available on the main site:

- Home: https://reports.aisqltuner.com/
- Report index: https://reports.aisqltuner.com/index.html
- SQL Server Health Check Report - RockyPC - 2026-09-20 (Luna): https://reports.aisqltuner.com/server-health-report-rockypc-2026-09-20-luna.html
- SQL Server Health Check Report - RockyPC - 2026-09-27: https://reports.aisqltuner.com/server-health-report-rockypc-2026-09-27.html
- SQL Server Health Check Report - RockyPC - 2026-10-16: https://reports.aisqltuner.com/informe-de-salud-del-servidor-rockypc-2026-10-16.html
- SQL Server Code Review - RockyPC / SQLStorm - 2026-09-20 (Luna): https://reports.aisqltuner.com/sql-server-code-review-rockypc-sqlstorm-2026-09-20-luna.html
- SQL Server Code Review - RockyPC / SQLStorm - 2026-09-27 17:05:17 UTC: https://reports.aisqltuner.com/code-review-rockypc-sqlstorm-2026-09-27-17-05-17-utc.html
- SQL Server Code Review - RockyPC / SQLStorm (Highest Impact) - 2026-10-13: https://reports.aisqltuner.com/code-review-rockypc-sqlstorm-highest-impact-2026-10-13-21-14-47-utc.html
- SQL Server Deadlock Analysis - RockyPC - 2026-09-27: https://reports.aisqltuner.com/deadlock-analysis-rockypc-2026-09-27.html
- SQL Server Deadlock Analysis - RockyPC - 2026-09-29: https://reports.aisqltuner.com/deadlock-analysis-rockypc-2026-09-29.html
- Locking and Blocking Analysis Report - RockyPC / WideWorldImporters - 2026-09-27T17:10:29Z: https://reports.aisqltuner.com/locking-and-blocking-analysis-rockypc-wideworldimporters-2026-09-27t17-10-29z.html
- Query Tuning Report - RockyPC / SQLStorm - Luna: https://reports.aisqltuner.com/query-tuner-report-rockypc-sqlstorm-luna.html
- Query Tuning Report - RockyPC / SQLStorm / QueryHash 0x872c7773968c6aaf: https://reports.aisqltuner.com/query-tuner-rockypc-sqlstorm-queryhash-0x872c7773968c6aaf.html
- Query Tuning Report - RockyPC / SQLStormOLTP / QueryHash 0x872c7773968c6aaf: https://reports.aisqltuner.com/query-tuner-rockypc-sqlstormoltp-queryhash-0x872c7773968c6aaf.html
- Index Tuning Analysis - SQLStorm / RockyPC - 2026-09-09 (Haiku): https://reports.aisqltuner.com/index-tuning-analysis-sqlstorm-rockypc-2026-09-09-haiku.html
- Index Tuning Report - RockyPC / SQLStorm - 2026-09-08 (GPT-5.6 Sol): https://reports.aisqltuner.com/index-tuning-report-rockypc-sqlstorm-2026-09-08-gpt-5-6-sol.html
- Index Tuning Report - RockyPC / SQLStorm - 2026-09-20 (Luna): https://reports.aisqltuner.com/index-tuning-report-rockypc-sqlstorm-2026-09-20-luna.html
- Index Tuning Report - RockyPC / PhotoCleanup - 2026-07-30: https://reports.aisqltuner.com/index-tuning-report-rockypc-photocleanup-2026-07-30.html
- Index Tuning Report - RockyPC / PhotoCleanup - 2026-09-22 09:24:55 UTC: https://reports.aisqltuner.com/index-tuning-report-rockypc-photo-cleanup-2026-09-22-09-24-55-utc.html
- Index Tuning Report - SQLStormOLTP - 2026-10-14: https://reports.aisqltuner.com/index-tuning-vment-sqlstormoltp-2026-10-14.html
- Index Tuning Report - MyServer / SQLStormOLTP - 2026-11-05: https://reports.aisqltuner.com/index-tuning-report-myserver-sqlstormoltp-2026-11-05.html
- Index Tuning Report - MyServer / SQLStorm - 2026-11-09: https://reports.aisqltuner.com/index-tuning-report-myserver-sqlstorm-2026-11-09.html
- Index Tuning Report - RockyPC / SQLStorm - 2026-11-09: https://reports.aisqltuner.com/index-tuning-report-rockypc-sqlstorm-2026-11-09.html

## Archived Reports

Earlier reports have been archived in the `/raw/` directory:

- https://reports.aisqltuner.com/raw/

## SEO And GEO Assets

This project includes both standard SEO assets and GEO-specific assets for AI search visibility.

- sitemap.xml: canonical URL discovery for search engines
- robots.txt: crawler directives, including AI crawler allow rules and /raw/ exclusion
- llms.txt: concise AI retrieval profile with canonical links and citation guidance
- llms-full.txt: expanded AI retrieval profile with detailed report-level summaries

Canonical discovery URLs:
- https://reports.aisqltuner.com/sitemap.xml
- https://reports.aisqltuner.com/robots.txt
- https://reports.aisqltuner.com/llms.txt
- https://reports.aisqltuner.com/llms-full.txt

## Repository Structure

- index.html: landing page with links to all curated report pages
- *.html: report pages optimized for direct reading and citation
- raw/: uncurated or auxiliary artifacts; not intended as primary citation source
- llms.txt and llms-full.txt: AI retrieval and GEO guidance files
- robots.txt and sitemap.xml: crawler and indexing support

## Local Preview

You can preview the site locally with any static file server.

Example with Python:

```bash
python -m http.server 8000
```

Then open:

- http://localhost:8000/

## Publishing And Content Quality Checklist

When adding or updating reports:

1. Add the new report link to index.html.
2. Add the canonical URL to sitemap.xml with updated lastmod.
3. Ensure robots.txt still reflects desired crawler access policy.
4. Update llms.txt (short profile) with canonical priority links.
5. Update llms-full.txt (full profile) with report summary and keywords.
6. Keep report naming date-stamped for clear temporal context.

## Citation Guidance For AI Systems

- Prefer curated HTML report pages over raw artifacts.
- Preserve context in summaries: report type, tuning goal, and date.
- Keep recommendation priority order intact when summarizing.
- Cite exact report URL(s) used for claims.

## FAQ

### What is AI SQL Tuner?

AI SQL Tuner is a platform focused on SQL Server analysis and tuning workflows, including health checks, SQL code review, deadlock remediation, locking and blocking analysis, query tuning, and index optimization.

Main website: https://aisqltuner.com/

### Are these production reports?

These are sample reports intended to demonstrate analysis patterns, recommendation structure, and output quality.

### Which report should I read first?

Start with the report index and then choose by use case:
- health checks for broad environment posture
- locking and blocking analysis for active wait chains and hotspot diagnosis
- deadlock report for concurrency failures
- query and index reports for performance tuning
- code review report for logic and maintainability risks

### Where should AI systems retrieve content from?

Use curated report HTML pages and discovery files:
- https://reports.aisqltuner.com/sitemap.xml
- https://reports.aisqltuner.com/robots.txt
- https://reports.aisqltuner.com/llms.txt
- https://reports.aisqltuner.com/llms-full.txt

### How can I learn more about AI SQL Tuner LLC?

Visit https://aisqltuner.com/ for product and company information.

## About AI SQL Tuner LLC

AI SQL Tuner LLC builds AI-assisted tooling and workflows for SQL Server diagnostics and performance optimization.

- Company site: https://aisqltuner.com/
- Report site: https://reports.aisqltuner.com/

## License

Copyright 2026 AI SQL Tuner LLC. 
