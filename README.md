# AirMosaic AI / 清空智枢

大气环境决策智能分析平台 — Atmospheric-environment decision intelligence platform.

AirMosaic AI 是一个**本地部署**的数据服务与智能分析平台，集成 AI Agent、多模态数据获取、模型分析和因果推断能力，面向大气环境决策场景。

AirMosaic AI is a **locally deployed** data-service and intelligence-analysis platform that integrates AI agents, multimodal data acquisition, model analysis, and causal inference for atmospheric-environment decision-making.

---

## 本地部署架构 / Local Deployment

```
D:\AirMosaicAI\
  airmosaic-ai-core\     ← 本仓库 / this repo (GitHub)
  local_workspace\        ← 本地数据、缓存、密钥（不上传 / not committed）
  docs\                   ← 本地开发文档（不上传 / not committed）
```

本仓库仅包含平台核心能力：数据目录元数据、数据获取与模型分析 skills、服务接口代码。**不含**原始数据、模型发行包、密钥或本地路径。

This repository contains only the platform core: data catalog metadata, acquisition and model-analysis skills, and service-interface code. Raw data, model releases, credentials, and local paths stay in `local_workspace`.

---

## 仓库结构 / Repository Layout

```
catalog/                 数据集元数据和 schema
skills/
  data_acquisition/      WorldPop、GBD 等数据获取 skills
  model/                 GCAM 情景分析、配置和数据提取 skills
src/airmosaic_core/      Python 服务包（DataCatalog, DataAccess, CausalDesign）
examples/                Agent 调用示例
tests/                   单元测试
index.html               网站入口
app.js                   网站逻辑
styles.css               样式表
```

---

## 本地快速启动 / Quick Start

### 环境要求 / Prerequisites

- Python 3.10+
- 设置环境变量：

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
$env:GCAM_RELEASE_DIR = "<path to gcam-china-v8-Windows-Release-Package>"
```

### 核心服务 / Core Services

```powershell
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e ".[dev]"
python -m airmosaic_core.cli
```

### 网站前端 / Web Frontend

```powershell
cd D:\AirMosaicAI\airmosaic-ai-core
python -m http.server 5176 --bind 127.0.0.1
```

浏览器打开 / Open: http://127.0.0.1:5176/

---

## Skills 说明

### 数据获取 / Data Acquisition

- **WorldPop**: 按国家、年份下载人口网格数据
- **GBD Results**: 从 IHME GBD Results 获取死亡率、疾病负担等参数

### 模型分析 / Model Analysis

- **GCAM**: 探索 GCAM BaseX 输出结构、理解配置文件、提取情景数据
  - 01_output_structure: 场景、区域、部门、技术结构探索
  - 02_configuration: 配置文件解读、SSP-RCP 设置、CCS 配置
  - 03_data_extraction: 参数化 XQuery 提取价格、产量、技术组分

每个 skill 目录包含 `SKILL.md`（说明）、`scripts/`（可执行脚本）、`references/`（参考文档）和 `examples/`（调用示例）。

---

## 外部 Agent 接入 / External Agent Interface

平台能力通过以下方式暴露给外部 Agent：

- **MCP Tools**: 细粒度函数调用，返回结构化 JSON
- **REST / OpenAPI**: 网站前端和其他服务调用
- **Python SDK / CLI**: 本地科研脚本和批处理

Agent 不直接访问文件系统，所有数据读写通过服务接口。

---

## GitHub Pages

本仓库支持从 `main` 分支根目录直接发布为 GitHub Pages 静态站点：

1. Repository `Settings > Pages`
2. Source: `Deploy from a branch`
3. Branch: `main`, folder: `/ (root)`

---

## 数据边界 / Data Boundary

本仓库**不包含**以下内容：

- 原始环境数据（NetCDF, GeoTIFF, CSV）
- GCAM 模型发行包或 BaseX 数据库
- 私密凭证、API 密钥、下载链接
- 模型运行结果和缓存文件

以上内容存放于 `$env:AIRMOSAIC_LOCAL_WORKSPACE`。

---

## License

Apache-2.0. See `LICENSE`.
