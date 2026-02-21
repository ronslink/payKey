import { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Input, Typography, Button, Modal, Progress, Tooltip, Space } from 'antd';
import {
    SearchOutlined, CalendarOutlined, TeamOutlined, DollarOutlined,
    CheckCircleOutlined, BankOutlined, MobileOutlined, WalletOutlined,
    RightOutlined, DownOutlined,
} from '@ant-design/icons';
import { adminPayroll } from '../api/client';

const { Title, Text } = Typography;

// ─── Constants ────────────────────────────────────────────────────────────────

const STATUS_STYLE: Record<string, { color: string; bg: string; label: string }> = {
    paid:       { color: '#16a34a', bg: '#dcfce7', label: 'Paid' },
    processing: { color: '#2563eb', bg: '#dbeafe', label: 'Processing' },
    open:       { color: '#d97706', bg: '#fef3c7', label: 'Open' },
    closed:     { color: '#64748b', bg: '#f1f5f9', label: 'Closed' },
    failed:     { color: '#dc2626', bg: '#fee2e2', label: 'Failed' },
};

const METHOD_STYLE: Record<string, { color: string; bg: string; icon: React.ReactNode }> = {
    MPESA: { color: '#16a34a', bg: '#dcfce7', icon: <MobileOutlined /> },
    BANK:  { color: '#2563eb', bg: '#dbeafe', icon: <BankOutlined /> },
    WALLET:{ color: '#7c3aed', bg: '#ede9fe', icon: <WalletOutlined /> },
};

const AVATAR_COLORS: [string, string][] = [
    ['#6366f1', '#eef2ff'], ['#10b981', '#ecfdf5'], ['#f59e0b', '#fffbeb'],
    ['#ef4444', '#fee2e2'], ['#8b5cf6', '#f5f3ff'], ['#0ea5e9', '#e0f2fe'],
    ['#ec4899', '#fdf2f8'], ['#14b8a6', '#f0fdfa'],
];

function employerColor(id: string): [string, string] {
    let hash = 0;
    for (let i = 0; i < id.length; i++) hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
    return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

function fmtKES(v: number) {
    return Number(v || 0).toLocaleString();
}

function fmtDateRange(start: string, end: string) {
    const s = new Date(start).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    const e = new Date(end).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
    return `${s} – ${e}`;
}

// ─── Stat card ────────────────────────────────────────────────────────────────

function StatCard({ label, value, sub, color, bg, icon }: {
    label: string; value: string | number; sub?: React.ReactNode;
    color: string; bg: string; icon: React.ReactNode;
}) {
    return (
        <div style={{
            background: '#fff', borderRadius: 13,
            padding: '18px 20px',
            border: '1px solid #e8e8e8',
            flex: 1, minWidth: 140,
        }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: sub ? 10 : 0 }}>
                <div>
                    <div style={{ fontSize: 11, color: '#64748b', marginBottom: 6, fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                        {label}
                    </div>
                    <div style={{ fontSize: 26, fontWeight: 700, lineHeight: 1, color: '#0f172a' }}>{value}</div>
                </div>
                <div style={{
                    width: 40, height: 40, borderRadius: 10,
                    background: bg, display: 'flex', alignItems: 'center',
                    justifyContent: 'center', fontSize: 18, color,
                }}>
                    {icon}
                </div>
            </div>
            {sub && <div style={{ marginTop: 4 }}>{sub}</div>}
        </div>
    );
}

// ─── Period row (inside expanded employer) ───────────────────────────────────

function PeriodRow({ period, onViewRecords, employerName }: {
    period: any;
    onViewRecords: (payPeriodId: string, employerName: string, periodLabel: string) => void;
    employerName: string;
}) {
    const st = STATUS_STYLE[period.status] || { color: '#64748b', bg: '#f1f5f9', label: period.status };
    const label = fmtDateRange(period.startDate, period.endDate);

    return (
        <div style={{
            display: 'flex', alignItems: 'center', gap: 16,
            padding: '11px 24px 11px 64px',
            borderBottom: '1px solid #f1f5f9',
            background: period.status === 'failed' ? '#fff5f5' : '#fff',
        }}>
            {/* Period range */}
            <div style={{ flex: 1, minWidth: 0 }}>
                <span style={{ fontSize: 13, color: '#334155', fontWeight: 500 }}>{label}</span>
            </div>

            {/* Status */}
            <div style={{ width: 110, flexShrink: 0 }}>
                <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 5,
                    background: st.bg, color: st.color,
                    borderRadius: 20, padding: '3px 11px', fontSize: 12, fontWeight: 600,
                }}>
                    <span style={{
                        width: 6, height: 6, borderRadius: '50%',
                        background: st.color, display: 'inline-block',
                    }} />
                    {st.label}
                </span>
            </div>

            {/* Workers */}
            <div style={{ width: 100, flexShrink: 0, display: 'flex', alignItems: 'center', gap: 6 }}>
                <TeamOutlined style={{ color: '#6366f1', fontSize: 13 }} />
                <span style={{ fontSize: 13, fontWeight: 600, color: '#334155' }}>{period.recordCount}</span>
                <span style={{ fontSize: 11, color: '#94a3b8' }}>workers</span>
            </div>

            {/* Net Pay */}
            <div style={{ width: 150, flexShrink: 0, textAlign: 'right' }}>
                <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>KES</span>
                <span style={{ fontSize: 14, fontWeight: 700, color: '#0f172a' }}>{fmtKES(period.totalNetPay)}</span>
            </div>

            {/* Action */}
            <div style={{ width: 120, flexShrink: 0, textAlign: 'right' }}>
                <Button
                    size="small"
                    type="primary"
                    ghost
                    icon={<TeamOutlined />}
                    onClick={() => onViewRecords(period.id, employerName, label)}
                    style={{ borderRadius: 6, fontSize: 12 }}
                >
                    Records
                </Button>
            </div>
        </div>
    );
}

