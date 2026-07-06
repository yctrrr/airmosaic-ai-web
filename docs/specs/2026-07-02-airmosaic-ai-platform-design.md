# AirMosaic AI 平台设计文档

日期：2026-07-02  
项目名：AirMosaic AI  
中文名：清空智枢  
副标题：大气环境决策智能分析平台  
项目目录：`D:\AirMosaicAI`

## 1. 平台定位

AirMosaic AI 是一个面向外部 Agent、研究人员、网站前端和科研脚本的大气环境决策能力平台。它不以“本地托管一个 Agent 应用”为核心，而是提供标准化的数据目录、数据获取技能、空间处理、模型设计和因果设计能力，让外部 Agent 可以调用这些能力完成分析任务。

平台的核心目标是把空气污染、社会经济、健康影响、政策情景和因果推断连接起来，形成可解释、可审计、可复用的决策分析工作流。

## 2. 明确不做的事情

第一阶段不做以下内容：

- 不把 TAP、MEIC、遥感、统计年鉴等大数据全量下载进项目仓库。
- 不把外部 Agent 固定为某一个本地服务。
- 不让 Agent 直接猜测和读取散落在磁盘中的数据路径。
- 不把模型脚本直接堆到网站后端中。
- 不先追求完整政策评估闭环，而是先界定数据目录和服务能力边界。

## 3. 设计原则

1. **数据轻目录，按需获取**
   - 项目管理数据源注册、元数据、获取方法和缓存路径。
   - 数据按年份、区域、变量、瓦片或情景按需下载。

2. **服务化能力，外部 Agent 调用**
   - 平台能力通过 MCP tools、REST/OpenAPI、Python SDK/CLI 暴露。
   - 外部 Agent 可以编排这些服务，但平台本身不绑定单一 Agent 框架。

3. **模型和因果推断可解释**
   - 模型设计必须声明输入、输出、假设、参数和不确定性。
   - 因果推断必须显式定义 treatment、outcome、confounders、识别策略和稳健性检验。

4. **工程目录清晰**
   - 数据目录、技能、服务、文档、示例分开。
   - 后续添加新数据源时只需增加 catalog 和 acquisition skill，不改核心服务边界。

## 4. 项目拆分与目录结构

AirMosaic AI 应拆成两个可上传 GitHub 的项目，以及一个只在本地使用的工作区。

```text
D:\AirMosaicAI\
  airmosaic-ai-core\      # 可上传 GitHub：平台核心能力
  airmosaic-ai-web\       # 可上传 GitHub：网站源代码
  local_workspace\        # 不上传：本地数据、缓存、密钥、运行结果
  docs\                   # 当前阶段的总体设计和研究文档
```

### 4.1 `airmosaic-ai-core`

`airmosaic-ai-core` 是平台能力项目，面向外部 Agent、研究脚本、网站后端和命令行用户。它可以上传 GitHub。

包含：

- 数据目录 schema 和数据源 YAML。
- 数据获取 skills。
- Data Catalog、Data Access、Geospatial、Model Design、Causal Design 等服务。
- MCP、REST/OpenAPI、CLI、Python SDK 接口。
- 轻量示例和测试。
- 平台核心文档。

不包含：

- 原始大数据。
- 私有下载链接 token。
- API key。
- 本地绝对路径配置。
- 下载缓存和模型输出。

### 4.2 `airmosaic-ai-web`

`airmosaic-ai-web` 是网站源代码项目，面向用户展示和交互。它可以上传 GitHub。

包含：

- 首页和品牌展示。
- 数据目录浏览页。
- Agent 接入说明页。
- 决策分析仪表盘 UI。
- 调用 core 服务的 API client。
- mock 数据和轻量 demo。
- 网站部署配置。

不包含：

- 数据下载主体逻辑。
- 因果推断和模型核心逻辑。
- 大体量数据文件。
- 密钥和本地缓存。

### 4.3 `local_workspace`

`local_workspace` 是本地运行区，不上传 GitHub。

包含：

- 下载后的 TAP、MEIC、人口、GDP、GBD 等数据缓存。
- `.env` 和本地配置。
- 日志。
- 临时输出。
- 模型运行结果。
- 本地路径映射配置。

### 4.4 `airmosaic-ai-core` 建议结构

建议第一阶段采用以下结构：

