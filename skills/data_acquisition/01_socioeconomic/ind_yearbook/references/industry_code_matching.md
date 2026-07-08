# Industry Code Matching Rules

## Code Lookup Table

Standard reference: GB/T 4754-2012 (National Economic Industry Classification)

The code lookup table RESSET_NLC_INDUSTRYCODE_2012__N_1.csv contains:
- IndCd2, IndNm2: 2-digit major group code and name
- IndCd4, IndNm4: 4-digit sub-group code and name

## Normalization Pipeline

`
Raw industry name → normalize_industry_name() → match against lookup → manual rules fallback
`

### Normalization Rules

| Rule | Example |
|---|---|
| Replace full-width parentheses （） → () | 煤炭开采和洗选业（无烟煤） → correct |
| Strip trailing dots | 食品制造业. → 食品制造业 |
| Unified typos | 镍钴矿采选 → 镍钴矿采选 |
| 专业及辅助性活动 → 辅助活动 | Standardize suffix |
| 蔬菜、菌类、水果和坚果加工 → 蔬菜、水果和坚果加工 | Remove 菌类 |
| 产业用纺织制成品制造 → 非家用纺织制成品制造 | Old → new naming |
| 其他产业用纺织制成品制造 → 其他非家用纺织制成品制造 | Old → new naming |
| 木质制品制造 → 木制品制造 | Simplify |
| 工艺美术及礼仪用品制造 → 工艺美术品制造 | Simplify |
| 其他原油制造 → 人造原油制造 | Fix naming |
| 低速汽车制造 → 低速载货汽车制造 | Fix naming |
| 金属包装容器及材料制造 → 金属包装容器制造 | Simplify |

### Matching Strategy

1. Attempt exact match against normalized lookup names
2. If name matches exactly one code → assign
3. If name matches multiple codes → flag as ambiguous, require manual review
4. If name matches zero codes → apply manual override rules

## Manual Override Rules

These rules cover industry names that differ from the standard classification:

| Yearbook Industry Name | Correct Sector Code | Code Category |
|---|---|---|
| 其他采矿业 | 1200 | cat2 |
| 假肢、人工器官及植(介)入器械制造 | 3586 | cat4 |
| 非家用纺织制成品制造 | 1780 | cat4 |
| 其他非家用纺织制成品制造 | 1789 | cat4 |
| 木制品制造 | 2030 | cat4 |
| 木门窗制造 | 2032 | cat4 |
| 木楼梯制造 | 2032 | cat4 |
| 木地板制造 | 2033 | cat4 |
| 工艺美术品制造 | 2430 | cat4 |
| 专项运动器材及配件制造 | 2442 | cat4 |
| 健身器材制造 | 2443 | cat4 |
| 高铁车组制造 | 3711 | cat4 |
| 铁路机车车辆制造 | 3712 | cat4 |
| 热电联产 | 4411 | cat4 |
| 生物质能发电 | 4419 | cat4 |
| 燃气生产和供应业 | 4500 | cat2 |
| 硅冶炼 | 3218 | cat4 |
| 金属包装容器制造 | 3333 | cat4 |
| 石油、煤炭及其他燃料加工业 | 25 | cat2 |
| 食用菌加工 | 1371 | cat4 |
| 方便面制造 | 1433 | cat4 |
| 其他方便食品制造 | 1433 | cat4 |
| 工业颜料制造 | 2643 | cat4 |
| 工艺美术颜料制造 | 2643 | cat4 |
| 文化用信息化学品制造 | 2664 | cat4 |
| 医学生产用信息化学品制造 | 2664 | cat4 |
| 肥皂及洗涤剂制造 | 2681 | cat4 |
| 特种玻璃制造 | 3049 | cat4 |
| 陈设艺术陶瓷制造 | 3079 | cat4 |
| 园艺陶瓷制造 | 3079 | cat4 |
| 其他陶瓷制品制造 | 3079 | cat4 |
| 竹材加工机械制造 | 3524 | cat4 |

## Regional Sector Name Normalization

Additional rules for regional tables (fewer normalizations needed since regional tables use simpler names):

| Raw | Standardized |
|---|---|
| 非金属矿制品业 | 非金属矿物制品业 |
| 电气机械和器材设备制造业 | 电气机械和器材制造业 |
| 计算机、通讯和其他电子设备制造业 | 计算机、通信和其他电子设备制造业 |
| 农副食品制造业 | 农副食品加工业 |
| 烟草制造业 | 烟草制品业 |
| 家具制品业 | 家具制造业 |

## GB18030 Encoding Detection

When sector code lookup CSV appears garbled:
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

Detection criterion: if iconv() output contains more CJK characters than input, apply the replacement.
