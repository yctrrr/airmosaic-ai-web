# AirMosaic AI / 清空智枢

**大气环境决策智能分析平台** —— 本地化部署，集成 AI Agent、多模态数据获取、模型分析与因果推断。

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
workflow/                  分析流水线模板（4层架构）
AGENTS.md                  面向外部 agent 的安装、读取与操作说明
skills/
  data_acquisition/        数据源连接器，按 workflow 层级组织
    01_socioeconomic/      WorldPop、CSMAR、工业年鉴
    02_emission_inventory/ 排放清单数据获取
    03_atmospheric_transport/ 空气质量与传输相关数据
    04_impact/             GBD Results、健康数据
  model/                   模型分析方法，按 workflow 层级与模型类型组织
    01_socioeconomic/      社会经济建模
    02_emission_inventory/ 排放建模
    03_atmospheric_transport/ 大气传输建模
    04_impact/             健康影响分析、PM2.5 PAF 死亡负担评估
    IAM/                   综合评估模型
      gcam/                GCAM 情景分析、输出结构探索、配置解读、数据提取
src/airmosaic_core/        Python 服务层（CLI / SDK backend）
  services/
    data_catalog.py        数据集注册表：按层级、领域、格式查询数据
    data_access.py         本地缓存解析：路径查找、可用性检查、校验和验证
    causal_design.py       因果推断本地模板：treatment/outcome 定义 -> DAG + estimator 草案
examples/                  Agent 调用示例（JSON 模板）
tests/                     单元测试
```

## 分析流水线

四层分析架构，每层支持 AI 方法与经验/专家方法分支：

```
Layer 1: 社会经济驱动力 -> 活动水平、能源使用、末端治理技术
Layer 2: 排放清单编制 -> 污染物与碳排放
Layer 3: 大气化学传输 -> 浓度场模拟
Layer 4: 社会经济影响 -> 健康负担、经济损失、不平等评估
```

方法选择取决于数据可用性。对于历史样本、空间样本或标签数据足够多的模块，AirMosaic AI 推荐使用 transformer 等 AI model 加快模式识别、变量交互发现和候选因果效应识别。对于数据量不足、观测稀疏或标签不足的模块，推荐优先使用经验公式、过程假设和专家审核规则。

## 快速启动

```powershell
# 安装
cd D:\AirMosaicAI\airmosaic-ai-core
pip install -e .[dev]

# CLI：列出 data acquisition skills 声明可获取/处理的数据集
airmosaic list-datasets
airmosaic list-datasets --layer 01_socioeconomic
airmosaic list-datasets --skill worldpop
airmosaic list-datasets --domain health

# CLI：检查本地数据可用性
airmosaic check-availability population

# CLI：生成本地因果分析模板草案
airmosaic draft-causal-plan --question "清洁空气政策是否降低了死亡率？" --treatment "清洁空气政策" --outcome "死亡率"
```

### 外部 Agent 读取示例

对于 Codex 或其他本地 agent，建议从仓库根目录开始，并要求 agent 先读取项目说明：

```text
打开 D:\AirMosaicAI\airmosaic-ai-core。
先读取 AGENTS.md。
使用 `airmosaic list-datasets` 查看各 data acquisition skill 声明的数据集。
使用 `airmosaic check-availability population` 检查人口数据缓存。
运行任何 workflow 前，先读取相关的 `skills/**/SKILL.md`。
`airmosaic draft-causal-plan ...` 只生成本地 JSON 草案，不会调用外部 LLM；后续分析需要由外部 agent 继续推理和扩展。
```

## 技能模块

每个 skill 是自包含模块，包含 `SKILL.md`、`scripts/`、`references/` 和 `examples/`。每个 skill 封装一个数据源、模型或分析方法，并提供对应工具、说明文档和 agent 调用约定。

数据获取类 skill 可额外包含 `datasets.yaml`，用于声明该 skill 可以获取或处理的数据集。`airmosaic list-datasets` 会同步读取这些文件，因此输出反映的是当前 `skills/data_acquisition/` 中可用的数据获取能力。

**data_acquisition/** —— 面向外部数据源的连接器，按四层 workflow 组织：

- **01 Socioeconomic**：WorldPop 人口网格、CSMAR 金融数据、工业年鉴提取
- **02 Emission Inventory**：排放因子数据、部门活动水平数据
- **03 Atmospheric Transport**：卫星反演浓度场、再分析产品
- **04 Impact**：IHME GBD 死亡率和疾病负担结果

**model/** —— 分析和建模方法，也按 workflow 层级组织：

- **01-04**：层级化模型方法，包括社会经济预测、排放编制、大气传输模拟、健康影响 PAF 计算
- **IAM/**：综合评估模型，例如 GCAM（情景配置解读、BaseX 输出结构探索、市场价格提取）

## 外部 Agent 接口

*正在开发中。* `src/airmosaic_core/services/` 服务层提供 Python SDK 和 CLI，供 Codex 或自定义 agent 调用，用于数据发现、本地缓存解析和本地因果设计模板生成。MCP 工具定义和 REST API 仍在规划中。

## 数据边界

本仓库**不含**：原始环境数据、API 密钥、模型运行结果。以上存放于 `$env:AIRMOSAIC_LOCAL_WORKSPACE`。

## Agent 集成

AirMosaic AI 被设计为可由 Codex 或其他外部 agent 读取和调用。详见 [AGENTS.md](AGENTS.md)，其中包含 agent 安装、skill 发现、数据边界和操作约定。

**Agent 快速启动：**

```powershell
$env:AIRMOSAIC_LOCAL_WORKSPACE = "D:\AirMosaicAI\local_workspace"
pip install -e .[dev]
airmosaic list-datasets
```

外部 agent 应从仓库根目录读取 `AGENTS.md`。每个 skill 通过 `agents/openai.yaml` 注册接口；运行 workflow 前应读取对应的 `SKILL.md`。

对于外部 agent，推荐流程是：打开仓库根目录，读取 `AGENTS.md`，检查相关 `SKILL.md`，调用 `airmosaic` CLI 完成 catalog/cache/template 类任务，然后由 agent 自身推理将返回的 JSON 扩展为完整分析计划。CLI 本身不会调用外部 LLM。

## License

Apache-2.0.