```text
D:\AirMosaicAI\airmosaic-ai-core\
  catalog\
    datasets\
      tap_pm25.yaml
      meic_emission.yaml
      population.yaml
      gdp.yaml
      health_burden.yaml
      admin_boundary.yaml
    schemas\
      dataset.schema.json
      variable.schema.json

  skills\
    data_acquisition\
      tap\
      meic\
      population\
      gbd_health\
      weather_reanalysis\
      local_indexer\

  services\
    data_catalog\
    data_access\
    geospatial\
    model_design\
    causal_design\
    decision_analysis\

  interfaces\
    mcp\
    rest_api\
    cli\
    python_sdk\

  docs\
    research\
    specs\
    user_guides\

  examples\
    agent_calls\
    notebooks\
    workflows\
```

### 4.5 `airmosaic-ai-web` 建议结构

```text
D:\AirMosaicAI\airmosaic-ai-web\
  app\
  components\
  lib\
    api-client\
    mock-data\
  public\
  docs\
  tests\
```

### 4.6 `local_workspace` 建议结构

```text
D:\AirMosaicAI\local_workspace\
  data_cache\
    tap\
    meic\
    population\
    gbd_health\
  logs\
  outputs\
  secrets\
  temp\
```

## 5. 数据目录边界

`catalog/datasets` 只保存数据源的元数据，不保存大体量数据本身。每个数据集条目应至少包含：

- `dataset_id`
- `name`
- `domain`
- `description`
- `spatial_coverage`
- `spatial_resolution`
- `temporal_coverage`
- `temporal_resolution`
- `formats`
- `variables`
- `access_method`
- `license_or_terms`
- `local_cache_policy`
- `default_cache_root`
- `acquisition_skill`
- `quality_notes`
- `example_queries`

第一阶段建议注册以下数据：

| dataset_id | 数据 | 作用 |
|---|---|---|
| `tap_pm25_1km` | TAP PM2.5 1km | 污染暴露、地图、健康负担 |
| `meic_emission` | MEIC 排放清单 | 源排放、情景分析、贡献分解 |
| `population_grid` | 人口网格/行政区人口 | 暴露人口、健康负担、社会经济匹配 |
| `gdp_economic` | GDP、收入、产业、经济统计 | 经济影响和不平等分析 |
| `gbd_health` | GBD 或健康负担参数 | 基线死亡率、疾病终点、风险函数 |
| `admin_boundary` | 行政区划和网格边界 | 空间聚合、区域查询、地图展示 |

## 6. 数据获取技能边界

`skills/data_acquisition` 保存数据获取和整理能力。它们不是一次性脚本，而应具备统一行为：

- 接收参数：年份、区域、变量、瓦片、输出目录。
- 支持断点续传和跳过已有文件。
- 下载后做校验、解压和目录整理。
- 记录日志。
- 输出结构化结果：文件清单、本地路径、缺失项、失败项。

第一阶段优先迁移 TAP 获取 skill：

```text
skills/data_acquisition/tap/
  SKILL.md
  scripts/
    download_tap_urls.ps1
    organize_tap_pm25.py
    validate_tap_files.py
  examples/
    tap_pm25_2023_tiles.json
```

TAP skill 的目标不是默认下载全部 TAP 数据，而是支持按 `year`、`tile`、`scale`、`url_list` 精准获取。

## 7. 服务边界

### 7.1 Data Catalog Service

负责回答“有什么数据、能做什么、如何获取”。

核心能力：

- `list_datasets`
- `describe_dataset`
- `search_datasets`
- `list_variables`
- `get_access_requirements`
- `recommend_dataset_for_task`

### 7.2 Data Access Service

负责回答“本地有没有、在哪里、缺什么、如何 materialize 子集”。

核心能力：

- `query_files`
- `check_local_availability`
- `materialize_subset`
- `get_cache_path`
- `validate_dataset_files`

### 7.3 Data Acquisition Service

负责调用具体数据获取 skill。

核心能力：

- `acquire_dataset`
- `resume_acquisition`
- `validate_download`
- `organize_files`
- `summarize_acquisition_log`

### 7.4 Geospatial Service

负责空间处理和地理统计，不直接承担业务解释。

核心能力：

- `clip_raster`
- `aggregate_grid_to_region`
- `join_grid_with_population`
- `convert_crs`
- `summarize_by_admin`
- `generate_map_layer_metadata`

### 7.5 Model Design Service

负责把研究问题转成模型方案。

核心能力：

- `recommend_model`
- `define_model_inputs`
- `define_model_outputs`
- `draft_workflow`
- `check_data_requirements`

支持的第一批模型类型：

- 暴露评估模型
- 健康负担模型
- 经济影响模型
- 不平等指标模型
- 政策情景模型

### 7.6 Causal Design Service

负责把政策问题转成因果识别方案。

核心能力：

