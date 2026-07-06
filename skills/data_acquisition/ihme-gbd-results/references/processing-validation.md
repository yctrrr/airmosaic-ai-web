# GBD Processing Validation

Keep processing code in the calling project or service layer. Use this checklist for derived AirMosaic mortality tables:

- Preserve existing column names unless a schema migration is explicit.
- Join raw and processed rows by `year`, `location`, `metric`, `endpoint`, `agegroup`, and `sex`.
- Compare numeric mortality or population values within floating-point tolerance.
- Emit a missing-combination report for requested age/cause/sex/location combinations absent from IHME output.
- Store raw exports, derived tables, and validation reports under `${AIRMOSAIC_LOCAL_WORKSPACE}/data_cache/gbd_health`.
- Do not commit IHME exports or derived health tables to GitHub.
