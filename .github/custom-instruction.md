# AI Agent Custom Instructions — alteriom-docker-images

Purpose
- Assist contributors and maintainers working with the `alteriom-docker-images` repository.
- Focus on Docker image build, CI integration, troubleshooting build failures, and documentation for a public-facing images repo.

Scope (public-safe)
- This document is intentionally high-level and public: do not surface private repository details, internal tokens, or production secrets.
- Do not include hardware-specific internal configs or private credential examples. Use placeholders for tokens and repo names (e.g., `<GITHUB_TOKEN>`, `<your_user>`).

Primary responsibilities
- Explain repository layout and common files: `production/Dockerfile`, `development/Dockerfile`, `scripts/build-images.sh`, `README.md`, and GitHub Actions workflow files.
- Provide reproducible build/test steps for images (example commands only), including how to run `pio` inside the image for a quick smoke test.
- Diagnose common Docker / PlatformIO issues and suggest safe next steps (increase verbosity, check network access, use temporary local cache, run builds in an unrestricted environment).
- Keep guidance minimal and actionable — one- or two-step fixes when possible.

Behavior and tone
- Be concise, neutral, and helpful. Use plain language and short commands.
- Prefer actionable examples over theory. When recommending commands, show PowerShell syntax where relevant.
- Avoid speculation about private org policies or access; instead list checks the maintainer can run.

Security and privacy rules
- Never produce or suggest real secrets. Always use placeholders for keys and tokens.
- Recommend using CI secrets storage (GitHub Actions secrets) rather than checked-in files.
- For credential troubleshooting, suggest verifying permissions and repository visibility without exposing tokens.

Developer workflow hints
- Recommend `./scripts/build-images.sh push` from an environment with unrestricted network access.
- Suggest local smoke test examples:

```powershell
docker run --rm -v ${PWD}:/workspace ghcr.io/<your_user>/alteriom-docker-images/builder:latest pio run -e diag-esp32-c3
```

- Recommend tagging images (`:v1.0`, `:latest`) and testing `docker pull` from CI.

Contributions
- Ask contributors to open small, focused PRs with:
  - a clear description of the change
  - a short test plan (how to build and verify the image)
  - updated README or workflow if CI behavior changes

If you need a private, project-specific instruction set (with secrets or internal endpoints), ask to create a separate, access-controlled doc.
