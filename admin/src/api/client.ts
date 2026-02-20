import axios from 'axios';

// baseURL must be empty/relative so the browser sends requests to its own
// origin (localhost:5174). The Vite dev server proxy then forwards /api/* to
// the backend (configured via VITE_API_URL in vite.config.ts).
export const api = axios.create({
    baseURL: '',
    headers: { 'Content-Type': 'application/json' },
});

// Attach token on every request
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('admin_token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
});

// Redirect to login on 401
api.interceptors.response.use(
    (res) => res,
    (error) => {
        if (error.response?.status === 401 || error.response?.status === 403) {
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_user');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    },
);

// ─── Auth ──────────────────────────────────────────────────────────────────
export const adminAuth = {
    login: (email: string, password: string) =>
        api.post('/api/auth/login', { email, password }).then(r => r.data),
};

// ─── Analytics ─────────────────────────────────────────────────────────────
export const adminAnalytics = {
    dashboard: () => api.get('/api/admin/analytics/dashboard').then(r => r.data),
    infra: () => api.get('/api/admin/analytics/infra').then(r => r.data),
};

// ─── Users ─────────────────────────────────────────────────────────────────
export const adminUsers = {
    list: (params?: { search?: string; page?: number; limit?: number }) =>
        api.get('/api/admin/users', { params }).then(r => r.data),
    detail: (id: string) => api.get(`/api/admin/users/${id}`).then(r => r.data),
};

// ─── Workers ───────────────────────────────────────────────────────────────
export const adminWorkers = {
    list: (params?: { search?: string; page?: number; limit?: number }) =>
        api.get('/api/admin/workers', { params }).then(r => r.data),
};

// ─── Transactions ───────────────────────────────────────────────────────────
export const adminTransactions = {
    list: (params?: { search?: string; status?: string; type?: string; page?: number; limit?: number }) =>
        api.get('/api/admin/transactions', { params }).then(r => r.data),
    refund: (data: { transactionId: string; amount?: number; reason: string }) =>
        api.post('/api/admin/refunds', data).then(r => r.data),
};

// ─── Payroll ────────────────────────────────────────────────────────────────
export const adminPayroll = {
    dashboard: () => api.get('/api/admin/payroll/dashboard').then(r => r.data),
    payPeriods: (params?: { search?: string; page?: number; limit?: number }) =>
        api.get('/api/admin/payroll/pay-periods', { params }).then(r => r.data),
    records: (payPeriodId: string) =>
        api.get(`/api/admin/payroll/records/${payPeriodId}`).then(r => r.data),
};

// ─── Subscription Plans ─────────────────────────────────────────────────────
export const adminPlans = {
    list: () => api.get('/api/admin/subscription-plans').then(r => r.data),
    update: (id: string, data: any) =>
        api.put(`/api/admin/subscription-plans/${id}`, data).then(r => r.data),
    subscribers: () =>
        api.get('/api/admin/subscription-plans/subscribers').then(r => r.data),
    stats: () =>
        api.get('/api/admin/subscription-plans/stats').then(r => r.data),
};

// ─── Tax Configs ────────────────────────────────────────────────────────────
export const adminTaxConfigs = {
    list: () => api.get('/api/admin/tax-configs').then(r => r.data),
    create: (data: any) => api.post('/api/admin/tax-configs', data).then(r => r.data),
    update: (id: string, data: any) =>
        api.put(`/api/admin/tax-configs/${id}`, data).then(r => r.data),
    deactivate: (id: string) =>
        api.put(`/api/admin/tax-configs/${id}/deactivate`).then(r => r.data),
};

// ─── Support Tickets ────────────────────────────────────────────────────────
export const adminSupport = {
    list: (params?: { status?: string; category?: string; priority?: string; search?: string; page?: number }) =>
        api.get('/api/admin/support/tickets', { params }).then(r => r.data),
    detail: (id: string) =>
        api.get(`/api/admin/support/tickets/${id}`).then(r => r.data),
    update: (id: string, data: any) =>
        api.put(`/api/admin/support/tickets/${id}`, data).then(r => r.data),
    reply: (id: string, message: string) =>
        api.post(`/api/admin/support/tickets/${id}/messages`, { message }).then(r => r.data),
};

// ─── System Config ──────────────────────────────────────────────────────────
export const adminSystemConfig = {
    list: () => api.get('/api/admin/system-config').then(r => r.data),
    update: (key: string, data: { value: string; description?: string }) =>
        api.put(`/api/admin/system-config/${key}`, data).then(r => r.data),
};

// ─── Audit Logs ─────────────────────────────────────────────────────────────
export const adminAuditLogs = {
    list: (params?: { page?: number; entityType?: string; action?: string }) =>
        api.get('/api/admin/audit-logs', { params }).then(r => r.data),
};

// ─── Notifications ────────────────────────────────────────────────────────────
export const adminNotifications = {
    list: (params?: { page?: number; limit?: number; type?: string }) =>
        api.get('/api/admin/notifications', { params }).then(r => r.data),
    send: (data: { userIds?: string[]; broadcast?: boolean; type: string; subject?: string; message: string }) =>
        api.post('/api/admin/notifications/send', data).then(r => r.data),
};

// ─── Container Logs ────────────────────────────────────────────────────────
export const adminLogs = {
    list: (params?: { container?: string; lines?: number; page?: number; search?: string }) =>
        api.get('/api/admin/containers/logs', { params }).then(r => r.data),
    containers: () => api.get('/api/admin/containers').then(r => r.data),
};
