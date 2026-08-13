# docs/ — AI resource workspace

**Scaffold target:** project root `docs/README.md` (outside `kit/`).  
**Policy:** [kit/rules/ai-docs-workspace.md](../../rules/ai-docs-workspace.md)  
**Templates:** copy module folders from `kit/templates/docs/` into project `docs/` as needed.

---

## Purpose

This tree is a **resource for AI** (and humans) maintaining the repository: research, detailed plans, project build context, and curated resources. It is **not** kit standards and **not** the canonical home for public product contracts.

| Module | Path | Enabled? | Purpose |
|--------|------|----------|---------|
| Research | `docs/research/` | {{ENABLED_RESEARCH}} | Investigations, spikes, findings |
| Workboard | `docs/WORKBOARD.md` | {{ENABLED_WORKBOARD}} | Multi-phase execution (open / next / SHA) |
| Plan | `docs/plan/` | {{ENABLED_PLAN}} | Detailed plans and optional annexes (complements root `PLAN.md` + workboard) |
| Project build | `docs/project_build/` | {{ENABLED_PROJECT_BUILD}} | Implementation / build context for AI |
| Resources | `docs/resources/` | {{ENABLED_RESOURCES}} | Curated repo + external pointers |

Replace `{{ENABLED_*}}` with `yes` / `no` / `on demand`. Omit unused module rows or mark disabled.

---

## How to update

1. Scaffold **only modules needed** for the current work ([lifecycle](../../rules/ai-docs-workspace.md#lifecycle-dynamic)).  
2. Keep this index accurate when modules change.  
3. Prefer thin notes + links to L4 (`kit/RULES.md`, package contracts).  
4. When a finding becomes a product promise, **promote** to the authority-map owner ([contracts](../../rules/contracts.md)).  
5. Durable mission / Agent models stay in root **`PLAN.md`**. Live multi-phase work stays on **`docs/WORKBOARD.md`** — do not paste phase tables into PLAN.

---

## Related

| Doc | Path |
|-----|------|
| Workspace policy | `kit/rules/ai-docs-workspace.md` |
| Maintenance hub | `kit/RULES.md` |
| Project plan (control) | `PLAN.md` |
| Workboard policy | `kit/rules/workboard.md` |
| Operator enforcement | `kit/RULES.md#operator-enforcement` |
