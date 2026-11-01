#!/usr/bin/env python3
"""CI adapter for a small LLM Council-style build diagnosis.

Inspired by https://github.com/karpathy/llm-council but intentionally kept
as a dependency-free CI utility instead of embedding the web application.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_MODELS = [
    "openai/gpt-5.1",
    "google/gemini-3-pro-preview",
    "anthropic/claude-sonnet-4.5",
]
DEFAULT_CHAIRMAN = "google/gemini-3-pro-preview"
MAX_LOG_CHARS = 60000
MAX_RESPONSE_CHARS = 14000
API_URL = "https://openrouter.ai/api/v1/chat/completions"


def bounded(text: str, limit: int = MAX_LOG_CHARS) -> str:
    if len(text) <= limit:
        return text
    head = limit // 3
    tail = limit - head
    return text[:head] + "\n\n...[TRUNCATED]...\n\n" + text[-tail:]


def load_log(path: Path) -> str:
    return bounded(path.read_text(encoding="utf-8", errors="replace"))


def normalize_error(log: str) -> str:
    patterns = [
        r"(?im)^.*(?:error:|fatal error:|FAILED:|FAILURE:|Execution failed).*$",
        r"(?im)^.*(?:ninja: build stopped|BUILD FAILED).*$",
    ]
    hits: list[str] = []
    for pattern in patterns:
        hits.extend(re.findall(pattern, log))
    seen: set[str] = set()
    unique = []
    for hit in hits:
        hit = hit.strip()
        if hit and hit not in seen:
            seen.add(hit)
            unique.append(hit)
    return "\n".join(unique[:40]) or "No canonical error line extracted; inspect the bounded build log."


def models_from_env() -> list[str]:
    raw = os.environ.get("COUNCIL_MODELS", "")
    models = [m.strip() for m in raw.split(",") if m.strip()] if raw else DEFAULT_MODELS
    return models[:5]


def request_model(api_key: str, model: str, prompt: str, timeout: int = 90) -> str:
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a senior C++/Android NDK build engineer. Be concrete, evidence-driven, and conservative."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.1,
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://github.com/Yoyote84/FlightGear-Android",
            "X-Title": "FlightGear Android LLM Council",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
        content = data["choices"][0]["message"]["content"]
        return bounded(str(content), MAX_RESPONSE_CHARS)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, KeyError, IndexError, json.JSONDecodeError) as exc:
        return f"MODEL_ERROR: {type(exc).__name__}: {str(exc)[:300]}"


def stage_one(log: str, models: list[str]) -> list[tuple[str, str]]:
    context = normalize_error(log)
    prompt = f"""Analyze this failed FlightGear Android ARM64 native build.

Canonical error signals:
{context}

Bounded build log:
{log}

Give one diagnosis with:
1. root cause;
2. why the current Android/OSG/SimGear setup triggers it;
3. smallest safe source or build-system correction;
4. how to verify the correction.
Do not suggest emulation or replacing FlightGear."""
    return [(model, request_model(os.environ["OPENROUTER_API_KEY"], model, prompt)) for model in models]


def stage_two(log: str, opinions: list[tuple[str, str]]) -> str:
    candidates = "\n\n".join(f"Candidate {i + 1}:\n{answer}" for i, (_, answer) in enumerate(opinions))
    prompt = f"""Review anonymized candidate diagnoses for a native FlightGear Android build failure.

Failure signal:
{normalize_error(log)}

Candidates:
{candidates}

Rank the candidates for technical correctness and minimal scope. Identify false assumptions, especially around OpenSceneGraph desktop-vs-GLES compatibility. Return a ranked list and explain the evidence."""
    return request_model(os.environ["OPENROUTER_API_KEY"], os.environ.get("COUNCIL_REVIEW_MODEL", models_from_env()[0]), prompt)


def stage_three(log: str, opinions: list[tuple[str, str]], review: str) -> str:
    opinions_text = "\n\n".join(f"Opinion {i + 1}:\n{answer}" for i, (_, answer) in enumerate(opinions))
    prompt = f"""Act as the chairman of a technical review council. Synthesize a single actionable diagnosis for the failed native FlightGear Android build.

Failure signal:
{normalize_error(log)}

Independent opinions:
{opinions_text}

Cross-review:
{review}

Produce:
- Verdict
- Evidence
- Recommended minimal change
- Verification command/check
- What NOT to change yet
Never recommend Box64, emulation, streaming, or a FlightGear rewrite."""
    return request_model(os.environ["OPENROUTER_API_KEY"], os.environ.get("COUNCIL_CHAIRMAN_MODEL", DEFAULT_CHAIRMAN), prompt)


def render_report(log: str, opinions: list[tuple[str, str]], review: str, chairman: str) -> str:
    lines = [
        "# FlightGear Android — LLM Council diagnostic",
        "",
        "> Advisory analysis only. No source changes are made automatically.",
        "",
        "## Failure signal",
        "",
        "```text",
        normalize_error(log),
        "```",
        "",
        "## Stage 1 — independent diagnoses",
    ]
    for i, (model, answer) in enumerate(opinions, 1):
        lines += ["", f"### Candidate {i} — `{model}`", "", answer]
    lines += ["", "## Stage 2 — cross-review", "", review, "", "## Stage 3 — chairman", "", chairman, ""]
    return "\n".join(lines)


def self_test() -> int:
    sample = """[1/866] Building CXX object foo.o\nerror: use of undeclared identifier 'GL_AMBIENT'\nninja: build stopped: subcommand failed.\nBUILD FAILED"""
    assert "GL_AMBIENT" in normalize_error(sample)
    assert len(bounded("x" * 100, 20)) <= 60
    print("LLM Council self-test: OK")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", type=Path)
    parser.add_argument("--output", type=Path, default=Path("llm-council-report.md"))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if not args.log:
        parser.error("--log is required unless --self-test is used")
    if not os.environ.get("OPENROUTER_API_KEY"):
        print("OPENROUTER_API_KEY is not configured; skipping LLM Council diagnostics.")
        return 0

    log = load_log(args.log)
    models = models_from_env()
    opinions = stage_one(log, models)
    review = stage_two(log, opinions)
    chairman = stage_three(log, opinions, review)
    args.output.write_text(render_report(log, opinions, review, chairman), encoding="utf-8")
    print(f"LLM Council report written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
