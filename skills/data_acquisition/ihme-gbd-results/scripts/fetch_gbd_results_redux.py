from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import pandas as pd
import requests
import websocket


INSTALL_STORE_JS = r"""
(() => {
  if (window.__gbdStore) return "already";
  function findStoreFromFiber(fiber, seen = new Set()) {
    if (!fiber || seen.has(fiber)) return null;
    seen.add(fiber);
    const props = fiber.memoizedProps || fiber.pendingProps || {};
    if (props && props.store && typeof props.store.getState === "function") return props.store;
    const stateNode = fiber.stateNode;
    if (stateNode && stateNode.props && stateNode.props.store && typeof stateNode.props.store.getState === "function") {
      return stateNode.props.store;
    }
    return findStoreFromFiber(fiber.child, seen) || findStoreFromFiber(fiber.sibling, seen) || findStoreFromFiber(fiber.return, seen);
  }
  for (const el of document.querySelectorAll("*")) {
    const key = Object.keys(el).find((k) => k.startsWith("__reactFiber$") || k.startsWith("__reactInternalInstance$"));
    if (!key) continue;
    const store = findStoreFromFiber(el[key]);
    if (store) {
      window.__gbdStore = store;
      return "found";
    }
  }
  return "not_found";
})()
"""


def csv_ints(value: str) -> list[int]:
    return [int(item.strip()) for item in value.split(",") if item.strip()]


def get_tab(port: int) -> dict[str, Any]:
    tabs = requests.get(f"http://127.0.0.1:{port}/json/list", timeout=10).json()
    for tab in tabs:
        if tab.get("type") == "page" and "vizhub.healthdata.org/gbd-results" in tab.get("url", ""):
            return tab
    raise RuntimeError("GBD Results tab not found. Open https://vizhub.healthdata.org/gbd-results/ first.")


class CDP:
    def __init__(self, ws_url: str) -> None:
        self.ws = websocket.create_connection(ws_url, timeout=300)
        self.seq = 0

    def eval(self, expression: str, timeout_ms: int = 300000) -> Any:
        self.seq += 1
        self.ws.send(json.dumps({
            "id": self.seq,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "awaitPromise": True,
                "returnByValue": True,
                "timeout": timeout_ms,
            },
        }))
        while True:
            response = json.loads(self.ws.recv())
            if response.get("id") == self.seq:
                result = response.get("result", {})
                if "exceptionDetails" in result:
                    raise RuntimeError(json.dumps(result["exceptionDetails"], ensure_ascii=False))
                return result.get("result", {}).get("value")

    def close(self) -> None:
        self.ws.close()


def build_search_js(params: dict[str, Any], wait_ms: int) -> str:
    return f"""
    (async () => {{
      const store = window.__gbdStore;
      if (!store) return JSON.stringify({{ok: false, error: "store_not_found"}});
      const params = {json.dumps(params)};
      const beforeData = store.getState().app.data;
      const dispatch = store.dispatch;
      const setParam = (key, value) => dispatch({{type: "CHANGE_PARAMETER", payload: {{key, value}}}});

      dispatch({{type: "CHANGE_BASE", payload: {{key: "base", value: "single"}}}});
      for (const [key, value] of Object.entries(params)) {{
        if (key === "base") dispatch({{type: "CHANGE_BASE", payload: {{key: "base", value}}}});
        else setParam(key, value);
      }}
      dispatch({{type: "CHANGE_ACTIVE_VIEW", payload: {{view: "table"}}}});
      dispatch({{type: "EXECUTE_SEARCH"}});

      const started = Date.now();
      let sawNewData = false;
      while (Date.now() - started < {wait_ms}) {{
        const state = store.getState().app;
        const data = state.data;
        if (data !== beforeData) sawNewData = true;
        if (!state.loading && (sawNewData || state.error)) {{
          const rows = data && data.tableData ? data.tableData.length : 0;
          return JSON.stringify({{ok: !state.error, error: state.error, rows, data, parameters: state.parameters}});
        }}
        await new Promise((resolve) => setTimeout(resolve, 500));
      }}
      const state = store.getState().app;
      const data = state.data;
      const rows = data && data.tableData ? data.tableData.length : 0;
      return JSON.stringify({{ok: false, error: "timeout", rows, data, parameters: state.parameters}});
    }})()
    """


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch IHME GBD Results tableData through the logged-in web UI.")
    parser.add_argument("--out", required=True, help="Output CSV path.")
    parser.add_argument("--port", type=int, default=9222, help="Chrome remote debugging port.")
    parser.add_argument("--version", type=int, default=8352, help="GBD version ID.")
    parser.add_argument("--context", default="cause")
    parser.add_argument("--population-group", type=int, default=1)
    parser.add_argument("--years", required=True, type=csv_ints)
    parser.add_argument("--locations", required=True, type=csv_ints)
    parser.add_argument("--causes", required=True, type=csv_ints)
    parser.add_argument("--ages", required=True, type=csv_ints)
    parser.add_argument("--sexes", required=True, type=csv_ints)
    parser.add_argument("--measures", required=True, type=csv_ints)
    parser.add_argument("--metrics", required=True, type=csv_ints)
    parser.add_argument("--wait-ms", type=int, default=300000)
    args = parser.parse_args()

    params = {
        "year": args.years,
        "context": args.context,
        "population_group": args.population_group,
        "cause": args.causes,
        "measure": args.measures,
        "metric": args.metrics,
        "location": args.locations,
        "age": args.ages,
        "sex": args.sexes,
        "base": "single",
        "version": args.version,
    }

    cdp = CDP(get_tab(args.port)["webSocketDebuggerUrl"])
    try:
        store_status = cdp.eval(INSTALL_STORE_JS)
        if store_status not in {"already", "found"}:
            raise RuntimeError(f"Could not find GBD Redux store: {store_status}")
        result = json.loads(cdp.eval(build_search_js(params, args.wait_ms), timeout_ms=args.wait_ms + 60000))
    finally:
        cdp.close()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    sidecar = out.with_suffix(out.suffix + ".json")
    sidecar.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    if result.get("error"):
        raise RuntimeError(f"GBD search returned error: {result.get('error')} (sidecar: {sidecar})")

    rows = result.get("data", {}).get("tableData", [])
    pd.DataFrame(rows).to_csv(out, index=False, encoding="utf-8-sig")
    print(json.dumps({"out": str(out), "sidecar": str(sidecar), "rows": len(rows)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
