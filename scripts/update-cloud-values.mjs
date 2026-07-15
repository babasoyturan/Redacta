#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const componentImages = {
  frontend: "redacta-frontend",
  documentService: "redacta-document-service",
  authenticationService: "redacta-authentication-service",
  anonymizationService: "redacta-anonymization-service",
  genaiService: "redacta-genai-service",
};

const serviceAccounts = {
  documentService: "redacta-document-service",
  authenticationService: "redacta-authentication-service",
  anonymizationService: "redacta-anonymization-service",
  genaiService: "redacta-genai-service",
  keycloak: "redacta-keycloak",
};

const defaults = {
  development: {
    file: "deploy/helm/redacta/values-cloud-development.yaml",
    host: "dev.redacta.site",
  },
  production: {
    file: "deploy/helm/redacta/values-cloud-production.yaml",
    host: "redacta.site",
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
    tenantId: options["tenant-id"] || "",
    acrLoginServer: options["acr-login-server"] || "",
    host: options.host || defaults[options.environment].host,
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

function getWorkloadClientIds(outputs) {
  const value = outputValue(outputs, "workload_identity_client_ids");
  const missing = Object.keys(serviceAccounts).filter(
    (component) => typeof value?.[component] !== "string" || value[component].trim() === "",
  );

  if (missing.length > 0) {
    throw new Error(`Terraform output "workload_identity_client_ids" is missing: ${missing.join(", ")}`);
  }

  return value;
}

function imageRepository(component, acrLoginServer) {
  const imageName = componentImages[component];
  if (!acrLoginServer) {
    return imageName;
  }

  return `${acrLoginServer}/${imageName}`;
}

function databaseUrl(sqlFqdn, database) {
  return `jdbc:sqlserver://${sqlFqdn}:1433;database=${database};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;`;
}

function yaml(options, outputs) {
  const resourceGroupName = getRequiredString(outputs, "resource_group_name");
  const storageAccountName = getRequiredString(outputs, "documents_storage_account_name");
  const documentsShareName = getRequiredString(outputs, "documents_share_name");
  const sqlFqdn = getRequiredString(outputs, "sql_server_fqdn");
  const keyVaultName = getRequiredString(outputs, "key_vault_name");
  const clientIds = getWorkloadClientIds(outputs);
  const tenantId = options.tenantId.trim();
  const acrLoginServer = options.acrLoginServer.trim();
  const appGatewayCidrs = {
    development: "10.20.16.0/24",
    production: "10.30.16.0/24",
  };
  const sqlCidrs = {
    development: "10.20.17.0/24",
    production: "10.30.17.0/24",
  };
  const production = options.environment === "production";
  const appReplicaCount = production ? 3 : 1;
  const capacityControls = production ? `autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
  components:
    frontend: true
    documentService: true
    authenticationService: true
    anonymizationService: true
    genaiService: true

podDisruptionBudget:
  enabled: true
  minAvailable: 2
  components:
    frontend: true
    documentService: true
    authenticationService: true
    anonymizationService: true
    genaiService: true

topologySpread:
  enabled: true
  maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway` : `autoscaling:
  enabled: false`;

  if (!tenantId) {
    throw new Error("--tenant-id is required");
  }

  if (!acrLoginServer) {
    throw new Error("--acr-login-server is required");
  }

  return `global:
  imagePullPolicy: IfNotPresent

spring:
  profile: cloud

deploymentStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0
    maxUnavailable: 1

frontend:
  image:
    repository: ${imageRepository("frontend", acrLoginServer)}
    tag: replace-me
  replicaCount: ${appReplicaCount}

documentService:
  image:
    repository: ${imageRepository("documentService", acrLoginServer)}
    tag: replace-me
  replicaCount: ${appReplicaCount}
  storageLocation: /mnt/redacta-documents
  persistence:
    enabled: true
    storageClassName: azurefile-csi
    size: 20Gi
    shareName: ${documentsShareName}
    resourceGroupName: ${resourceGroupName}
    storageAccountName: ${storageAccountName}
    secretName: redacta-azure-files-secret
    reclaimPolicy: Retain
  databaseUrl: ${databaseUrl(sqlFqdn, "documentdb")}
  jwtIssuerUri: http://keycloak:8080/realms/oopsops

authenticationService:
  image:
    repository: ${imageRepository("authenticationService", acrLoginServer)}
    tag: replace-me
  replicaCount: ${appReplicaCount}
  databaseUrl: ${databaseUrl(sqlFqdn, "authdb")}

anonymizationService:
  image:
    repository: ${imageRepository("anonymizationService", acrLoginServer)}
    tag: replace-me
  replicaCount: ${appReplicaCount}
  databaseUrl: ${databaseUrl(sqlFqdn, "anonymizationdb")}
  jwtIssuerUri: http://keycloak:8080/realms/oopsops

genaiService:
  image:
    repository: ${imageRepository("genaiService", acrLoginServer)}
    tag: replace-me
  replicaCount: ${appReplicaCount}
  localFallback: false

keycloak:
  enabled: true
  authServerUrl: http://keycloak:8080
  database:
    vendor: mssql
    url: ${databaseUrl(sqlFqdn, "keycloakdb")}

serviceAccount:
  create: true
  components:
    documentService: ${serviceAccounts.documentService}
    authenticationService: ${serviceAccounts.authenticationService}
    anonymizationService: ${serviceAccounts.anonymizationService}
    genaiService: ${serviceAccounts.genaiService}
    keycloak: ${serviceAccounts.keycloak}

workloadIdentity:
  enabled: true
  clientIds:
    documentService: ${clientIds.documentService}
    authenticationService: ${clientIds.authenticationService}
    anonymizationService: ${clientIds.anonymizationService}
    genaiService: ${clientIds.genaiService}
    keycloak: ${clientIds.keycloak}

keyVault:
  csi:
    enabled: true
    vaultName: ${keyVaultName}
    tenantId: ${tenantId}

sqlBootstrap:
  enabled: true
  serverFqdn: ${sqlFqdn}

secrets:
  create: false
  name: redacta-app-secrets
  names:
    documentService: redacta-document-service-secrets
    authenticationService: redacta-authentication-service-secrets
    anonymizationService: redacta-anonymization-service-secrets
    genaiService: redacta-genai-service-secrets
    keycloak: redacta-keycloak-secrets

ingress:
  enabled: true
  className: azure-application-gateway
  host: ${options.host}
  annotations:
    appgw.ingress.kubernetes.io/use-private-ip: "false"
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls:
    enabled: true
    secretName: redacta-tls

certManager:
  clusterIssuer:
    enabled: true
    name: letsencrypt-prod
    email: admin@redacta.site
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretName: redacta-letsencrypt-prod-account-key
    ingressClassName: azure-application-gateway

${capacityControls}

networkPolicy:
  enabled: true
  ingress:
    appGatewayCidrs:
      - ${appGatewayCidrs[options.environment]}
  egress:
    sqlCidrs:
      - ${sqlCidrs[options.environment]}
    externalHttpsCidrs:
      - 0.0.0.0/0

monitoring:
  serviceMonitor:
    enabled: true
    apiVersion: azmonitoring.coreos.com/v1
`;
}

const options = parseArgs(process.argv.slice(2));
const outputs = JSON.parse(readFileSync(options.outputsFile, "utf8").replace(/^\uFEFF/, ""));
writeFileSync(options.file, yaml(options, outputs), "utf8");
