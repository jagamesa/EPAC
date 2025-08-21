# Azure Policy EPAC Baseline
Repo de **Policy as Code** para Azure:
- Policy custom **Diagnostic Settings → Log Analytics** (DeployIfNotExists).
- Policy **DENY** para **RBAC break-glass**.
- **Initiative** y **assignment** (Bicep).
- **GitHub Actions**: what-if → deploy → scan → remediate.

## Uso
1. Copia `policy/infra/params.example.json` a `policy/infra/params.json` y rellena los valores.
2. Añade secretos en GitHub: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.
3. Push a `main` para ejecutar el pipeline.