// ─── Period table header ──────────────────────────────────────────────────────

function PeriodHeader({ canEdit }: { canEdit: boolean }) {
    return (
        <div style={{
            display: 'flex', alignItems: 'center', gap: 16,
            padding: '7px 24px 7px 64px',
            background: '#f8fafc',
            borderBottom: '1px solid #e8e8e8',
            fontSize: 11, fontWeight: 700, color: '#94a3b8',
            textTransform: 'uppercase', letterSpacing: '0.06em',
        }}>
            <div style={{ flex: 1 }}>Period</div>
            <div style={{ width: 110, flexShrink: 0 }}>Status</div>
            <div style={{ width: 100, flexShrink: 0 }}>Workers</div>
            <div style={{ width: 150, flexShrink: 0, textAlign: 'right' }}>Net Pay</div>
            {canEdit && <div style={{ width: 120, flexShrink: 0, textAlign: 'right' }}>Actions</div>}
        </div>
    );
}

// ─── Employer group row ───────────────────────────────────────────────────────

function EmployerGroupRow({ employer, expanded, onToggle, onViewRecords }: {
    employer: any;
    expanded: boolean;
    onToggle: () => void;
    onViewRecords: (payPeriodId: string, employerName: string, periodLabel: string) => void;
}) {
    const [color, bg] = employerColor(employer.employer_id || employer.employer_email || '?');
    const initial = (employer.employer_name || '?').charAt(0).toUpperCase();
    const periods = employer.recentPeriods || [];
    const hasFailed = periods.some((p: any) => p.status === 'failed');

    return (
        <div style={{ borderBottom: '1px solid #f1f5f9' }}>
            {/* Employer header */}
            <div
                onClick={onToggle}
                style={{
                    display: 'flex', alignItems: 'center', gap: 14,
                    padding: '14px 20px',
                    cursor: 'pointer',
                    background: expanded ? '#fafbff' : '#fff',
                    transition: 'background 0.12s',
                    userSelect: 'none',
                }}
                onMouseEnter={e => { if (!expanded) e.currentTarget.style.background = '#fafbff'; }}
                onMouseLeave={e => { if (!expanded) e.currentTarget.style.background = '#fff'; }}
            >
                {/* Expand toggle */}
                <span style={{ color: '#94a3b8', fontSize: 12, width: 14, flexShrink: 0 }}>
                    {expanded ? <DownOutlined /> : <RightOutlined />}
                </span>

                {/* Avatar */}
                <div style={{
                    width: 40, height: 40, borderRadius: 12,
                    background: bg, color, display: 'flex', alignItems: 'center',
                    justifyContent: 'center', fontWeight: 700, fontSize: 16, flexShrink: 0,
                }}>
                    {initial}
                </div>

                {/* Name + email */}
                <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 700, fontSize: 14, color: '#0f172a', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {employer.employer_name || '—'}
                    </div>
                    <div style={{ fontSize: 12, color: '#94a3b8' }}>{employer.employer_email}</div>
                </div>

                {/* Failed warning */}
                {hasFailed && (
                    <Tooltip title="One or more pay periods failed">
                        <span style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            background: '#fee2e2', color: '#dc2626',
                            borderRadius: 20, padding: '3px 10px', fontSize: 11, fontWeight: 600,
                        }}>
                            ⚠ Has Failures
                        </span>
                    </Tooltip>
                )}

                {/* Pay period count */}
                <div style={{ textAlign: 'center', minWidth: 70 }}>
                    <div style={{ fontSize: 20, fontWeight: 700, color, lineHeight: 1 }}>{employer.totalPayPeriods}</div>
                    <div style={{ fontSize: 11, color: '#94a3b8' }}>period{employer.totalPayPeriods !== 1 ? 's' : ''}</div>
                </div>

                {/* Lifetime net pay */}
                <div style={{ textAlign: 'right', minWidth: 150 }}>
                    <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 1 }}>Lifetime Net Pay</div>
                    <div style={{ fontSize: 15, fontWeight: 700, color: '#0f172a' }}>
                        <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>KES</span>
                        {fmtKES(employer.lifetimeNetPay)}
                    </div>
                </div>
            </div>

            {/* Expanded period rows */}
            {expanded && periods.length > 0 && (
                <div style={{ background: '#fafbff' }}>
                    <PeriodHeader canEdit={true} />
                    {periods.map((p: any) => (
                        <PeriodRow
                            key={p.id}
                            period={p}
                            employerName={employer.employer_name}
                            onViewRecords={onViewRecords}
                        />
                    ))}
                </div>
            )}
        </div>
    );
}