- `define_causal_question`
- `suggest_identification_strategy`
- `build_causal_dag_spec`
- `recommend_estimators`
- `recommend_refutation_tests`
- `draft_causal_analysis_plan`

第一阶段只输出设计方案，不强制直接运行因果模型。

### 7.7 Decision Analysis Service

负责整合指标、模型结果和因果设计，服务网站和外部 Agent。

核心能力：

- `summarize_policy_scenario`
- `compare_regions`
- `compare_years`
- `summarize_tradeoffs`
- `generate_decision_brief`

## 8. 外部 Agent 接入方式

平台应同时预留三种接口。

### 8.1 MCP Tools

适合 Claude、Codex 或其他支持 MCP 的 Agent 调用。MCP 工具应是细粒度、可审计、返回结构化 JSON 的函数。

示例：

```text
search_datasets(query)
describe_dataset(dataset_id)
acquire_dataset(dataset_id, filters)
query_files(dataset_id, filters)
recommend_model(question, datasets)
draft_causal_analysis_plan(question, treatment, outcome)
```

### 8.2 REST / OpenAPI

适合网站前端、其他服务和非 MCP Agent 调用。

建议路径：

```text
GET  /datasets
GET  /datasets/{dataset_id}
POST /datasets/{dataset_id}/acquire
POST /data/query-files
POST /models/recommend
POST /causal/design
POST /decision/brief
```

### 8.3 Python SDK / CLI

适合本地科研脚本、Jupyter Notebook 和批处理任务。

示例：

```python
from airmosaic import catalog, acquisition, causal

catalog.search("PM2.5 1km China 2023")
acquisition.acquire("tap_pm25_1km", years=[2023], tiles=[12, 13])
causal.design(
    treatment="clean air policy",
    outcome="mortality",
    unit="county",
)
```

## 9. 网站第一版范围

网站第一版应该展示平台能力，而不是只做宣传页。

建议首页包含：

1. **Agent 接入入口**
   - 展示外部 Agent 可以调用的平台工具。
   - 提供示例任务：“获取 2023 年 TAP PM2.5 指定瓦片并做区域暴露聚合”。

2. **数据目录浏览**
   - 列出已注册数据集。
   - 显示空间尺度、时间范围、变量、获取方式、缓存状态。

3. **决策分析能力地图**
   - 展示从数据到模型、因果设计、政策简报的流程。

4. **服务接口文档入口**
   - MCP、REST、CLI/Python SDK 三类接口说明。

第一版不要求完成所有真实后端能力，但页面结构必须和服务边界一致。

## 10. 第一阶段实施范围

第一阶段建议只实现最小但完整的基础层，并优先放在 `airmosaic-ai-core` 中：

1. 建立目录结构。
2. 编写数据目录 schema。
3. 注册 TAP、MEIC、人口、GDP、健康、行政区划六类数据。
4. 迁移 TAP 数据获取 skill。
5. 实现 Data Catalog Service 的本地读 YAML 能力。
6. 实现 Data Access Service 的本地文件查询和缺失检查。
7. 实现 Causal Design Service 的方案生成接口。
8. 在 `airmosaic-ai-web` 中建立网站原型，展示外部 Agent 可调用的能力。

## 11. 验收标准

第一阶段完成后应满足：

- 外部 Agent 可以查询数据目录，而不是猜路径。
- TAP 数据可以按需下载、整理、校验。
- 服务能明确区分“已缓存数据”和“可获取但未下载数据”。
- 用户可以从网站看到 AirMosaic AI 的数据、服务和 Agent 接入能力。
- 因果模块能输出结构化设计方案，包括 treatment、outcome、confounders、识别策略和稳健性检验。
- 项目目录中没有大体量原始数据，只有元数据、技能、服务代码和轻量示例。

## 12. 风险与处理

| 风险 | 处理 |
|---|---|
| 数据源链接过期 | 在 acquisition skill 中保留 URL 更新、失败重试和日志机制 |
| Agent 调用能力过宽 | 所有工具返回结构化结果，禁止任意路径读写 |
| 模型结果不可复现 | 后续接入 workflow log 和 experiment metadata |
| 因果推断被误用 | 输出识别假设和稳健性检查，不默认给出“因果结论” |
| 网站变成静态展示 | 首页直接围绕数据目录、Agent 工具和决策流程组织 |

## 13. 下一步

本设计确认后，下一步应编写实施计划，优先覆盖：

1. 项目骨架。
2. 数据目录 schema。
3. TAP acquisition skill。
4. Data Catalog/Data Access 最小服务。
5. 网站原型。
