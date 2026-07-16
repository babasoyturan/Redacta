#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const defaults = {
  development: {
    file: "deploy/gitops/argocd/development/kyverno.yaml",
    appName: "kyverno-development",
    project: "redacta-development",
  },
  production: {
    file: "deploy/gitops/argocd/production/kyverno.yaml",
    appName: "kyverno-production",
    project: "redacta-production",
  },
};

function parseArgs(argv) {
  const options = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) {
      throw new Error(`Unexpected argument "${arg}"`);
    }

    const key = arg.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) {
      throw new Error(`${arg} requires a value`);
    }

    options[key] = value;
    index += 1;
  }

  if (!options.environment || !defaults[options.environment]) {
    throw new Error("--environment must be either development or production");
  }

  if (!options["outputs-file"]) {
    throw new Error("--outputs-file is required");
  }

  return {
    environment: options.environment,
    outputsFile: resolve(options["outputs-file"]),
    file: resolve(options.file || defaults[options.environment].file),
  };
}

function outputValue(outputs, key) {
  if (!Object.prototype.hasOwnProperty.call(outputs, key)) {
    throw new Error(`Terraform output "${key}" is missing`);
  }

  return outputs[key].value;
}

function getRequiredString(outputs, key) {
  const value = outputValue(outputs, key);
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`Terraform output "${key}" must be a non-empty string`);
  }

  return value;
}

function yaml(environment, clientId) {
  const defaultsForEnvironment = defaults[environment];

  return `apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${defaultsForEnvironment.appName}
  namespace: argocd
spec:
  project: ${defaultsForEnvironment.project}
  source:
    repoURL: https://kyverno.github.io/kyverno/
    chart: kyverno
    targetRevision: 3.8.2
    helm:
      releaseName: kyverno
      values: |
        admissionController:
          replicas: 1
          rbac:
            serviceAccount:
              annotations:
                azure.workload.identity/client-id: ${clientId}
          podLabels:
            azure.workload.identity/use: "true"
          container:
            extraEnvVars:
              - name: AZURE_CLIENT_ID
                value: ${clientId}
        backgroundController:
          enabled: false
        cleanupController:
          enabled: false
        reportsController:
          enabled: false
  destination:
    server: https://kubernetes.default.svc
    namespace: kyverno
  ignoreDifferences:
    - group: apiextensions.k8s.io
      kind: CustomResourceDefinition
      jsonPointers:
        - /spec
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
      - RespectIgnoreDifferences=true
`;
}

const options = parseArgs(process.argv.slice(2));
const outputs = JSON.parse(readFileSync(options.outputsFile, "utf8").replace(/^\uFEFF/, ""));
const clientId = getRequiredString(outputs, "kyverno_acr_pull_client_id");
writeFileSync(options.file, yaml(options.environment, clientId), "utf8");
