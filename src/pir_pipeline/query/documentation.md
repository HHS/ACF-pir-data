# Query API

Retrieve Program Information Report (PIR) response records, optionally aggregated, as a downloadable JSON file.

---

## `POST /query`

Submits a query against the response data. The server looks up matching program and question records, joins them with response and agency data, optionally aggregates the results, and returns a download link to the resultant JSON file.

### Request

**Method:** `POST`
**Path:** `/query`
**Content-Type:** `application/json`

#### Body Structure

```json
{
  "aggregate_by": ["<field>", "..."],
  "program": {
    "<program_field>": ["<value>", "..."]
  },
  "question": [
    { "<question_field>": "<value>", "...": "..." }
  ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `aggregate_by` | `array[string]` | Yes | Field names to group results by. Pass `[]` to receive un-aggregated, record-level data. |
| `program` | `object` | Yes | Filters applied to the program table. Keys are program field names (see [Program Fields](#program-fields)); values are **arrays** of acceptable values for that field (an "IN" match — a record matches if its value for that field is any one of the array's entries). All keys are AND'd together. |
| `question` | `array[object]` | Yes | Filters applied to the question table. Each object is a set of field/value pairs (see [Question Fields](#question-fields)) that must **all** match (AND) to identify a question. Multiple objects in the array are combined with **OR** — a question matching *any* one of the objects is included. |

> **All three fields are required.** Omitting `program` or `question` from the request body will cause the request to fail, even if you don't want to filter on them.

#### Program Fields

Valid keys for the `program` filter object, corresponding to columns on the program table:

| Field | Type | Notes |
|---|---|---|
| `uid` | string | Program's unique identifier |
| `year` | integer | Reporting year |
| `grantee_name` | string | |
| `grant_number` | string | |
| `program_address_line_1` | string | |
| `program_address_line_2` | string | |
| `program_agency_description` | string | |
| `program_agency_type` | string | |
| `program_city` | string | |
| `program_email` | string | |
| `program_name` | string | |
| `program_number` | string | |
| `program_phone` | string | |
| `program_type` | string | |
| `program_state` | string | |
| `program_zip1` | string | |
| `program_zip2` | string | |
| `region` | integer | |

> `uid` and `year` together uniquely identify a program record, and are also the fields used to join against `response` — they're always valid filters even though they're excluded from the columns returned in program-related output fields.

#### Question Fields

Valid keys for objects in the `question` filter array, corresponding to columns on the question table:

| Field | Type | Notes |
|---|---|---|
| `question_id` | string | Question's unique identifier for a given year |
| `year` | integer | Used to disambiguate which question row to resolve when a field like `question_number` isn't unique across years. Does not restrict which years appear in the final output (see note below). |
| `uqid` | string | "Universal" question ID — links equivalent questions across years |
| `category` | string | |
| `question_name` | string | |
| `question_number` | string | |
| `question_order` | number | |
| `question_text` | string | |
| `question_type` | string | |
| `section` | string | |
| `subsection` | string | |

> **Fields in a `question` filter object identify a question — they do not filter the output.** Each object is used to look up a specific `question_id`/`uqid` pair. Once resolved, the API pulls **every row sharing that `uqid` or `question_id`, across all years**, regardless of what you specified inside the object (including `year`). The actual years present in your final results are controlled by your `program.year` filter (via the join to `response`), not by anything inside `question`. Because the API looks up questions by resolving each filter object to matching `question_id`/`uqid` values, filtering on `question_id` or `uqid` directly is the most precise way to target specific questions. Filtering on descriptive fields (e.g. `category`, `section`) will match every question satisfying those conditions.

#### How Filtering Works

- **`program`** filters use `column IN (...)`-style matching per field, AND'd across all supplied fields, and directly restrict which response records are included (via the join on `uid`/`year`).
- **`question`** filter objects are used purely to identify which question(s) you mean (via `question_id`/`uqid` lookup) — they are not applied as filters on the final result. Once a question is identified, all years associated with its `uqid`/`question_id` are eligible for the output; the effective year range is then narrowed by your `program` filter, not by the `question` object.
- The matched program and question records are joined against `response` (matched on `uid`/`year` and `question_id`/`year` respectively) and left-joined with agency data (matched on `grant_number`) to look up each program's `agency_id`.

#### Empty Filters

- `"question": []` — no question filters resolve to any matches, so the query returns no questions and therefore no responses (since responses are joined to questions). Always supply at least one filter object.
- `"program": {}` — no constraints are applied to the program lookup, i.e. all programs are eligible (before the join against matched questions/responses narrows things down).

#### Example Request — No Aggregation

```http
POST /query HTTP/1.1
Content-Type: application/json

