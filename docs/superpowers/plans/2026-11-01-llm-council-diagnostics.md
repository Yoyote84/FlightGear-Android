# LLM Council diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a CI-only multi-LLM diagnostic adapter that analyzes failed native Android builds using the LLM Council pattern.

**Architecture:** Keep FlightGear untouched at runtime. GitHub Actions captures a failed Gradle/CMake log and invokes a small Python adapter that calls OpenRouter in three stages: independent diagnoses, anonymized cross-review, and chairman synthesis. The report is uploaded as an artifact and never drives source changes automatically.

**Tech Stack:** Python 3.10+ standard library, OpenRouter HTTP API, GitHub Actions, Markdown artifacts.

**Spec:** `docs/superpowers/specs/2026-11-01-llm-council-diagnostics.md`

## Global Constraints

- No LLM dependency is added to the Android APK.
- No Box64, emulation, streaming, or FlightGear replacement is introduced.
- The diagnostic path is advisory and never edits or merges code automatically.
- The API key is read only from `OPENROUTER_API_KEY`.
- Build logs sent to the API are truncated to a bounded size.

## Review Focus

- Missing API key must skip diagnostics instead of failing the Android build.
- HTTP/API failures must produce a useful diagnostic error without leaking secrets.
- Empty or very large build logs must remain bounded and valid Markdown.
- Malformed model responses must not crash the report generation.
- The diagnostic step must run after a failed build while preserving the original build failure.

### Task 1: Council adapter

**Files:**
- Create: `tools/llm-council/council.py`
- Create: `tools/llm-council/README.md`

**Interfaces:**
- CLI: `python3 tools/llm-council/council.py --log <path> --output <path>`
- Environment: `OPENROUTER_API_KEY`, optional `COUNCIL_MODELS`, `COUNCIL_CHAIRMAN_MODEL`.

- [ ] Implement bounded log loading and deterministic prompt construction.
- [ ] Implement OpenRouter requests with timeouts and explicit error handling.
- [ ] Implement stage 1 independent diagnoses.
- [ ] Implement stage 2 anonymized ranking/review.
- [ ] Implement stage 3 chairman synthesis.
- [ ] Implement Markdown report generation and secret-safe error messages.
- [ ] Run a local self-test mode for prompt/report formatting.
- [ ] Commit.

### Task 2: GitHub Actions integration

**Files:**
- Modify: `.github/workflows/android.yml`

**Interfaces:**
- Build step writes `build.log` while preserving its exit code.
- Diagnostic step runs only after build failure and only when `OPENROUTER_API_KEY` exists.
- Report is uploaded as `FlightGear-Android-llm-council-report`.

- [ ] Capture Gradle output with `tee` and preserve failure status.
- [ ] Add diagnostic step after the build with `if: failure()`.
- [ ] Upload the report even when diagnostics fail, without masking the build result.
- [ ] Commit.

### Task 3: Verification

**Files:**
- Verify: new adapter and workflow.

- [ ] Run `python3 tools/llm-council/council.py --self-test`.
- [ ] Validate workflow YAML structure using a local parser available on the runner, or a focused text check when no YAML parser is available.
- [ ] Trigger/inspect GitHub Actions and confirm the diagnostic step is present after the build step.
- [ ] Record any remaining build blocker separately from the Council integration.