// ─── Worker record row (in modal) ─────────────────────────────────────────────

function RecordRow({ r }: { r: any }) {
    const st = STATUS_STYLE[r.status] || { color: '#64748b', bg: '#f1f5f9', label: r.status || '—' };

    return (
        <div style={{
            display: 'flex', alignItems: 'center', gap: 14,
            padding: '11px 16px',
            borderBottom: '1px solid #f1f5f9',
            background: r.status === 'failed' ? '#fff5f5' : '#fff',
        }}>
            {/* Worker */}
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 13, color: '#0f172a' }}>{r.worker_name}</div>
                <div style={{ fontSize: 11, color: '#94a3b8', fontFamily: 'monospace' }}>{r.worker_phone}</div>
            </div>

            {/* Gross */}
            <div style={{ width: 120, textAlign: 'right' }}>
                <div style={{ fontSize: 11, color: '#94a3b8' }}>Gross</div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#334155' }}>
                    <span style={{ fontSize: 10, marginRight: 2, color: '#94a3b8' }}>KES</span>
                    {fmtKES(r.grossSalary)}
                </div>
            </div>

            {/* PAYE */}
            <div style={{ width: 110, textAlign: 'right' }}>
                <div style={{ fontSize: 11, color: '#94a3b8' }}>PAYE</div>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#ef4444' }}>
                    <span style={{ fontSize: 10, marginRight: 2, color: '#94a3b8' }}>KES</span>
                    {fmtKES(r.payeTax || 0)}
                </div>
            </div>

            {/* Net */}
            <div style={{ width: 130, textAlign: 'right' }}>
                <div style={{ fontSize: 11, color: '#94a3b8' }}>Net Pay</div>
                <div style={{ fontSize: 15, fontWeight: 800, color: '#10b981' }}>
                    <span style={{ fontSize: 10, marginRight: 2, color: '#94a3b8' }}>KES</span>
                    {fmtKES(r.netPay)}
                </div>
            </div>

            {/* Status */}
            <div style={{ width: 90, flexShrink: 0 }}>
                <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                    background: st.bg, color: st.color,
                    borderRadius: 20, padding: '2px 10px', fontSize: 11, fontWeight: 600,
                }}>
                    <span style={{ width: 5, height: 5, borderRadius: '50%', background: st.color, display: 'inline-block' }} />
                    {st.label}
                </span>
            </div>
        </div>
    );
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function PayrollPage() {
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());
    const [detailModal, setDetailModal] = useState<{ open: boolean; payPeriodId?: string; employerName?: string; periodLabel?: string }>({ open: false });

    const { data: dashboard, isLoading: dashboardLoading } = useQuery({
        queryKey: ['admin-payroll-dashboard'],
        queryFn: adminPayroll.dashboard,
    });

    const { data, isLoading } = useQuery({
        queryKey: ['admin-payroll', search, page],
        queryFn: () => adminPayroll.payPeriods({ search: search || undefined, page }),
    });

    const { data: recordsData, isLoading: recordsLoading } = useQuery({
        queryKey: ['admin-payroll-records', detailModal.payPeriodId],
        queryFn: () => adminPayroll.records(detailModal.payPeriodId!),
        enabled: !!detailModal.payPeriodId && detailModal.open,
    });

    const summary = dashboard?.summary;
    const totalPeriods = summary?.totalPeriods || 0;
    const successfulPeriods = summary?.successfulPeriods || 0;
    const successRate = totalPeriods > 0 ? Math.round((successfulPeriods / totalPeriods) * 100) : 0;

    const employers: any[] = data?.data || [];

    // Auto-expand all on data load
    useMemo(() => {
        if (employers.length > 0) {
            setExpandedIds(new Set(employers.map((e: any) => e.employer_id)));
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [data]);

    const toggleExpand = (id: string) => {
        setExpandedIds((prev) => {
            const next = new Set(prev);
            if (next.has(id)) next.delete(id);
            else next.add(id);
            return next;
        });
    };

    const allExpanded = employers.length > 0 && employers.every((e: any) => expandedIds.has(e.employer_id));
    const toggleAll = () => {
        if (allExpanded) setExpandedIds(new Set());
        else setExpandedIds(new Set(employers.map((e: any) => e.employer_id)));
    };

    const openRecords = (payPeriodId: string, employerName: string, periodLabel: string) => {
        setDetailModal({ open: true, payPeriodId, employerName, periodLabel });
    };

    // Records modal totals
    const records: any[] = recordsData || [];
    const totalNet = records.reduce((s, r) => s + Number(r.netPay || 0), 0);
    const totalGross = records.reduce((s, r) => s + Number(r.grossSalary || 0), 0);
    const totalPaye = records.reduce((s, r) => s + Number(r.payeTax || 0), 0);

    const TOTAL_PAGES = Math.ceil((data?.total || 0) / 20);

    return (
        <div>
            {/* Header */}
            <div style={{ marginBottom: 20 }}>
                <Title level={3} style={{ margin: 0 }}>Payroll</Title>
                <Text style={{ color: '#64748b', fontSize: 14 }}>Monitor payroll activity and payment volumes across all employers</Text>
            </div>

            {/* KPI Cards */}
            <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', marginBottom: 24 }}>
                <StatCard
                    label="Total Pay Periods"
                    value={dashboardLoading ? '—' : totalPeriods}
                    color="#6366f1" bg="#eef2ff"
                    icon={<CalendarOutlined />}
                />
                <StatCard
                    label="Successful Periods"
                    value={dashboardLoading ? '—' : successfulPeriods}
                    color="#10b981" bg="#ecfdf5"
                    icon={<CheckCircleOutlined />}
                    sub={
                        totalPeriods > 0 ? (
                            <Tooltip title={`${successfulPeriods} of ${totalPeriods} periods paid successfully`}>
                                <div>
                                    <Progress percent={successRate} size="small" strokeColor="#10b981" showInfo={false} style={{ marginBottom: 2 }} />
                                    <div style={{ fontSize: 11, color: '#94a3b8' }}>{successRate}% success rate</div>
                                </div>
                            </Tooltip>
                        ) : null
                    }
                />
                <StatCard
                    label="Total Net Pay Volume"
                    value={dashboardLoading ? '—' : (
                        <>
                            <span style={{ fontSize: 13, color: '#94a3b8', marginRight: 4 }}>KES</span>
                            {fmtKES(summary?.totalVolume || 0)}
                        </>
                    ) as any}
                    color="#f59e0b" bg="#fffbeb"
                    icon={<DollarOutlined />}
                />
                {/* Payout methods card */}
                <div style={{
                    background: '#fff', borderRadius: 13,
                    padding: '18px 20px', border: '1px solid #e8e8e8',
                    flex: 1, minWidth: 140,
                }}>
                    <div style={{ fontSize: 11, color: '#64748b', marginBottom: 10, fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                        Payout Methods
                    </div>
                    {(summary?.payoutBreakdown || []).length === 0 ? (
                        <div style={{ color: '#94a3b8', fontSize: 13 }}>No data yet</div>
                    ) : (
                        (summary?.payoutBreakdown || []).map((t: any) => {
                            const m = METHOD_STYLE[t.method] || { color: '#64748b', bg: '#f1f5f9', icon: <WalletOutlined /> };
                            return (
                                <div key={t.method} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 7 }}>
                                    <span style={{
                                        display: 'inline-flex', alignItems: 'center', gap: 5,
                                        background: m.bg, color: m.color,
                                        borderRadius: 5, padding: '2px 9px', fontSize: 12, fontWeight: 600,
                                    }}>
                                        {m.icon} {t.method.charAt(0) + t.method.slice(1).toLowerCase()}
                                    </span>
                                    <span style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>
                                        {t.count} <span style={{ color: '#94a3b8', fontWeight: 400, fontSize: 11 }}>txns</span>
                                    </span>
                                </div>
                            );
                        })
                    )}
                </div>
            </div>

            {/* Top-up methods breakdown */}
            {(summary?.topupBreakdown || []).length > 0 && (
                <div style={{
                    background: '#fff', borderRadius: 13, border: '1px solid #e8e8e8',
                    padding: '16px 20px', marginBottom: 24,
                }}>
                    <div style={{ fontSize: 13, fontWeight: 700, color: '#0f172a', marginBottom: 12 }}>Top-up Methods Breakdown</div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                        {(summary?.topupBreakdown || []).map((t: any) => {
                            const m = METHOD_STYLE[t.method] || { color: '#64748b', bg: '#f1f5f9', icon: <WalletOutlined /> };
                            return (
                                <div key={t.method} style={{
                                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                                    padding: '10px 14px', borderRadius: 10,
                                    background: m.bg + '88', border: `1px solid ${m.color}33`,
                                    minWidth: 180, flex: 1,
                                }}>
                                    <Space size={8}>
                                        <span style={{ color: m.color, fontSize: 16 }}>{m.icon}</span>
                                        <span style={{ fontWeight: 600, fontSize: 13, textTransform: 'capitalize' }}>
                                            {t.method.charAt(0) + t.method.slice(1).toLowerCase()}
                                        </span>
                                        <span style={{
                                            background: m.color + '20', color: m.color,
                                            borderRadius: 10, padding: '0 7px', fontSize: 11, fontWeight: 600,
                                        }}>
                                            {t.count} txns
                                        </span>
                                    </Space>
                                    <span style={{ fontWeight: 800, fontSize: 14, color: '#0f172a' }}>
                                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 2 }}>KES</span>
                                        {fmtKES(t.volume)}
                                    </span>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Controls */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, gap: 12, flexWrap: 'wrap' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Title level={4} style={{ margin: 0 }}>All Pay Periods</Title>
                    {employers.length > 0 && (
                        <span
                            onClick={toggleAll}
                            style={{
                                fontSize: 12, fontWeight: 600, cursor: 'pointer',
                                color: '#6366f1', background: '#eef2ff',
                                borderRadius: 20, padding: '3px 12px',
                            }}
                        >
                            {allExpanded ? '− Collapse All' : '+ Expand All'}
                        </span>
                    )}
                </div>
                <Input.Search
                    placeholder="Search by employer…"
                    prefix={<SearchOutlined />}
                    style={{ width: 280 }}
                    allowClear
                    onSearch={(v) => { setSearch(v); setPage(1); }}
                    onChange={(e) => { if (!e.target.value) { setSearch(''); setPage(1); } }}
                />
            </div>

            {/* Employer list */}
            <div style={{ background: '#fff', borderRadius: 14, border: '1px solid #e8e8e8', overflow: 'hidden' }}>
                {/* Column headers */}
                <div style={{
                    display: 'flex', alignItems: 'center', gap: 14,
                    padding: '10px 20px 10px 50px',
                    background: '#f8fafc', borderBottom: '1px solid #e8e8e8',
                    fontSize: 11, fontWeight: 700, color: '#94a3b8',
                    textTransform: 'uppercase', letterSpacing: '0.06em',
                }}>
                    <div style={{ flex: 1 }}>Employer</div>
                    <div style={{ width: 80, textAlign: 'center' }}>Periods</div>
                    <div style={{ width: 150, textAlign: 'right' }}>Lifetime Net</div>
                </div>

                {isLoading ? (
                    <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>Loading payroll data…</div>
                ) : employers.length === 0 ? (
                    <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>No payroll records found</div>
                ) : (
                    employers.map((emp: any) => (
                        <EmployerGroupRow
                            key={emp.employer_id}
                            employer={emp}
                            expanded={expandedIds.has(emp.employer_id)}
                            onToggle={() => toggleExpand(emp.employer_id)}
                            onViewRecords={openRecords}
                        />
                    ))
                )}
            </div>

            {/* Pagination */}
            {TOTAL_PAGES > 1 && (
                <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8, marginTop: 16 }}>
                    <span style={{ fontSize: 13, color: '#64748b' }}>
                        Page {page} of {TOTAL_PAGES} · {data?.total || 0} employers
                    </span>
                    <Button size="small" disabled={page <= 1} onClick={() => setPage(p => p - 1)} style={{ borderRadius: 6 }}>← Prev</Button>
                    {Array.from({ length: Math.min(TOTAL_PAGES, 5) }, (_, i) => {
                        const p = Math.max(1, Math.min(page - 2, TOTAL_PAGES - 4)) + i;
                        return (
                            <Button
                                key={p} size="small"
                                type={p === page ? 'primary' : 'default'}
                                onClick={() => setPage(p)}
                                style={{ borderRadius: 6, minWidth: 32, background: p === page ? '#6366f1' : undefined, borderColor: p === page ? '#6366f1' : undefined }}
                            >
                                {p}
                            </Button>
                        );
                    })}
                    <Button size="small" disabled={page >= TOTAL_PAGES} onClick={() => setPage(p => p + 1)} style={{ borderRadius: 6 }}>Next →</Button>
                </div>
            )}

            {/* Records Modal */}
            <Modal
                title={
                    <div>
                        <div style={{ fontWeight: 700, fontSize: 16 }}>{detailModal.employerName}</div>
                        {detailModal.periodLabel && (
                            <div style={{ fontSize: 13, color: '#64748b', fontWeight: 400, display: 'flex', alignItems: 'center', gap: 6 }}>
                                <CalendarOutlined />
                                {detailModal.periodLabel}
                            </div>
                        )}
                    </div>
                }
                open={detailModal.open}
                onCancel={() => setDetailModal({ open: false })}
                footer={null}
                width={820}
            >
                {/* Summary bar */}
                {records.length > 0 && (
                    <div style={{
                        background: '#f8fafc', borderRadius: 10,
                        padding: '14px 18px', marginBottom: 16,
                        display: 'flex', gap: 0,
                    }}>
                        <div style={{ flex: 1, textAlign: 'center', borderRight: '1px solid #e8e8e8' }}>
                            <div style={{ fontSize: 11, color: '#64748b', marginBottom: 4 }}>Total Gross</div>
                            <div style={{ fontSize: 18, fontWeight: 700 }}>
                                <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>KES</span>
                                {fmtKES(totalGross)}
                            </div>
                        </div>
                        <div style={{ flex: 1, textAlign: 'center', borderRight: '1px solid #e8e8e8' }}>
                            <div style={{ fontSize: 11, color: '#64748b', marginBottom: 4 }}>Total PAYE</div>
                            <div style={{ fontSize: 18, fontWeight: 700, color: '#ef4444' }}>
                                <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>KES</span>
                                {fmtKES(totalPaye)}
                            </div>
                        </div>
                        <div style={{ flex: 1, textAlign: 'center' }}>
                            <div style={{ fontSize: 11, color: '#64748b', marginBottom: 4 }}>Total Net Pay</div>
                            <div style={{ fontSize: 18, fontWeight: 800, color: '#10b981' }}>
                                <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>KES</span>
                                {fmtKES(totalNet)}
                            </div>
                        </div>
                    </div>
                )}

                {/* Column header */}
                <div style={{
                    display: 'flex', alignItems: 'center', gap: 14,
                    padding: '8px 16px',
                    background: '#f8fafc', borderRadius: '8px 8px 0 0',
                    borderBottom: '1px solid #e8e8e8',
                    fontSize: 11, fontWeight: 700, color: '#94a3b8',
                    textTransform: 'uppercase', letterSpacing: '0.06em',
                }}>
                    <div style={{ flex: 1 }}>Worker</div>
                    <div style={{ width: 120, textAlign: 'right' }}>Gross</div>
                    <div style={{ width: 110, textAlign: 'right' }}>PAYE</div>
                    <div style={{ width: 130, textAlign: 'right' }}>Net Pay</div>
                    <div style={{ width: 90 }}>Status</div>
                </div>

                <div style={{ borderRadius: '0 0 8px 8px', overflow: 'hidden', border: '1px solid #f1f5f9', borderTop: 'none' }}>
                    {recordsLoading ? (
                        <div style={{ padding: 32, textAlign: 'center', color: '#94a3b8' }}>Loading records…</div>
                    ) : records.length === 0 ? (
                        <div style={{ padding: 32, textAlign: 'center', color: '#94a3b8' }}>No records found</div>
                    ) : (
                        <>
                            {records.map((r: any) => <RecordRow key={r.id} r={r} />)}
                            {/* Totals footer */}
                            {records.length > 1 && (
                                <div style={{
                                    display: 'flex', alignItems: 'center', gap: 14,
                                    padding: '12px 16px',
                                    background: '#f8fafc', borderTop: '2px solid #e8e8e8',
                                }}>
                                    <div style={{ flex: 1, fontWeight: 700, color: '#0f172a', fontSize: 13 }}>
                                        {records.length} workers
                                    </div>
                                    <div style={{ width: 120, textAlign: 'right', fontWeight: 700, fontSize: 13 }}>
                                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 2 }}>KES</span>
                                        {fmtKES(totalGross)}
                                    </div>
                                    <div style={{ width: 110, textAlign: 'right', fontWeight: 700, fontSize: 13, color: '#ef4444' }}>
                                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 2 }}>KES</span>
                                        {fmtKES(totalPaye)}
                                    </div>
                                    <div style={{ width: 130, textAlign: 'right', fontWeight: 800, fontSize: 14, color: '#10b981' }}>
                                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 2 }}>KES</span>
                                        {fmtKES(totalNet)}
                                    </div>
                                    <div style={{ width: 90 }} />
                                </div>
                            )}
                        </>
                    )}
                </div>
            </Modal>
        </div>
    );
}