{
  "aggregate_by": [],
  "program": {
    "year": [2024]
  },
  "question": [
    { "question_id": "Q101", "year": 2024 }
  ]
}
```

#### Example Request — With Aggregation, Multiple Question Filters

```http
POST /query HTTP/1.1
Content-Type: application/json

{
  "aggregate_by": ["grant_number", "program_type"],
  "program": {
    "year": [2024],
    "grant_number": ["G-1001", "G-1002"]
  },
  "question": [
    { "question_id": "Q101" },
    { "uqid": "UQ-77" }
  ]
}
```

This requests responses for program year 2024, limited to two grants, where the question matches **either** `question_id = "Q101"` **or** `uqid = "UQ-77"`.

---

### Aggregation Behavior

When `aggregate_by` is a non-empty list, the API groups records by the fields you specify **plus `uqid` and `year`, which the server always appends internally** — so your groups are never coarser than "one question, one year," even if you don't list those fields yourself. The API then computes one summary value per remaining field for each group, rather than returning individual records.

This matters in practice: if you filter on multiple distinct questions (e.g. by `question_number`) but only group by an unrelated field like `agency_id`, you will still get **separate rows per question** (and per year) within each `agency_id`, because `uqid`/`year` are silently part of every grouping. Fields like `question_number` or `question_text` will therefore be consistent within each group rather than an arbitrary pick across mixed questions — the `"first"` caveat below mainly matters for fields that can still vary *within* a single question/year/your-chosen-fields combination (e.g. `program_name` varying across multiple programs answering the same question in the same year, if you haven't grouped by a program-identifying field).

#### Aggregation Function per Field

| Field | Function | Notes |
|---|---|---|
| `answer` | **sum** | The only field that is numerically aggregated. Response values are summed across all records in the group. |
| All other fields (`category`, `question_name`, `question_number`, `question_order`, `question_text`, `question_type`, `section`, `subsection`, `grantee_name`, `grant_number`, `program_address_line_1`, `program_address_line_2`, `program_agency_description`, `program_agency_type`, `program_city`, `program_email`, `program_name`, `program_number`, `program_phone`, `program_type`, `program_state`, `program_zip1`, `program_zip2`, `region`) | **first** | Takes whichever value appears first within the group — it is **not** a true aggregate. |

> **Important:** Because non-`answer` fields use `"first"`, any such field you *don't* include in `aggregate_by` will show only one arbitrary value per group in the output — not a list, not a mode, not a guarantee of consistency. This is safe when the field is constant within a group (e.g. `program_name` for a single `grant_number`), but can be misleading if the field actually varies within the group (e.g. `question_text` when grouping only by `year`, across multiple distinct questions). Only trust a non-grouped field's value in the output if you know it's constant within the groups you've defined.

> **`agency_id` is a special case:** it is *not* listed in the aggregation spec table above at all (it has no "first"/"sum" rule). This means `agency_id` only appears in aggregated output when you explicitly include it in `aggregate_by` (as a grouping key) — it cannot be carried through as a "first"-value passenger column the way other program fields can. If you want `agency_id` in your aggregated results, group by it directly.

A few behaviors control **which** fields are even eligible for this "first" aggregation and appear in the output at all:

- **Grant-level detail:** Include `"grant_number"` or `"agency_id"` in `aggregate_by` if you want grant-related fields (including `grant_number` itself, taken via `"first"` if not grouped on) preserved in the aggregated output. If omitted, all grant-related fields are dropped entirely.
- **Program/agency-level detail:** Include a field starting with `"program"` (e.g. `program_type`, `program_number`), `"grant_number"`, or `"agency_id"` in `aggregate_by` if you want program- and agency-related fields preserved. If none of these are included, program- and agency-related fields are dropped entirely from the output.
- If `aggregate_by` is left empty, you get raw, un-aggregated records instead — every joined field is returned except the internal `question_id`, `uid`, and `uqid` identifiers, and `answer` is returned as the original per-record value rather than a sum.

In short: **the fields you group by determine (a) which columns survive into the output at all, and (b) which surviving columns are trustworthy** — grouped fields are exact; non-grouped survivors are just the first value seen, and `answer` alone is a true sum.

---

### Response

**Success Status:** `200 OK`
**Body:** A plain-text presigned URL (string).

```text
"https://your-bucket.s3.amazonaws.com/3f2a1c9e....json?X-Amz-Algorithm=...&X-Amz-Expires=10&..."
```

#### Using the Response

- Make an HTTP `GET` request to the returned URL to download your query results as a JSON file.
- **The URL expires in 10 seconds.** You must fetch it almost immediately after receiving the response — do not store it for later use.
- The downloaded file contains a JSON array of record objects, combining fields from `response`, `program`, `question`, and `agency_id`. Field names correspond to your `aggregate_by` selections (if aggregating) or the full joined record schema (if not).

#### Example Downloaded JSON (aggregated)

```json
[
  {
    "grant_number": "G-1001",
    "program_type": "Head Start",
    "year": 2024,
    "answer": 87.5
  },
  {
    "grant_number": "G-1002",
    "program_type": "Head Start",
    "year": 2024,
    "answer": 92.0
  }
]
```

#### Example Downloaded JSON (un-aggregated)

```json
[
  {
    "answer": "Yes",
    "year": 2024,
    "grant_number": "G-1001",
    "grantee_name": "Example Grantee",
    "program_type": "Head Start",
    "question_text": "Does the program have a written plan?",
    "agency_id": 5
  }
]
```

---

### Errors

| Condition | Behavior |
|---|---|
| `aggregate_by` missing from request body | Request fails (bad request). Always include this field, even as an empty array. |
| `program` or `question` missing from request body | Request fails (bad request). Both are required keys, even if their values are empty. |
| `question`/`program` filter entries reference a field not listed in [Program Fields](#program-fields) / [Question Fields](#question-fields) | Request fails (bad request/lookup error). |
| `question` is an empty array | Returns an empty result set (no questions resolve, so no responses join). |
| No matching records found | An empty dataset is uploaded and a valid (but empty) download URL is returned. |
| Cloud storage/network failure while generating the download link | Request fails with a server error. |

---

### Authentication

Requests must include an API key in the `x-api-key` header, alongside a JSON content type:

```
Content-Type: application/json
x-api-key: <your-api-key>
```

Store your key in an environment variable (e.g. `PIR_QUERY_API_KEY`) rather than hardcoding it in scripts.

---

### Full Example: Request → Download

This example identifies questions `C.50` and `C.51` (using their 2025 records to disambiguate the lookup, in case `question_number` isn't unique across years) and requests the `agency_id`-level aggregate `answer` sum across program years 2018–2025, then downloads the result to a local file. Since the presigned URL expires in 10 seconds, the download must happen immediately after the initial request returns.

> **Note:** The `year: 2025` inside each `question` object only identifies *which* `C.50`/`C.51` to resolve — it does not restrict the output to 2025. Because `program.year` spans 2018–2025, the results include every year in that range that the resolved `uqid`s appear in.

#### Python

```python
import json
import os
import requests

