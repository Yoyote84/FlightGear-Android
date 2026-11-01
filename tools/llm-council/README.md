# LLM Council CI adapter

This directory contains the FlightGear Android CI adapter inspired by Karpathy's [`llm-council`](https://github.com/karpathy/llm-council).

It is deliberately **not** part of the Android application. It runs on GitHub Actions only when the native build fails.

## Usage

```bash
python3 tools/llm-council/council.py --self-test
python3 tools/llm-council/council.py --log build.log --output llm-council-report.md
```

The second command requires `OPENROUTER_API_KEY`.

Optional environment variables:

- `COUNCIL_MODELS`: comma-separated model IDs for independent diagnoses.
- `COUNCIL_REVIEW_MODEL`: model used for cross-review.
- `COUNCIL_CHAIRMAN_MODEL`: final synthesis model.

The adapter follows the upstream project's three-stage idea: independent opinions, peer review/ranking, then a chairman synthesis. It adds FlightGear-specific constraints so the council does not recommend Box64/emulation or a rewrite.
