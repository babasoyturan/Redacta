# Backend Load Test Proof

This folder contains the load-test assets used to prove that Redacta can handle the required backend request volume without opening the public ingress path or weakening the runtime NetworkPolicy model.

## Target

The project requirement is to demonstrate that the deployed application can handle at least 300 backend requests per second. The preferred proof runs inside the production AKS cluster against an internal service endpoint.

The default Kubernetes job targets:

```text
namespace: redacta
service:   redacta-anonymization-service
url:       http://redacta-anonymization-service:8094/actuator/health
rate:      300 requests/second
duration:  60 seconds
threshold: less than 1% request failures and p95 latency below 300 ms
```

The `/actuator/health` endpoint is used because it proves backend service reachability and avoids mixing authentication, browser, TLS, Application Gateway, or internet latency into the internal backend-capacity result.

## Files

```text
tests/performance/k6-backend-smoke.js
tests/performance/k8s-loadtest-networkpolicy.yaml
tests/performance/k8s-k6-backend-smoke-job.yaml
tests/performance/backend-load-smoke.mjs
```

`k6-backend-smoke.js` is the main k6 test. `backend-load-smoke.mjs` is a dependency-free Node.js fallback for local endpoint checks when k6 is not installed.

The Kubernetes test uses a temporary NetworkPolicy named `redacta-allow-k6-load-test-to-anonymization`. It allows only pods labeled `redacta-load-test: "true"` to call the anonymization service on port `8094`. This policy is not part of the GitOps runtime deployment; it exists only during the performance proof and must be deleted after the test.

## Run From Production AKS

```powershell
az aks get-credentials `
  --resource-group rg-redacta-production `
  --name aks-redacta-prod-swec `
  --overwrite-existing

kubectl -n redacta delete job redacta-k6-backend-smoke --ignore-not-found
kubectl -n redacta delete configmap redacta-k6-backend-smoke --ignore-not-found
kubectl -n redacta delete networkpolicy redacta-allow-k6-load-test-to-anonymization --ignore-not-found

kubectl -n redacta create configmap redacta-k6-backend-smoke `
  --from-file=k6-backend-smoke.js=tests/performance/k6-backend-smoke.js

kubectl apply -f tests/performance/k8s-loadtest-networkpolicy.yaml
kubectl apply -f tests/performance/k8s-k6-backend-smoke-job.yaml

kubectl wait -n redacta --for=condition=complete job/redacta-k6-backend-smoke --timeout=240s

kubectl logs -n redacta job/redacta-k6-backend-smoke `
  | Tee-Object -FilePath docs/performance/k6-backend-smoke-latest.log
```

## Cleanup

```powershell
kubectl -n redacta delete job redacta-k6-backend-smoke --ignore-not-found
kubectl -n redacta delete configmap redacta-k6-backend-smoke --ignore-not-found
kubectl -n redacta delete networkpolicy redacta-allow-k6-load-test-to-anonymization --ignore-not-found
```

## Expected Evidence

The k6 output should show:

```text
http_req_failed{target:api}: rate<0.01
http_req_duration{target:api}: p(95)<300
http_reqs: approximately 300/s
```

If the test is run through a local `kubectl port-forward` or public internet endpoint, the result is not a clean backend-capacity proof because the port-forward process, TLS, Application Gateway, and client network latency become part of the measurement.

## Latest Production Result

Latest recorded proof:

```text
file: docs/performance/k6-backend-smoke-20260716-051508.log
environment: production AKS
target: http://redacta-anonymization-service:8094/actuator/health
duration: 60 seconds
requests: 18,001
request rate: 299.975368/s
failed requests: 0.00%
p95 latency: 47.35 ms
threshold result: passed
```
