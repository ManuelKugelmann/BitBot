
# Feature: DevContainer Configuration & VS Code Integration

## Research References
- Research/container-dev-environment-research.md (lines 1-51)
- Claude_info.txt:402-436 (VS Code integration)
- Legacy_devcontainer_samples/* (composable setup scripts)

## Feature Description
BitBot provides a devcontainer that is:
- Fully compatible with VS Code (detectable, attachable, supports lifecycle hooks)
- Configurable for different tech stacks and safety policies
- Composable via setup scripts, inspired by legacy_devcontainers
- Built as a fixed container image, with runtime behavior steered by arguments and environment variables

## Implementation Approach
- Use a **single devcontainer.json template** for all stacks.
- Compose setup scripts (e.g., install-language.sh, setup-mcp.sh) at container build and runtime, following patterns from legacy_devcontainer_samples.
- The container image is fixed; runtime stack selection and safety policy are handled via environment variables and startup scripts.
- All protection is via git push or bundle backup, not container modes.
- Users can customize tech stack and features by providing runtime args/env or by extending setup scripts.
- VS Code integration is ensured by setting correct labels and supporting lifecycle hooks (postCreateCommand, postStartCommand, etc.).

## Rationale
- Composable setup scripts allow flexible, maintainable configuration without rebuilding the container for every change.
- Fixed container image simplifies updates and compatibility.
- Runtime args/env provide dynamic behavior for different stacks and safety policies.
- Aligns with best practices from legacy_devcontainer_samples and modern container development.
