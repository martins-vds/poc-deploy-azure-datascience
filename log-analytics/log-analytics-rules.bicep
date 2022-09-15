param scheduledQueryName string
param workspaceName string
param workspaceSubscriptionId string
param workspaceResourceGroup string

param ruleEnabled bool = false
param location string = resourceGroup().location

var actionGroups = array(loadJsonContent('vars-action-groups.json'))

resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspaceName
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroup)
}

resource scheduledQuery 'microsoft.insights/scheduledqueryrules@2021-08-01' = {
  name: scheduledQueryName
  location: location
  properties: {
    displayName: scheduledQueryName
    description: 'The PayCan Pipeline has completed successfully. A summary of the pipeline run completion is below:'
    severity: 3
    enabled: ruleEnabled
    evaluationFrequency: 'PT5M'
    scopes: [
      workspace.id
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'ADFPipelineRun\n| sort by TimeGenerated\n| where PipelineName == "PL_Control_Main" and Status == "Succeeded"\n| project\n    PipelineName,\n    Status,\n    Parameters,\n    Start,\n    End\n| limit 1'
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [for actionGroup in actionGroups: '/subscriptions/${actionGroup.subscriptionId}/resourceGroups/${actionGroup.resourceGroup}/providers/microsoft.insights/actionGroups/${actionGroup.actionGroup}']
    }
  }
}
