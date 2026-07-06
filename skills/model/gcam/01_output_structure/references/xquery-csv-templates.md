# Reusable XQuery CSV Templates

These templates produce CSV output from GCAM BaseX databases. They are designed to be parameterized by scenario, region, sector, and year lists.

## Getting CSV Output from BaseX

BaseX can output CSV directly with the `-smethod=csv` flag:

```bash
java -cp <classpath> -Dorg.basex.DBPATH=<db_path> \
  org.basex.BaseX -smethod=csv -scsv=header=yes \
  -o output.csv -i database_basexdb \
  RUN query.xq
```

Within XQuery, use `document { element csv { ... } }` to structure CSV records.

## Template 1: List All Sectors in a Region

```xquery
for $s in collection()/scenario
for $sec in $s/world/*[@type="region" and @name="AH"]/*[@type="sector"]
return concat($s/@name, ",", $sec/@name)
```

## Template 2: Sector Physical Output Table

```xquery
document { element csv {
  for $s in collection()/scenario
  for $r in $s/world/*[@type="region" and @name=("AH","BJ")]
  for $sec in $r/*[@type="sector" and @name="cement"]
  for $out in $sec//output-primary/physical-output
  return element record {
    element scenario { string($s/@name) },
    element region { string($r/@name) },
    element sector { string($sec/@name) },
    element year { string($out/@vintage) },
    element unit { string($out/@unit) },
    element value { string($out/text()) }
  }
} }
```

## Template 3: Sector Price/Cost Table

```xquery
document { element csv {
  for $s in collection()/scenario
  for $r in $s/world/*[@type="region" and @name=("AH","BJ")]
  for $sec in $r/*[@type="sector" and @name="cement"]
  for $cost in $sec/cost
  return element record {
    element scenario { string($s/@name) },
    element region { string($r/@name) },
    element sector { string($sec/@name) },
    element year { string($cost/@year) },
    element unit { string($cost/@unit) },
    element value { string($cost/text()) }
  }
} }
```

## Template 4: Technology Input Demand Table

```xquery
document { element csv {
  for $s in collection()/scenario
  for $r in $s/world/*[@type="region" and @name="AH"]
  for $sec in $r/*[@type="sector" and @name="cement"]
  for $input in $sec//input
  for $demand in $input/demand-physical
  return element record {
    element scenario { string($s/@name) },
    element region { string($r/@name) },
    element sector { string($sec/@name) },
    element input { string($input/@name) },
    element year { string($demand/@vintage) },
    element unit { string($demand/@unit) },
    element value { string($demand/text()) }
  }
} }
```

## Template 5: List All Scenarios

```xquery
document { element csv {
  for $s in collection()/scenario
  return element record {
    element scenario { string($s/@name) },
    element date { string($s/@date) },
    element model_version { string($s/model-version/text()) },
    element top_child_types { string-join(distinct-values($s/world/*/@type), ";") }
  }
} }
```

## Template 6: Technology Tree for a Sector

```xquery
document { element csv {
  for $s in collection()/scenario
  for $r in $s/world/*[@type="region" and @name=("AH")]
  for $sec in $r/*[@type="sector" and @name="cement"]
  for $sub in $sec/*[@type="subsector"]
  for $tech in $sub/*[@type="technology"]
  let $outputs := string-join(distinct-values($tech/*[@type="output"]/@name), ";")
  let $inputs := string-join(distinct-values($tech/*[@type="input"]/@name), ";")
  let $output_units := string-join(distinct-values($tech/*[@type="output"]/physical-output/@unit), ";")
  let $years := string-join(distinct-values($tech/*[@type="output"]/physical-output/@vintage), ";")
  return element record {
    element scenario { string($s/@name) },
    element region { string($r/@name) },
    element sector { string($sec/@name) },
    element subsector { string($sub/@name) },
    element technology { string($tech/@name) },
    element outputs { $outputs },
    element inputs { $inputs },
    element output_units { $output_units },
    element output_years { $years }
  }
} }
```

## Template 7: Sector Cost Node Inventory

```xquery
document { element csv {
  for $s in collection()/scenario
  for $r in $s/world/*[@type="region" and @name=("AH")]
  for $sec in $r/*[@type="sector"]
  return element record {
    element scenario { string($s/@name) },
    element region { string($r/@name) },
    element sector { string($sec/@name) },
    element sector_cost_years { string-join(distinct-values($sec/cost/@year), ";") },
    element sector_cost_units { string-join(distinct-values($sec/cost/@unit), ";") },
    element sector_cost_count { count($sec/cost) },
    element physical_output_count { count($sec//physical-output) },
    element input_demand_count { count($sec//demand-physical) }
  }
} }
```
