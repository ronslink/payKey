import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Input, Typography, Tag, Button, Select, Space, Tooltip, Card, Row, Col, Avatar, Badge } from 'antd';
import {
    SearchOutlined, EyeOutlined, TeamOutlined, CrownOutlined, StarOutlined,
    TrophyOutlined, WalletOutlined, UserOutlined, CheckCircleOutlined, ClockCircleOutlined,
    ExclamationCircleOutlined, StopOutlined,
} from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { adminUsers } from '../api/client';

const { Title, Text } = Typography;

// ─── Tier config ──────────────────────────────────────────────────────────────

const TIER: Record<string, { color: string; bg: string; icon: React.ReactNode; label: string }> = {
    FREE:     { color: '#64748b', bg: '#f8fafc', icon: <UserOutlined />,   label: 'Free' },
    BASIC:    { color: '#2563eb', bg: '#eff6ff', icon: <StarOutlined />,   label: 'Basic' },
    GOLD:     { color: '#d97706', bg: '#fffbeb', icon: <TrophyOutlined />, label: 'Gold' },
    PLATINUM: { color: '#7c3aed', bg: '#faf5ff', icon: <CrownOutlined />,  label: 'Platinum' },
};

// ─── Sub status config ────────────────────────────────────────────────────────

const SUB_STATUS: Record<string, { color: string; bg: string; icon: React.ReactNode }> = {
    ACTIVE:    { color: '#16a34a', bg: '#dcfce7', icon: <CheckCircleOutlined /> },
    PAST_DUE:  { color: '#d97706', bg: '#fef3c7', icon: <ExclamationCircleOutlined /> },
    CANCELLED: { color: '#ef4444', bg: '#fee2e2', icon: <StopOutlined /> },
    EXPIRED:   { color: '#94a3b8', bg: '#f1f5f9', icon: <ClockCircleOutlined /> },
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const fmtKES = (v: number) => Number(v || 0).toLocaleString('en-KE');

const employerColor = (id: string) => {
    const palette = ['#6366f1', '#0ea5e9', '#22c55e', '#f59e0b', '#ec4899', '#8b5cf6', '#14b8a6', '#f97316'];
    let hash = 0;
    for (let i = 0; i < id.length; i++) hash = id.charCodeAt(i) + ((hash << 5) - hash);
    return palette[Math.abs(hash) % palette.length];
};

const initials = (name: string) => name?.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2) || '?';

// ─── Employer card row ────────────────────────────────────────────────────────

function EmployerRow({ r, onClick }: { r: any; onClick: () => void }) {
    const tier   = TIER[r.subscription_tier || 'FREE'];
    const status = SUB_STATUS[r.subscription_status] || null;
    const color  = employerColor(r.id || r.email || '');
    const name   = r.displayName || r.businessName || r.email?.split('@')[0] || '?';

    return (
        <div
            onClick={onClick}
            style={{
                display: 'flex', alignItems: 'center', gap: 14,
                padding: '12px 16px',
                borderBottom: '1px solid #f1f5f9',
                background: '#fff',
                cursor: 'pointer',
                transition: 'background 0.12s',
            }}
            onMouseEnter={e => (e.currentTarget.style.background = '#fafbff')}
            onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
        >
            {/* Avatar */}
            <Avatar size={38} style={{ background: color, fontWeight: 700, fontSize: 14, flexShrink: 0 }}>
                {initials(name)}
            </Avatar>

            {/* Name / business */}
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 13, color: '#1e293b', lineHeight: 1.3 }}>{name}</div>
                {r.businessName && r.businessName !== r.displayName && (
                    <div style={{ fontSize: 11, color: '#94a3b8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.businessName}</div>
                )}
                <div style={{ fontSize: 11, color: '#94a3b8', fontFamily: 'monospace' }}>{r.email || r.employer_email}</div>
            </div>

            {/* Tier badge */}
            <div style={{ flexShrink: 0 }}>
                <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                    background: tier.bg, color: tier.color,
                    borderRadius: 20, padding: '3px 10px',
                    fontSize: 11, fontWeight: 700,
                }}>
                    {tier.icon} {tier.label}
                </span>
            </div>

            {/* Sub status */}
            <div style={{ minWidth: 96, flexShrink: 0 }}>
                {status ? (
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 11, fontWeight: 600, color: status.color }}>
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: status.color, display: 'inline-block' }} />
                        {r.subscription_status?.replace('_', ' ')}
                    </span>
                ) : (
                    <Text style={{ fontSize: 11, color: '#cbd5e1' }}>No subscription</Text>
                )}
            </div>

            {/* Workers count */}
            <div style={{ minWidth: 64, textAlign: 'center', flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#6366f1' }}>{r.workerCount || 0}</div>
                <div style={{ fontSize: 10, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.5 }}>workers</div>
            </div>

            {/* Wallet */}
            <div style={{ minWidth: 110, textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: Number(r.walletBalance) > 0 ? '#16a34a' : '#94a3b8' }}>
                    KES {fmtKES(r.walletBalance)}
                </div>
                <div style={{ fontSize: 10, color: '#94a3b8' }}>wallet</div>
            </div>

            {/* Joined */}
            <div style={{ minWidth: 84, textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 11, color: '#64748b' }}>{new Date(r.createdAt).toLocaleDateString('en-KE', { day: '2-digit', month: 'short', year: 'numeric' })}</div>
                <div style={{ fontSize: 10, color: '#94a3b8' }}>joined</div>
            </div>

            {/* View button */}
            <div style={{ flexShrink: 0 }}>
                <Tooltip title="View employer details">
                    <Button icon={<EyeOutlined />} size="small" type="text" onClick={e => { e.stopPropagation(); }} />
                </Tooltip>
            </div>
        </div>
    );
}