headers = {
    "content-type": "application/json",
    "x-api-key": os.getenv("PIR_QUERY_API_KEY"),
}

data = {
    "program": {"year": list(range(2018, 2026))},
    "question": [
        {"question_number": "C.50", "year": 2025},
        {"question_number": "C.51", "year": 2025},
    ],
    "aggregate_by": ["agency_id"],
}

# Step 1: submit the query, receive a presigned download URL
response = requests.post(
    "<url>",
    json=data,
    headers=headers,
)
response.raise_for_status()

# Step 2: immediately follow the presigned URL to fetch the JSON results
download = requests.get(response.text)
download.raise_for_status()

with open("temp.json", "w") as f:
    json.dump(download.json(), f, indent=2)
```

#### R

```r
library(httr)
library(jsonlite)

headers <- add_headers(
  "content-type" = "application/json",
  "x-api-key" = Sys.getenv("PIR_QUERY_API_KEY")
)

body <- list(
  program = list(year = 2018:2025),
  question = list(
    list(question_number = "C.50", year = 2025),
    list(question_number = "C.51", year = 2025)
  ),
  aggregate_by = list("agency_id")
)

# Step 1: submit the query, receive a presigned download URL
resp <- POST(
  "<url>",
  headers,
  body = toJSON(body, auto_unbox = TRUE),
  encode = "raw"
)
stop_for_status(resp)
download_url <- content(resp, as = "text", encoding = "UTF-8")

