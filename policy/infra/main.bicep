targetScope = "subscription"

@description("Name for the custom policy: diagnostics to Log Analytics")
param policyDefinitionNameDiag string = "custom-enable-diagnostics-to-law"

@description("Name for the custom policy: deny break-glass RBAC")
param policyDefinitionNameBreakglass string = "custom-deny-breakglass-rbac"

@description("Name for the policy set (initiative)")
param initiativeName string = "baseline-policy-initiative"

@description("Name for the policy assignment")
param assignmentName string = "baseline-policy-assignment"

@description("Location (required for identity on assignment)")
param location string = "westeurope"

@description("Log Analytics workspace resourceId")
param logAnalyticsWorkspaceId string

@description("Diagnostic setting name")
param diagnosticSettingName string = "send-to-law"

@allowed([ "AllLogs", "Audit", "Security" ])
@description("Category group to enable in diagnostics")
param categoryGroup string = "Audit"

@description("Enable AllMetrics in diagnostics")
param enableMetrics bool = true

@description("Break-glass principal object IDs")
param emergencyPrincipalIds array = []

@description("Allowed role definition IDs for break-glass (full IDs). Empty array forbids any assignment.")
param allowedRoleDefinitionIds array = []

@description("Allowed scope prefix for break-glass assignments (empty means any scope).")
param allowedScopePrefix string = ""

var diagPolicy = json(loadTextContent("../definitions/enable-diagnostics-law.json"))
var breakglassPolicy = json(loadTextContent("../definitions/deny-breakglass-rbac.json"))

resource diagDef "Microsoft.Authorization/policyDefinitions@2021-06-01" = {
  name: policyDefinitionNameDiag
  properties: diagPolicy.properties
}

resource breakglassDef "Microsoft.Authorization/policyDefinitions@2021-06-01" = {
  name: policyDefinitionNameBreakglass
  properties: breakglassPolicy.properties
}

resource baselineSet "Microsoft.Authorization/policySetDefinitions@2021-06-01" = {
  name: initiativeName
  properties: {
    displayName: initiativeName
    description: "Baseline initiative: diagnostics to Log Analytics + deny non-compliant break-glass RBAC."
    metadata: { category: "Governance" }
    parameters: {
      logAnalyticsWorkspaceId: { type: "String" }
      diagnosticSettingName: { type: "String", defaultValue: "send-to-law" }
      categoryGroup: { type: "String", allowedValues: [ "AllLogs", "Audit", "Security" ], defaultValue: "Audit" }
      enableMetrics: { type: "Boolean", defaultValue: true }
      emergencyPrincipalIds: { type: "Array", defaultValue: [] }
      allowedRoleDefinitionIds: { type: "Array", defaultValue: [] }
      allowedScopePrefix: { type: "String", defaultValue: "" }
    }
    policyDefinitions: [
      {
        policyDefinitionId: diagDef.id
        parameters: {
          logAnalyticsWorkspaceId: { value: "[parameters('logAnalyticsWorkspaceId')]" }
          diagnosticSettingName: { value: "[parameters('diagnosticSettingName')]" }
          categoryGroup: { value: "[parameters('categoryGroup')]" }
          enableMetrics: { value: "[parameters('enableMetrics')]" }
        }
      }
      {
        policyDefinitionId: breakglassDef.id
        parameters: {
          emergencyPrincipalIds: { value: "[parameters('emergencyPrincipalIds')]" }
          allowedRoleDefinitionIds: { value: "[parameters('allowedRoleDefinitionIds')]" }
          allowedScopePrefix: { value: "[parameters('allowedScopePrefix')]" }
        }
      }
    ]
  }
}

resource assignment "Microsoft.Authorization/policyAssignments@2022-06-01" = {
  name: assignmentName
  location: location
  identity: { type: "SystemAssigned" }
  properties: {
    displayName: assignmentName
    policyDefinitionId: baselineSet.id
    scope: subscription().id
    parameters: {
      logAnalyticsWorkspaceId: { value: logAnalyticsWorkspaceId }
      diagnosticSettingName: { value: diagnosticSettingName }
      categoryGroup: { value: categoryGroup }
      enableMetrics: { value: enableMetrics }
      emergencyPrincipalIds: { value: emergencyPrincipalIds }
      allowedRoleDefinitionIds: { value: allowedRoleDefinitionIds }
      allowedScopePrefix: { value: allowedScopePrefix }
    }
    enforcementMode: "Default"
  }
}

output initiativeId string = baselineSet.id
output assignmentId string = assignment.id
