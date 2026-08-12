/**
 * GigKavach — Centralized API Client
 * All requests go through the API Gateway (port 8000).
 * The gateway routes to internal services — the admin dashboard never calls them directly.
 */

const API_BASE_URL = 'http://localhost:8000/api/v1';

let authToken = null;

const getHeaders = () => ({
  'Content-Type': 'application/json',
  ...(authToken ? { 'Authorization': `Bearer ${authToken}` } : {}),
});

const handleResponse = async (response) => {
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(errorData.detail || `API Error: ${response.statusText}`);
  }
  return response.json();
};

export const GigKavachApi = {
  // ── Auth ──
  login: (userId, password = 'demo') =>
    fetch(`${API_BASE_URL}/auth/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: userId, password }),
    }).then(handleResponse).then(data => {
      authToken = data.access_token;
      return data;
    }),

  setToken: (token) => { authToken = token; },

  // ── Workers ──
  getWorkers: (city) =>
    fetch(`${API_BASE_URL}/workers/${city ? `?city=${city}` : ''}`, { headers: getHeaders() })
      .then(handleResponse),

  getWorker: (workerId) =>
    fetch(`${API_BASE_URL}/workers/${workerId}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Earnings ──
  getEarningsSummary: (workerId, days = 30) =>
    fetch(`${API_BASE_URL}/earnings/summary/${workerId}?days=${days}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Claims ──
  getClaims: (params = '') =>
    fetch(`${API_BASE_URL}/claims/${params}`, { headers: getHeaders() })
      .then(handleResponse),

  getClaim: (claimId) =>
    fetch(`${API_BASE_URL}/claims/${claimId}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Policies ──
  getPolicies: (params = '') =>
    fetch(`${API_BASE_URL}/policies/${params}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Risk ──
  getCityHeatmap: (city) =>
    fetch(`${API_BASE_URL}/risk/city/${city}`, { headers: getHeaders() })
      .then(handleResponse),

  getZoneRisk: (h3Index) =>
    fetch(`${API_BASE_URL}/risk/zone/${h3Index}`, { headers: getHeaders() })
      .then(handleResponse),

  getZoneWeather: (h3Index, city = 'Chennai') =>
    fetch(`${API_BASE_URL}/risk/weather/${h3Index}?city=${city}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Premium ──
  calculatePremium: (data) =>
    fetch(`${API_BASE_URL}/premium/calculate`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(data),
    }).then(handleResponse),

  // ── Triggers ──
  evaluateTriggers: (h3Zone, city = 'Chennai') =>
    fetch(`${API_BASE_URL}/triggers/evaluate`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ h3_zone: h3Zone, city }),
    }).then(handleResponse),

  getTriggerStatus: (h3Zone, city = 'Chennai') =>
    fetch(`${API_BASE_URL}/triggers/status?h3_zone=${h3Zone}&city=${city}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Payouts ──
  initiatePayout: (claimId, amount, idempotencyKey) =>
    fetch(`${API_BASE_URL}/payouts/`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ claim_id: claimId, amount, idempotency_key: idempotencyKey }),
    }).then(handleResponse),

  getBalance: (accountId) =>
    fetch(`${API_BASE_URL}/payouts/balance/${accountId}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Decision ──
  getDecisionScore: (workerId, h3Zone, city = 'Chennai') =>
    fetch(`${API_BASE_URL}/decision/score/${workerId}?h3_zone=${h3Zone}&city=${city}`, { headers: getHeaders() })
      .then(handleResponse),

  // ── Legacy compatibility ──
  getStats: () => GigKavachApi.getClaims().then(data => ({
    total_claims: data.total || 0,
    active_policies: 0,
    total_payouts: 0,
  })),
  getPredictions: () => Promise.resolve({ predictions: [] }),
  getScenarios: () => Promise.resolve({ scenarios: [] }),
  runScenario: () => Promise.resolve({ status: 'mock' }),
  runEngine: (zone, city) => GigKavachApi.evaluateTriggers(zone, city),
  resetSim: () => Promise.resolve({ status: 'ok' }),
};
