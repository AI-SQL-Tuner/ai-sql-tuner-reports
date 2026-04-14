# AI SQL Tuner Reports

Public sample reports from AI SQL Tuner that demonstrate AI-assisted SQL Server analysis across server health, code quality, deadlock remediation, query tuning, and index optimization.

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
- query tuning recommendations
- index tuning recommendations

## Live Report Pages

- Home: https://reports.aisqltuner.com/
- Report index: https://reports.aisqltuner.com/index.html
- Server health check (GPT 5.4 low reasoning): https://reports.aisqltuner.com/aisqltuner-server-health-check-20260412-gpt-5-4-low.html
- Server health check (Claude Sonnet 4.6 low reasoning): https://reports.aisqltuner.com/aisqltuner-server-health-check-20260412-sonnet-4-6-low.html
- SQL code review: https://reports.aisqltuner.com/aisqltuner-code-review-20260301.html
- Deadlock analysis and fix: https://reports.aisqltuner.com/aisqltuner-fix-deadlocks-20260320.html
- Query tuner: https://reports.aisqltuner.com/aisqltuner-query-tuner-sp00060-20260328.html
- Index tuning (SQLStorm): https://reports.aisqltuner.com/aisqltuner--sqlstorm-index-tuning-20260319.html

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

AI SQL Tuner is a platform focused on SQL Server analysis and tuning workflows, including health checks, SQL code review, deadlock remediation, query tuning, and index optimization.

Main website: https://aisqltuner.com/

### Are these production reports?

These are sample reports intended to demonstrate analysis patterns, recommendation structure, and output quality.

### Which report should I read first?

Start with the report index and then choose by use case:
- health checks for broad environment posture
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
