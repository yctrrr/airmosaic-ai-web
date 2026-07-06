# Privacy Redaction Rules

- Use `${AIRMOSAIC_LOCAL_WORKSPACE}` or `${WORLDPOP_CACHE_ROOT}` in documentation and examples.
- Do not commit raster downloads, derived rasters, manifests containing private local paths, browser caches, or temporary files.
- Do not store credentials or API tokens. Public WorldPop discovery normally does not require user credentials.
- Keep only reusable scripts, schema files, concise references, and small examples in Git.
