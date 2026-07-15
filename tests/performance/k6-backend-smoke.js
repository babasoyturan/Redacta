import http from "k6/http";
import { check } from "k6";

const baseUrl = (__ENV.BASE_URL || "https://redacta.site").replace(/\/$/, "");
const apiPath = __ENV.API_PATH || "/api/v1/anonymization";
const rate = Number(__ENV.RATE || 300);
const vus = Number(__ENV.VUS || 100);
const maxVus = Number(__ENV.MAX_VUS || 300);

export const options = {
  scenarios: {
    backend_steady_load: {
      executor: "constant-arrival-rate",
      rate,
      timeUnit: "1s",
      duration: __ENV.DURATION || "2m",
      preAllocatedVUs: vus,
      maxVUs,
    },
  },
  thresholds: {
    "http_req_failed{target:api}": ["rate<0.01"],
    "http_req_duration{target:api}": ["p(95)<300"],
  },
};

export default function () {
  const response = http.get(`${baseUrl}${apiPath}`, {
    tags: { target: "api" },
  });

  check(response, {
    "backend responded below 500": (res) => res.status < 500,
  });
}
