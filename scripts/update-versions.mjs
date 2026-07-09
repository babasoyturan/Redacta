#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

const filePath = resolve("deploy/helm/redacta/versions.yaml");
const componentOrder = [
  "frontend",
  "documentService",
  "authenticationService",
  "anonymizationService",
  "genaiService",
];

function readUpdates(argv) {
  const updates = [];

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];

    if (arg === "--updates-file") {
      const updatesFile = argv[i + 1];
      if (!updatesFile) {
        throw new Error("--updates-file requires a path");
      }
      const content = readFileSync(updatesFile, "utf8");
      updates.push(...content.split(/\r?\n/).filter(Boolean));
      i += 1;
      continue;
    }

    updates.push(arg);
  }

  if (updates.length === 0) {
    throw new Error("At least one update is required, for example frontend=repo/name:tag");
  }

  return updates;
}

function parseVersions(content) {
  const versions = {};
  let currentComponent = null;
  let inImage = false;

  for (const rawLine of content.split(/\r?\n/)) {
    const componentMatch = rawLine.match(/^([A-Za-z][A-Za-z0-9]*):\s*$/);
    if (componentMatch) {
      currentComponent = componentMatch[1];
      inImage = false;
      versions[currentComponent] = versions[currentComponent] || { image: {} };
      continue;
    }

    if (!currentComponent) {
      continue;
    }

    if (/^  image:\s*$/.test(rawLine)) {
      inImage = true;
      versions[currentComponent].image = versions[currentComponent].image || {};
      continue;
    }

    const imageValueMatch = rawLine.match(/^    (repository|tag):\s*(.+?)\s*$/);
    if (inImage && imageValueMatch) {
      versions[currentComponent].image[imageValueMatch[1]] = imageValueMatch[2];
    }
  }

  for (const component of componentOrder) {
    if (!versions[component]?.image?.repository || !versions[component]?.image?.tag) {
      throw new Error(`versions.yaml is missing ${component}.image.repository or ${component}.image.tag`);
    }
  }

  return versions;
}

function parseImageRef(imageRef) {
  const separatorIndex = imageRef.lastIndexOf(":");
  if (separatorIndex <= 0 || separatorIndex === imageRef.length - 1) {
    throw new Error(`Invalid image reference "${imageRef}". Expected repository:tag`);
  }

  return {
    repository: imageRef.slice(0, separatorIndex),
    tag: imageRef.slice(separatorIndex + 1),
  };
}

function applyUpdate(versions, update) {
  const separatorIndex = update.indexOf("=");
  if (separatorIndex <= 0 || separatorIndex === update.length - 1) {
    throw new Error(`Invalid update "${update}". Expected component=repository:tag`);
  }

  const component = update.slice(0, separatorIndex);
  const imageRef = update.slice(separatorIndex + 1);

  if (!componentOrder.includes(component)) {
    throw new Error(`Unknown component "${component}". Allowed components: ${componentOrder.join(", ")}`);
  }

  versions[component].image = parseImageRef(imageRef);
}

function stringifyVersions(versions) {
  return `${componentOrder
    .map((component) => {
      const image = versions[component].image;
      return `${component}:\n  image:\n    repository: ${image.repository}\n    tag: ${image.tag}`;
    })
    .join("\n\n")}\n`;
}

const versions = parseVersions(readFileSync(filePath, "utf8"));
for (const update of readUpdates(process.argv.slice(2))) {
  applyUpdate(versions, update);
}

writeFileSync(filePath, stringifyVersions(versions), "utf8");
