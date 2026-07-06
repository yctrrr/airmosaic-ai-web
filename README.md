# AirMosaic AI / 清空智枢

**大气环境决策智能分析平台** — 本地化部署，集成 AI Agent、多模态数据获取、模型分析与因果推断。

A locally deployed atmospheric-environment intelligence platform integrating AI agents, multimodal data acquisition, model analysis, and causal inference.

---

## 平台定位

AirMosaic AI 是一个**本地化部署的分析平台**，不是一个线上 SaaS 或纯展示网站。核心能力以可复用的 skills、服务和接口形式组织，供外部 AI Agent（Codex、Claude 等）或本地科研脚本调用。

平台本身不托管 Agent，而是提供标准化的工具层：数据目录、数据获取管道、模型分析方法和因果推断框架。用户可以在本地环境中接入自己的 Agent 来编排这些能力。

---

## 本地部署架构

```
D:\AirMosaicAI\
  airmosaic-ai-core\     ← 本仓库（可上传 GitHub）
  local_workspace\        ← 数据缓存、密钥、运行结果（本地仅存）
  docs\                   ← 开发文档和设计说明（本地仅存）
```

仓库仅包含元数据、skills、服务代码和接口定义。原始数据、模型发行包、私密配置均存放于 `local_workspace`。

---

## 仓库结构

```
catalog/                  数据集元数据（YAML schema）
skills/
  data_acquisition/       WorldPop、GBD 等数据获取 skills
  model/                  GCAM 情景分析、配置、数据提取
src/airmosaic_core/       Python 服务包
  services/
    data_catalog.py       数据目录查询
    data_access.py        本地缓存检查和文件查询
    causal_design.py      因果推断方案生成
examples/                 Agent 调用示例（JSON 请求模板）
tests/                    单元测试
```

---

## 本地启动

### 环境要求

- Python 3.10+
- 环境变量：

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
$env:GCAM_RELEASE_DIR = "<gcam-china-v8-Windows-Release-Package 路径>"
```

### 安装与运行

```powershell
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e ".[dev]"
python -m airmosaic_core.cli
```

---

## Skills

每个 skill 是一个自包含的能力模块，包含 `SKILL.md`（使用说明）、`scripts/`（可执行脚本）、`references/`（领域参考文档）和 `examples/`（调用示例）。

### 数据获取

| Skill | 功能 |
|-------|------|
| WorldPop | 按国家、年份下载人口网格数据，裁切、校验 |
| GBD Results | 从 IHME GBD 获取死亡率、疾病负担参数 |

### 模型分析

| Skill | 功能 |
|-------|------|
| GCAM | 探索 BaseX 输出结构、解读配置文件、参数化提取价格/产量/技术组分 |

GCAM skill 分三层：
- **01_output_structure**: 场景、区域、部门、技术树的 XPath/XQuery 探索
- **02_configuration**: SSP-RCP 设置、CCS 配置、输入数据链追踪
- **03_data_extraction**: 市场/部门价格提取、技术组分分解、省份聚合

---

## 外部 Agent 接入

平台能力通过三种接口暴露给外部 Agent（Codex、Claude 等）：

- **MCP Tools**: 细粒度函数调用，返回结构化 JSON
- **REST / OpenAPI**: 供其他本地服务或脚本调用
- **Python SDK / CLI**: 本地科研脚本和 Jupyter Notebook

Agent 不直接访问文件系统，所有数据读写通过服务接口完成，确保可追溯、可审计。

---

## 数据边界

本仓库**不含**以下内容：

- 原始环境数据（NetCDF, GeoTIFF, CSV, RDS）
- GCAM 模型发行包或 BaseX 数据库
- API 密钥、凭证、私密下载链接
- 模型运行结果和缓存文件

以上内容存放于 `$env:AIRMOSAIC_LOCAL_WORKSPACE`。

---

## License

Apache-2.0. See `LICENSE`.
