# Privacy Redaction Checklist

Before committing changes to this skill:

- Remove absolute personal paths (any path containing user home, workspace names, or server mount points).
- Remove account names, email addresses, or user identifiers.
- Remove tokens, private download URLs, API keys, or credentials.
- Remove browser profile paths, cookie data, or session artifacts.
- Keep only scripts, schemas, examples, and concise references.
- Use placeholders such as `${GCAM_RELEASE_DIR}`, `${UNIT_PRICE_OUT_DIR}`, `${AIRMOSAIC_LOCAL_WORKSPACE}`.
- Keep GCAM releases, results, local caches, temporary databases, and generated reports out of Git.