# Step 2: immediately follow the presigned URL to fetch the JSON results
download_resp <- GET(download_url)
stop_for_status(download_resp)
results <- fromJSON(content(download_resp, as = "text", encoding = "UTF-8"))

write_json(results, "temp.json", pretty = TRUE, auto_unbox = TRUE)
```

> **R note:** `auto_unbox = TRUE` prevents single-element vectors (like `question_number = "C.50"`) from being wrapped in JSON arrays where a scalar is expected. `aggregate_by` and each `question` filter entry are still valid JSON arrays because they're defined as R lists here.

#### Resulting `temp.json` (illustrative)

Because the server always appends `uqid` and `year` to `aggregate_by` internally, the actual grouping here is `["agency_id", "uqid", "year"]`. Note two things this reveals:

1. Questions C.50 and C.51 (different `uqid`s) produce separate rows per agency, each with `answer` summed only across responses to that specific question/year.
2. Since `year: 2025` inside the `question` objects only identified *which* C.50/C.51 to resolve — not a result filter — and `program.year` spans 2018–2025, rows appear for **every year in that range**, not just 2025:

```json
[
  {
    "agency_id": 5,
    "year": 2018,
    "question_number": "C.50",
    "answer": 130.0
  },
  {
    "agency_id": 5,
    "year": 2025,
    "question_number": "C.50",
    "answer": 142.0
  },
  {
    "agency_id": 5,
    "year": 2025,
    "question_number": "C.51",
    "answer": 76.0
  },
  {
    "agency_id": 7,
    "year": 2018,
    "question_number": "C.50",
    "answer": 81.0
  },
  {
    "agency_id": 7,
    "year": 2025,
    "question_number": "C.50",
    "answer": 88.0
  },
  {
    "agency_id": 7,
    "year": 2025,
    "question_number": "C.51",
    "answer": 63.0
  }
]
```

> Rows are shown for 2018 and 2025 only for brevity — in practice, any year between 2018–2025 where the linked `uqid` has responses would appear. If you want results restricted to a single year, add that constraint to `program.year` (e.g. `"year": [2025]`) rather than relying on `question.year`.

---

### Notes for Integrators

- **Fetch the download URL immediately.** Its 10-second expiry means it should be requested right after the `POST /query` call completes — don't queue it or delay.
- **`program` and `question` filters serve different purposes:** `program` filters directly restrict which response records are included (via `IN`-per-field/AND-across-fields). `question` filters only *identify* which question(s) you mean (AND within an object, OR across the array) — they do not restrict the year range or otherwise filter the joined output.
- **`year` inside a `question` object is not a result filter.** It only disambiguates the lookup when other fields (like `question_number`) aren't unique across years. To restrict which years appear in your results, use `program.year`.
- **Prefer `question_id`/`uqid` for question filters** when you know exactly which question(s) you want — other fields (`category`, `section`, etc.) will match every question satisfying that condition, which may be broader than intended.
- **Empty `aggregate_by` returns raw, joined records**, which can be considerably larger than aggregated results — plan for larger payloads if you omit grouping.
- **Choose `aggregate_by` fields deliberately**, since they control both how data is grouped *and* which summary fields are included in the response (see [Aggregation Behavior](#aggregation-behavior)).
- **`uid` and `year`** are valid `program` filter fields even though they aren't part of the joined output columns from the program table (they're used for the join to `response` instead). Likewise, `question_id` and `year` are valid `question` filter fields despite the same exclusion on the question side.