// ─── Table header ─────────────────────────────────────────────────────────────

function TableHeader() {
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '7px 16px', background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
            {[
                { label: 'Employer', w: 38 + 14 },      // avatar + gap
                { label: '', flex: 1 },                  // name flex
                { label: 'Plan', w: 90 },
                { label: 'Status', w: 96 },
                { label: 'Workers', w: 64 },
                { label: 'Wallet', w: 110, right: true },
                { label: 'Joined', w: 84, right: true },
                { label: '', w: 32 },
            ].map(({ label, w, flex, right }, i) => (
                <div key={i} style={{ fontSize: 10, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, minWidth: w, flex: flex || undefined, textAlign: right ? 'right' : 'left', flexShrink: 0 }}>
                    {label}
                </div>
            ))}
        </div>
    );
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function UsersPage() {
    const navigate = useNavigate();
    const [search, setSearch] = useState('');
    const [tier, setTier]     = useState<string | undefined>();
    const [subStatus, setSubStatus] = useState<string | undefined>();
    const [page, setPage]     = useState(1);

    const { data, isLoading } = useQuery({
        queryKey: ['admin-users', search, tier, subStatus, page],
        queryFn: () => adminUsers.list({ search: search || undefined, tier, subscriptionStatus: subStatus, page }),
    });

    // Summary query (unfiltered page 1 — for tier breakdown cards)
    const { data: summaryData } = useQuery({
        queryKey: ['admin-users-summary'],
        queryFn: () => adminUsers.list({ page: 1 }),
        staleTime: 60_000,
    });

    const employers       = data?.data || [];
    const total           = data?.total || 0;
    const summaryList     = summaryData?.data || [];
    const tierBreakdown: Record<string, number> = { FREE: 0, BASIC: 0, GOLD: 0, PLATINUM: 0 };
    summaryList.forEach((e: any) => { const t = e.subscription_tier || 'FREE'; if (t in tierBreakdown) tierBreakdown[t]++; });
    const totalWallet = summaryList.reduce((s: number, e: any) => s + Number(e.walletBalance || 0), 0);
    const totalPages  = Math.ceil(total / 20);

    return (
        <div>
            {/* ── Header ─────────────────────────────────────────────────── */}
            <div style={{ marginBottom: 20 }}>
                <Title level={3} style={{ margin: 0 }}>Employers</Title>
                <Text style={{ color: '#64748b', fontSize: 14 }}>All registered employer accounts and their subscription status</Text>
            </div>

            {/* ── Tier stat cards ─────────────────────────────────────────── */}
            <Row gutter={[12, 12]} style={{ marginBottom: 20 }}>
                {(Object.entries(TIER) as [string, typeof TIER[string]][]).map(([key, cfg]) => {
                    const isActive = tier === key;
                    return (
                        <Col key={key} xs={12} sm={6} md={6} lg={3} style={{ flex: '1 1 0' }}>
                            <Card
                                size="small" hoverable
                                onClick={() => { setTier(tier === key ? undefined : key); setPage(1); }}
                                style={{ borderRadius: 12, border: isActive ? `2px solid ${cfg.color}` : '1px solid #e8e8e8', background: isActive ? cfg.bg : '#fff', transition: 'all 0.2s', cursor: 'pointer' }}
                                bodyStyle={{ padding: '12px 14px' }}
                            >
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <div style={{ fontSize: 10, color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>{cfg.label}</div>
                                        <div style={{ fontSize: 22, fontWeight: 800, color: isActive ? cfg.color : '#1e293b', marginTop: 2 }}>
                                            {isLoading ? '—' : tierBreakdown[key] ?? 0}
                                        </div>
                                    </div>
                                    <div style={{ width: 32, height: 32, borderRadius: 8, background: cfg.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, color: cfg.color }}>{cfg.icon}</div>
                                </div>
                            </Card>
                        </Col>
                    );
                })}
                {/* Total wallet card */}
                <Col xs={12} sm={6} md={6} lg={3} style={{ flex: '1 1 0' }}>
                    <Card size="small" style={{ borderRadius: 12, border: '1px solid #e8e8e8', background: '#f0fdf4', cursor: 'default' }} bodyStyle={{ padding: '12px 14px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <div>
                                <div style={{ fontSize: 10, color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5 }}>Total Wallet</div>
                                <div style={{ fontSize: 13, fontWeight: 800, color: '#16a34a', marginTop: 2 }}>KES {fmtKES(totalWallet)}</div>
                            </div>
                            <div style={{ width: 32, height: 32, borderRadius: 8, background: '#dcfce7', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, color: '#16a34a' }}><WalletOutlined /></div>
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* ── Filters ─────────────────────────────────────────────────── */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12, flexWrap: 'wrap', gap: 8 }}>
                <Space wrap>
                    {tier && <Tag closable onClose={() => setTier(undefined)} color="blue" style={{ borderRadius: 12 }}>Plan: {tier}</Tag>}
                    {subStatus && <Tag closable onClose={() => setSubStatus(undefined)} color={subStatus === 'ACTIVE' ? 'green' : 'orange'} style={{ borderRadius: 12 }}>Status: {subStatus.replace('_', ' ')}</Tag>}
                </Space>
                <Space wrap>
                    <Select placeholder="Sub Status" allowClear style={{ width: 150 }} value={subStatus} onChange={v => { setSubStatus(v); setPage(1); }}
                        options={['ACTIVE', 'PAST_DUE', 'CANCELLED', 'EXPIRED'].map(s => ({
                            value: s,
                            label: (
                                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                    <span style={{ width: 8, height: 8, borderRadius: '50%', background: SUB_STATUS[s]?.color, display: 'inline-block' }} />
                                    {s.replace('_', ' ')}
                                </span>
                            ),
                        }))}
                    />
                    <Input.Search placeholder="Search name, email…" prefix={<SearchOutlined />} style={{ width: 260 }} allowClear
                        onSearch={v => { setSearch(v); setPage(1); }}
                        onChange={e => { if (!e.target.value) { setSearch(''); setPage(1); } }}
                    />
                </Space>
            </div>

            {/* ── Employer list ────────────────────────────────────────────── */}
            <div style={{ background: '#fff', borderRadius: 14, border: '1px solid #e2e8f0', overflow: 'hidden' }}>
                {/* Controls bar */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 16px', background: '#f8fafc', borderBottom: '1px solid #e8eaf0' }}>
                    <Text style={{ fontSize: 12, color: '#64748b' }}>
                        {isLoading ? 'Loading…' : `${total} employer${total !== 1 ? 's' : ''}`}
                    </Text>
                </div>

                <TableHeader />

                {isLoading ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8' }}>Loading employers…</div>
                ) : employers.length === 0 ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8' }}>No employers found</div>
                ) : (
                    employers.map((r: any) => (
                        <EmployerRow key={r.id} r={r} onClick={() => navigate(`/users/${r.id}`)} />
                    ))
                )}

                {/* Pagination */}
                {!isLoading && total > 20 && (
                    <div style={{ padding: '12px 16px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8 }}>
                        <Text style={{ fontSize: 12, color: '#64748b' }}>{total} total</Text>
                        <Button size="small" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</Button>
                        <span style={{ fontSize: 12, color: '#475569', padding: '0 4px' }}>Page {page} of {totalPages}</span>
                        <Button size="small" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next →</Button>
                    </div>
                )}
            </div>
        </div>
    );
}
