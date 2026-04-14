# AI SQL Tuner Reports

Public sample reports from AI SQL Tuner that demonstrate AI-assisted SQL Server analysis across server health, code quality, deadlock remediation, query tuning, and index optimization.

Primary site: https://reports.aisqltuner.com/

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

## License

Copyright 2026 AI SQL Tuner LLC.
