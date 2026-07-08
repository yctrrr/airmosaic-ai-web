# Encoding Repair Methods

## Problem

Chinese industrial yearbook Excel files are frequently authored in GB18030/GBK on Windows systems. When read into R in a UTF-8 locale, column names and cell text may appear as garbled byte sequences rather than valid Chinese characters.

## Detection Heuristic

`
needs_gb18030_repair <- function(dt) {
  current_names <- names(dt)
  converted_names <- iconv(current_names, from = "GB18030", to = "UTF-8")
  !("资产总计" %in% current_names) && ("资产总计" %in% converted_names)
}
`

If 资产总计 appears only after conversion, the table likely needs repair.

## General Repair Function

`
decode_gb18030 <- function(x) {
  converted <- iconv(x, from = "GB18030", to = "UTF-8")
  converted[is.na(converted)] <- x[is.na(converted)]
  converted
}

repair_encoding_if_needed <- function(dt) {
  if (!needs_gb18030_repair(dt)) return(dt)
  setnames(dt, decode_gb18030(names(dt)))
  char_cols <- names(dt)[vapply(dt, is.character, logical(1))]
  for (col in char_cols) {
    dt[[col]] <- decode_gb18030(dt[[col]])
  }
  dt
}
`

## Per-Cell Selective Repair

For tables where only some columns are affected:

`
repair_gb18030_text <- function(dt) {
  char_cols <- names(dt)[vapply(dt, is.character, logical(1))]
  for (col in char_cols) {
    converted <- iconv(dt[[col]], from = "GB18030", to = "UTF-8")
    use <- !is.na(converted) &
      str_count(converted, "[\\u4e00-\\u9fff]") > str_count(dt[[col]], "[\\u4e00-\\u9fff]")
    dt[[col]][use] <- converted[use]
  }
  dt
}
`

Selective repair avoids corrupting cells that are already valid UTF-8.

## Unicode Code Point Workaround

For scripts that must run in multibyte Windows consoles, construct Chinese strings from Unicode code points:

`
u <- function(codepoints) intToUtf8(codepoints)

cn <- list(
  national    = u(c(0x5168, 0x56FD)),            # 全国
  province    = u(c(0x7701, 0x7EA7)),            # 省级
  yearbook    = u(c(0x5E74, 0x9274)),            # 年鉴
  output      = u(c(0x4EA7, 0x91CF))             # 产量
)
`

## Common Garbled Patterns

| Expected | Garbled (GB18030 bytes) | Repair |
|---|---|---|
| 资产总计 | 璧勪骇鎬昏 | iconv(x, "GB18030", "UTF-8") |
| 流动资产合计 | 娴佸姩璧勪骇鍚堣 | iconv(x, "GB18030", "UTF-8") |
| 所有者权益合计 | 鎵€鏈夎€呮潈鐩婂悎璁 | iconv(x, "GB18030", "UTF-8") |
| 累计折旧 | 绱鎶樻棫 | iconv(x, "GB18030", "UTF-8") |

## Prevention

- Always read Excel files with col_types = "text" to avoid premature type coercion
- Use writeLines(..., useBytes = TRUE) when writing Chinese text files
- Use write(dt, path, bom = TRUE) for CSV output with UTF-8 BOM
