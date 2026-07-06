# AirMosaic AI / 清空智枢

**大气环境决策智能分析平台** — 本地化部署，集成AI Agent、多模态数据获取、模型分析与因果推断。

[**English**](README.md)

---

## 本地部署架构

```
D:\AirMosaicAI\
  airmosaic-ai-core\     ← 本仓库（GitHub）
  local_workspace\        ← 原始数据、模型发行包、密钥（仅本地）
  docs\                   ← 设计文档（仅本地）
```

## 仓库结构

```
catalog/                   数据集元数据（YAML schema）
skills/
  data_acquisition/       WorldPop、GBD 数据获取
  model/                  GCAM 情景分析、配置、数据提取
src/airmosaic_core/       Python 服务包
  services/
    data_catalog.py        数据集注册查询
    data_access.py         本地缓存检查、路径解析
    causal_design.py       因果分析方案生成
examples/                 Agent 调用示例（JSON 模板）
tests/                    单元测试
```

## 快速启动

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
$env:GCAM_RELEASE_DIR = "<GCAM 发行包路径>"

cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e ".[dev]"
python -m airmosaic_core.cli
```

## 技能模块

每个 skill 是自包含模块，含 `SKILL.md`、`scripts/`、`references/` 和 `examples/`。

| Skill | 功能 |
|-------|------|
| WorldPop | 按国家、年份下载人口网格数据，支持裁切校验 |
| GBD Results | 从 IHME GBD 获取死亡率、疾病负担参数 |
| GCAM | 探索 BaseX 输出结构，解读配置，通过 XQuery 提取价格/产量 |

GCAM skill 分三层：
- **01_output_structure**: 场景、区域、部门、技术树的 XPath/XQuery 探索
- **02_configuration**: SSP-RCP 设置、CCS 配置、输入数据链追踪
- **03_data_extraction**: 市场/部门价格提取、技术组分分解、省份聚合

## 外部 Agent 接入

平台能力通过三种接口暴露：

- **MCP 工具**: 结构化 JSON 函数调用，适配 Codex、Claude 等
- **REST / OpenAPI**: 标准 HTTP API，供前端和其他服务调用
- **Python SDK / CLI**: 本地脚本、Jupyter Notebook、批处理

Agent 不直接访问文件系统，所有数据读写通过服务接口完成。

## 数据边界

本仓库**不含**：原始环境数据、GCAM 模型发行包、BaseX 数据库、API 密钥、模型运行结果。以上存放于 `$env:AIRMOSAIC_LOCAL_WORKSPACE`。

## License

Apache-2.0.
