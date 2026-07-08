# Workflow Layer — Analysis Pipeline Templates

预定义的四层大气环境决策分析流水线。每一层定义输入、处理模块、AI/经验分支逻辑和输出规格。

Four-layer atmospheric-environment decision analysis pipeline. Each layer defines inputs, processing modules, AI/empirical branching logic, and output specifications.

---

## Layer Overview

```
Layer 1: Socioeconomic Driver
  宏观经济/微观经济 → 活动水平 → 能源使用 → 末端治理技术
  ↓
Layer 2: Emission Inventory
  社会经济变量 → 污染物排放 → 碳排放变化
  ↓
Layer 3: Atmospheric Transport & Chemistry
  Emission → Transport → Chemistry → Deposition → Concentration
  ↓
Layer 4: Socioeconomic Impact
  浓度/排放 → 健康损失 → 碳社会成本 → 不平等效应
```

## Data Volume Branching

每个模块根据数据量自动选择执行路径：

- **数据充足** → Transformer / AI module 建模，优化因果效应识别
- **数据不足** → 经验公式 / 人工修正

## Template Files

| Layer | File | Description |
|-------|------|-------------|
| 1 | `layers/01_socioeconomic.yaml` | Socioeconomic driver template |
| 2 | `layers/02_emission_inventory.yaml` | Emission inventory template |
| 3 | `layers/03_atmospheric_transport.yaml` | Atmospheric chemistry transport template |
| 4 | `layers/04_socioeconomic_impact.yaml` | Impact assessment template |

## Usage

Agent calls the workflow orchestrator with a research question:

```python
from workflow import WorkflowOrchestrator

orchestrator = WorkflowOrchestrator()
result = orchestrator.run(
    question="评估2030年碳达峰政策对京津冀PM2.5浓度和居民健康的影响",
    layers=[1, 2, 3, 4],
    spatial_scope="Beijing-Tianjin-Hebei",
    temporal_scope={"start": 2020, "end": 2035}
)
```

## Traceability

See `references/io_traceability.md` for full I/O contract and causal traceability design.
