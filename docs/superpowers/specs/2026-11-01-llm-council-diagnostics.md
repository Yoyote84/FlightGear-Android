# LLM Council diagnostics for FlightGear Android

## Goal
Use Karpathy's `llm-council` approach as an external CI diagnostic assistant for native FlightGear Android builds, without adding any LLM dependency to the APK.

## Scope
- Run only after the Android build fails.
- Capture the build log and a small amount of repository context.
- Send the failure to several independent models through OpenRouter.
- Ask the models to critique anonymized candidate diagnoses.
- Ask a chairman model to synthesize a ranked diagnosis and concrete next steps.
- Upload the resulting Markdown report as a GitHub Actions artifact.

## Non-goals
- No LLM runtime in FlightGear Android.
- No Box64, emulation, streaming, or replacement of the native build.
- No automatic source modification or automatic merge based on model output.
- No secrets in repository files or artifacts.

## Safety and cost
- The diagnostic job is skipped when `OPENROUTER_API_KEY` is unavailable.
- Model output is advisory only and never changes the build automatically.
- Build logs are truncated before being sent to the API to bound token/cost usage.
- The default council uses three models plus one chairman and can be overridden with environment variables.

## Integration
`tools/llm-council/council.py` is a small CI adapter inspired by the upstream project at `https://github.com/karpathy/llm-council`. It uses the same three-stage pattern but talks directly to OpenRouter so CI does not need to start the local web application.

## Expected result
A failed build produces `llm-council-report.md` containing:
1. the normalized failure signal;
2. independent diagnoses;
3. cross-review/ranking;
4. chairman synthesis;
5. suggested next debugging actions.
