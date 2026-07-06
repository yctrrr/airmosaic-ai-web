# WorldPop API Notes

Use official WorldPop APIs for discovery and spatial services:

- `https://www.worldpop.org/rest/data`
- `https://api.worldpop.org/v1/services`

Data discovery pattern:

```text
GET https://www.worldpop.org/rest/data/pop/<project>?iso3=<ISO3>
```

Returned metadata commonly includes file names or `data_file` values. When `data_file` is relative, resolve it against:

```text
https://data.worldpop.org/
```

Filtering should be conservative. Match country, year, product/project alias, file extension, and product wording before downloading.

Cache manifests under `${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/worldpop/metadata` to avoid repeated API calls.
