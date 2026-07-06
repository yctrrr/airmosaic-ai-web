const i18n = {
  en: {
    nav_platform: "Platform",
    nav_skills: "Skills",
    nav_services: "Services",
    nav_agent: "Agent",
    hero_title: "Atmospheric Environment Decision Intelligence",
    hero_subtitle: "A locally deployed analysis platform integrating AI agents, multimodal data acquisition, model analysis, and causal inference.",
    hero_desc: "AirMosaic AI provides standardized tools for external AI agents and local research scripts. No data is bundled in the repository.",
    platform_title: "Local Deployment Architecture",
    arch_core_label: "airmosaic-ai-core",
    arch_core: "Skills, services, catalog metadata, interfaces — committed to GitHub.",
    arch_workspace_label: "local_workspace",
    arch_workspace: "Raw data, model releases, credentials, run outputs — local only.",
    arch_agent_label: "External Agent",
    arch_agent: "Codex, Claude, or custom scripts call services via MCP / REST / CLI.",
    skills_title: "Platform Skills",
    skill_worldpop: "Population grid data by country and year, with clipping and validation.",
    skill_gbd: "Mortality rates, disease burden parameters from IHME GBD.",
    skill_gcam: "Explore BaseX output structure, interpret configuration files, extract prices, quantities, and technology components via XQuery.",
    services_title: "Service Layer",
    svc_catalog_label: "Data Catalog",
    svc_catalog: "List datasets, variables, spatial-temporal coverage, and access methods.",
    svc_access_label: "Data Access",
    svc_access: "Check local cache availability, report missing data, and resolve paths.",
    svc_causal_label: "Causal Design",
    svc_causal: "Generate structured causal analysis plans: treatment, outcome, confounders, identification strategy, and refutation tests.",
    agent_title: "External Agent Interface",
    agent_desc: "Agents do not read files directly. All data access goes through service interfaces:",
    agent_mcp_label: "MCP Tools",
    agent_mcp: "Fine-grained function calls returning structured JSON for Codex, Claude, and other MCP-compatible agents.",
    agent_rest_label: "REST / OpenAPI",
    agent_rest: "Standard HTTP API for web frontends and non-MCP services.",
    agent_cli_label: "Python SDK / CLI",
    agent_cli: "Local scripting, Jupyter notebooks, and batch processing."
  },
  zh: {
    nav_platform: "平台架构",
    nav_skills: "技能模块",
    nav_services: "服务层",
    nav_agent: "Agent接入",
    hero_title: "大气环境决策智能分析平台",
    hero_subtitle: "本地化部署，集成AI Agent、多模态数据获取、模型分析与因果推断。",
    hero_desc: "AirMosaic AI 为外部 AI Agent 和本地科研脚本提供标准化工具。仓库不含原始数据，所有能力按需获取。",
    platform_title: "本地部署架构",
    arch_core_label: "airmosaic-ai-core",
    arch_core: "Skills、服务、目录元数据、接口定义——上传至 GitHub。",
    arch_workspace_label: "local_workspace",
    arch_workspace: "原始数据、模型发行包、密钥、运行结果——仅本地存储。",
    arch_agent_label: "外部 Agent",
    arch_agent: "Codex、Claude 或自定义脚本通过 MCP / REST / CLI 调用服务。",
    skills_title: "平台技能模块",
    skill_worldpop: "按国家、年份下载人口网格数据，支持裁切和校验。",
    skill_gbd: "从 IHME GBD 获取死亡率、疾病负担参数。",
    skill_gcam: "探索 BaseX 输出结构，解读配置文件，通过参数化 XQuery 提取价格、产量和技术组分。",
    services_title: "服务层",
    svc_catalog_label: "数据目录",
    svc_catalog: "列出数据集、变量、时空覆盖范围和获取方式。",
    svc_access_label: "数据访问",
    svc_access: "检查本地缓存状态，报告缺失数据，解析文件路径。",
    svc_causal_label: "因果设计",
    svc_causal: "生成结构化因果分析方案：treatment、outcome、confounders、识别策略和稳健性检验。",
    agent_title: "外部 Agent 接入",
    agent_desc: "Agent 不直接访问文件系统，所有数据读写通过服务接口完成：",
    agent_mcp_label: "MCP 工具",
    agent_mcp: "细粒度函数调用，返回结构化 JSON，适配 Codex、Claude 等 MCP 兼容 Agent。",
    agent_rest_label: "REST / OpenAPI",
    agent_rest: "标准 HTTP API，供网站前端和非 MCP 服务调用。",
    agent_cli_label: "Python SDK / CLI",
    agent_cli: "本地科研脚本、Jupyter Notebook 和批处理任务。"
  }
};

let currentLang = "en";

function setLang(lang) {
  currentLang = lang;
  document.documentElement.lang = lang;
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.getAttribute("data-i18n");
    if (i18n[lang] && i18n[lang][key]) {
      el.textContent = i18n[lang][key];
    }
  });
  document.querySelectorAll(".lang-option").forEach(opt => {
    opt.classList.toggle("active", opt.getAttribute("data-lang") === lang);
  });
}

document.getElementById("langToggle").addEventListener("click", () => {
  setLang(currentLang === "en" ? "zh" : "en");
});

setLang("en");
