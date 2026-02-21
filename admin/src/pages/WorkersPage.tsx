import { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Input, Typography, Tag, Select, Space, Card, Row, Col,
    Avatar, Tooltip, Button,
} from 'antd';
import {
    SearchOutlined, TeamOutlined, CheckCircleOutlined, StopOutlined,
    LinkOutlined, MailOutlined, UserOutlined, CaretRightOutlined,
    CaretDownOutlined, MobileOutlined, BankOutlined, WalletOutlined,
} from '@ant-design/icons';
import { adminWorkers } from '../api/client';

const { Title, Text } = Typography;

// ─── Helpers ──────────────────────────────────────────────────────────────────

const employerColor = (id: string) => {
    const palette = ['#6366f1', '#0ea5e9', '#22c55e', '#f59e0b', '#ec4899', '#8b5cf6', '#14b8a6', '#f97316'];
    let hash = 0;
    for (let i = 0; i < id.length; i++) hash = id.charCodeAt(i) + ((hash << 5) - hash);
    return palette[Math.abs(hash) % palette.length];
};

const initials = (name: string) =>
    name?.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2) || '?';

const PAYMENT_METHOD: Record<string, { icon: React.ReactNode; color: string; bg: string }> = {
    MPESA: { icon: <MobileOutlined />, color: '#16a34a', bg: '#dcfce7' },
    BANK:  { icon: <BankOutlined />,   color: '#0369a1', bg: '#e0f2fe' },
    CASH:  { icon: <WalletOutlined />, color: '#b45309', bg: '#fef3c7' },
};

// ─── Types ────────────────────────────────────────────────────────────────────

interface EmployerGroup {
    employer_id: string;
    employer_name: string;
    employer_email: string;
    workers: any[];
}

// ─── Portal status badge ──────────────────────────────────────────────────────

function PortalBadge({ r }: { r: any }) {
    if (r.linkedUserId) return (
        <Tooltip title="Connected to employee portal">
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: '#dcfce7', color: '#16a34a', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                <LinkOutlined /> Connected
            </span>
        </Tooltip>
    );
    if (r.inviteCode) return (
        <Tooltip title={`Invite code: ${r.inviteCode}`}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: '#fef3c7', color: '#d97706', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                <MailOutlined /> Invite Sent
            </span>
        </Tooltip>
    );
    return (
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: '#f1f5f9', color: '#94a3b8', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
            <UserOutlined /> Uninvited
        </span>
    );
}

// ─── Column header ────────────────────────────────────────────────────────────

function WorkerTableHeader() {
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '6px 16px 6px 46px', background: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
            {[
                { label: 'Worker', flex: 1 },
                { label: 'Salary (KES)', w: 120, right: true },
                { label: 'Method', w: 100 },
                { label: 'Portal', w: 120 },
                { label: 'Status', w: 80 },
                { label: 'Added', w: 90, right: true },
            ].map(({ label, w, flex, right }) => (
                <div key={label} style={{ fontSize: 10, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, minWidth: w, flex: flex || undefined, textAlign: right ? 'right' : 'left', flexShrink: 0 }}>
                    {label}
                </div>
            ))}
        </div>
    );
}

// ─── Worker row ───────────────────────────────────────────────────────────────

function WorkerRow({ w }: { w: any }) {
    const pm = PAYMENT_METHOD[w.paymentMethod];
    return (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px 10px 46px', borderBottom: '1px solid #f1f5f9', background: w.isActive ? '#fff' : '#fafafa', opacity: w.isActive ? 1 : 0.72 }}>
            {/* Worker name + phone */}
            <div style={{ flex: 1, minWidth: 0, display: 'flex', alignItems: 'center', gap: 10 }}>
                <Avatar size={30} style={{ background: w.isActive ? '#10b981' : '#94a3b8', fontSize: 12, fontWeight: 700, flexShrink: 0 }}>
                    {(w.worker_name || 'W').charAt(0).toUpperCase()}
                </Avatar>
                <div>
                    <div style={{ fontWeight: 600, fontSize: 13, color: '#1e293b' }}>{w.worker_name}</div>
                    <div style={{ fontSize: 11, color: '#94a3b8', fontFamily: 'monospace' }}>{w.phoneNumber || '—'}</div>
                </div>
            </div>

            {/* Salary */}
            <div style={{ minWidth: 120, textAlign: 'right', flexShrink: 0 }}>
                <span style={{ fontWeight: 700, fontSize: 13, color: '#1e293b' }}>
                    {Number(w.salaryGross || 0).toLocaleString('en-KE')}
                </span>
            </div>

            {/* Payment method */}
            <div style={{ minWidth: 100, flexShrink: 0 }}>
                {pm ? (
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, background: pm.bg, color: pm.color, borderRadius: 6, padding: '2px 7px', fontSize: 11, fontWeight: 600 }}>
                        {pm.icon} {w.paymentMethod}
                    </span>
                ) : <Text style={{ fontSize: 11, color: '#cbd5e1' }}>—</Text>}
            </div>

            {/* Portal status */}
            <div style={{ minWidth: 120, flexShrink: 0 }}>
                <PortalBadge r={w} />
            </div>

            {/* Active status dot */}
            <div style={{ minWidth: 80, flexShrink: 0 }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 11, fontWeight: 600, color: w.isActive ? '#16a34a' : '#ef4444' }}>
                    <span style={{ width: 6, height: 6, borderRadius: '50%', background: w.isActive ? '#16a34a' : '#ef4444', display: 'inline-block' }} />
                    {w.isActive ? 'Active' : 'Inactive'}
                </span>
            </div>

            {/* Added date */}
            <div style={{ minWidth: 90, textAlign: 'right', flexShrink: 0 }}>
                <div style={{ fontSize: 11, color: '#64748b' }}>
                    {new Date(w.createdAt).toLocaleDateString('en-KE', { day: '2-digit', month: 'short', year: 'numeric' })}
                </div>
            </div>
        </div>
    );
}

// ─── Employer group header ────────────────────────────────────────────────────

function EmployerGroupRow({ group, expanded, onToggle }: { group: EmployerGroup; expanded: boolean; onToggle: () => void }) {
    const color        = employerColor(group.employer_id);
    const activeCount  = group.workers.filter(w => w.isActive).length;
    const inactiveCount = group.workers.length - activeCount;
    const connectedCount = group.workers.filter(w => w.linkedUserId).length;
    const totalSalary  = group.workers.reduce((s, w) => s + Number(w.salaryGross || 0), 0);

    return (
        <div
            onClick={onToggle}
            style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px', background: expanded ? '#f5f7ff' : '#fafafa', borderBottom: '1px solid #e8eaf0', cursor: 'pointer', userSelect: 'none', transition: 'background 0.15s' }}
        >
            <span style={{ color: '#94a3b8', fontSize: 11, width: 14, flexShrink: 0 }}>
                {expanded ? <CaretDownOutlined /> : <CaretRightOutlined />}
            </span>
            <Avatar size={34} style={{ background: color, fontWeight: 700, fontSize: 13, flexShrink: 0 }}>
                {initials(group.employer_name)}
            </Avatar>
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 13, color: '#1e293b' }}>{group.employer_name}</div>
                <div style={{ fontSize: 11, color: '#94a3b8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{group.employer_email}</div>
            </div>

            {/* Status pills */}
            <Space size={4} style={{ flexShrink: 0 }}>
                {activeCount > 0 && (
                    <Tooltip title={`${activeCount} active`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#dcfce7', color: '#16a34a', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#16a34a', display: 'inline-block' }} />{activeCount}
                        </span>
                    </Tooltip>
                )}
                {inactiveCount > 0 && (
                    <Tooltip title={`${inactiveCount} inactive`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#fee2e2', color: '#dc2626', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#dc2626', display: 'inline-block' }} />{inactiveCount}
                        </span>
                    </Tooltip>
                )}
                {connectedCount > 0 && (
                    <Tooltip title={`${connectedCount} portal connected`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#e0f2fe', color: '#0369a1', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <LinkOutlined style={{ fontSize: 9 }} />{connectedCount}
                        </span>
                    </Tooltip>
                )}
            </Space>

            {/* Worker count */}
            <div style={{ textAlign: 'center', minWidth: 48, flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#475569' }}>{group.workers.length}</div>
                <div style={{ fontSize: 10, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.5 }}>workers</div>
            </div>

            {/* Monthly payroll */}
            <div style={{ textAlign: 'right', minWidth: 140, flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: '#1e293b' }}>KES {totalSalary.toLocaleString('en-KE')}</div>
                <div style={{ fontSize: 10, color: '#94a3b8' }}>monthly payroll</div>
            </div>
        </div>
    );
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function WorkersPage() {
    const [search, setSearch]             = useState('');
    const [page, setPage]                 = useState(1);
    const [statusFilter, setStatusFilter] = useState<string | undefined>();
    const [methodFilter, setMethodFilter] = useState<string | undefined>();
    const [portalFilter, setPortalFilter] = useState<string | undefined>();
    const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());

    const { data, isLoading } = useQuery({
        queryKey: ['admin-workers', search, page, statusFilter, methodFilter, portalFilter],
        queryFn: () => adminWorkers.list({
            search: search || undefined,
            page,
            isActive: statusFilter === 'active' ? true : statusFilter === 'inactive' ? false : undefined,
            paymentMethod: methodFilter,
            portalStatus: portalFilter,
        }),
    });

    const workers      = data?.data || [];
    const totalWorkers = data?.total || 0;
    const activeCount  = data?.activeCount  ?? workers.filter((w: any) => w.isActive).length;
    const inactiveCount = data?.inactiveCount ?? workers.filter((w: any) => !w.isActive).length;
    const connectedCount = data?.connectedCount ?? workers.filter((w: any) => w.linkedUserId).length;
    const invitedCount = data?.invitedCount  ?? workers.filter((w: any) => !w.linkedUserId && w.inviteCode).length;

    // Group by employer
    const groups = useMemo<EmployerGroup[]>(() => {
        const map = new Map<string, EmployerGroup>();
        for (const w of workers) {
            const id = w.employer_id || w.employer_email || 'unknown';
            if (!map.has(id)) map.set(id, { employer_id: id, employer_name: w.employer_name || w.employer_email || 'Unknown', employer_email: w.employer_email || '', workers: [] });
            map.get(id)!.workers.push(w);
        }
        return Array.from(map.values());
    }, [data]);

    // Auto-expand all on load/filter change
    useMemo(() => {
        if (groups.length > 0) setExpandedGroups(new Set(groups.map(g => g.employer_id)));
    }, [data]);

    const toggleGroup = (id: string) => setExpandedGroups(prev => { const n = new Set(prev); n.has(id) ? n.delete(id) : n.add(id); return n; });
    const allExpanded = groups.length > 0 && groups.every(g => expandedGroups.has(g.employer_id));
    const toggleAll   = () => setExpandedGroups(allExpanded ? new Set() : new Set(groups.map(g => g.employer_id)));
    const totalPages  = Math.ceil(totalWorkers / 20);

    const statCards = [
        { label: 'Total Workers',    value: totalWorkers,   icon: <TeamOutlined />,        color: '#6366f1', bg: '#eef2ff', filter: () => { setStatusFilter(undefined); setPortalFilter(undefined); setPage(1); }, active: !statusFilter && !portalFilter },
        { label: 'Active',           value: activeCount,    icon: <CheckCircleOutlined />, color: '#10b981', bg: '#ecfdf5', filter: () => { setStatusFilter(statusFilter === 'active' ? undefined : 'active'); setPage(1); }, active: statusFilter === 'active' },
        { label: 'Inactive',         value: inactiveCount,  icon: <StopOutlined />,        color: '#ef4444', bg: '#fef2f2', filter: () => { setStatusFilter(statusFilter === 'inactive' ? undefined : 'inactive'); setPage(1); }, active: statusFilter === 'inactive' },
        { label: 'Portal Connected', value: connectedCount, icon: <LinkOutlined />,        color: '#0ea5e9', bg: '#f0f9ff', filter: () => { setPortalFilter(portalFilter === 'connected' ? undefined : 'connected'); setPage(1); }, active: portalFilter === 'connected' },
        { label: 'Invite Sent',      value: invitedCount,   icon: <MailOutlined />,        color: '#f59e0b', bg: '#fffbeb', filter: () => { setPortalFilter(portalFilter === 'invited' ? undefined : 'invited'); setPage(1); }, active: portalFilter === 'invited' },
    ];

    return (
        <div>
            {/* ── Header ─────────────────────────────────────────────────── */}
            <div style={{ marginBottom: 20 }}>
                <Title level={3} style={{ margin: 0 }}>Workers</Title>
                <Text style={{ color: '#64748b', fontSize: 14 }}>All workers registered across employer accounts, grouped by employer</Text>
            </div>

            {/* ── Stat cards ───────────────────────────────────────────────── */}
            <Row gutter={[12, 12]} style={{ marginBottom: 20 }}>
                {statCards.map(s => (
                    <Col key={s.label} xs={12} sm={8} md={4} style={{ flex: '1 1 0' }}>
                        <Card size="small" hoverable onClick={s.filter}
                            style={{ borderRadius: 12, border: s.active ? `2px solid ${s.color}` : '1px solid #e8e8e8', background: s.active ? s.bg : '#fff', transition: 'all 0.2s', cursor: 'pointer' }}
                            bodyStyle={{ padding: '12px 14px' }}
                        >
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <div>
                                    <div style={{ fontSize: 10, color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 3 }}>{s.label}</div>
                                    <div style={{ fontSize: 22, fontWeight: 800, color: s.active ? s.color : '#1e293b' }}>{isLoading ? '—' : s.value}</div>
                                </div>
                                <div style={{ width: 32, height: 32, borderRadius: 8, background: s.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, color: s.color }}>{s.icon}</div>
                            </div>
                        </Card>
                    </Col>
                ))}
            </Row>

            {/* ── Filters ─────────────────────────────────────────────────── */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12, flexWrap: 'wrap', gap: 8, alignItems: 'center' }}>
                <Space wrap>
                    {statusFilter && <Tag closable onClose={() => setStatusFilter(undefined)} color={statusFilter === 'active' ? 'green' : 'red'} style={{ borderRadius: 12 }}>{statusFilter === 'active' ? 'Active Only' : 'Inactive Only'}</Tag>}
                    {portalFilter && <Tag closable onClose={() => setPortalFilter(undefined)} color={portalFilter === 'connected' ? 'blue' : 'orange'} style={{ borderRadius: 12 }}>Portal: {portalFilter === 'connected' ? 'Connected' : 'Invited'}</Tag>}
                    {methodFilter && <Tag closable onClose={() => setMethodFilter(undefined)} style={{ borderRadius: 12 }}>Method: {methodFilter}</Tag>}
                </Space>
                <Space wrap>
                    <Select placeholder="Payment Method" allowClear style={{ width: 150 }} value={methodFilter} onChange={v => { setMethodFilter(v); setPage(1); }}
                        options={['MPESA', 'BANK', 'CASH'].map(m => ({
                            value: m,
                            label: <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: PAYMENT_METHOD[m]?.color, display: 'inline-block' }} />{m}</span>,
                        }))}
                    />
                    <Input.Search placeholder="Search name or employer…" prefix={<SearchOutlined />} style={{ width: 260 }} allowClear
                        onSearch={v => { setSearch(v); setPage(1); }}
                        onChange={e => { if (!e.target.value) { setSearch(''); setPage(1); } }}
                    />
                </Space>
            </div>

            {/* ── Grouped list ───────────────────────────────────────────── */}
            <div style={{ background: '#fff', borderRadius: 14, border: '1px solid #e2e8f0', overflow: 'hidden' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 16px', background: '#f8fafc', borderBottom: '1px solid #e8eaf0' }}>
                    <Text style={{ fontSize: 12, color: '#64748b' }}>
                        {isLoading ? 'Loading…' : `${groups.length} employer${groups.length !== 1 ? 's' : ''} · ${totalWorkers} workers`}
                    </Text>
                    {groups.length > 0 && (
                        <Button size="small" type="text" style={{ fontSize: 12, color: '#6366f1', fontWeight: 500 }} onClick={toggleAll}>
                            {allExpanded ? 'Collapse all' : 'Expand all'}
                        </Button>
                    )}
                </div>

                {isLoading ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8' }}>Loading workers…</div>
                ) : groups.length === 0 ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8' }}>No workers found</div>
                ) : (
                    groups.map(group => {
                        const expanded = expandedGroups.has(group.employer_id);
                        return (
                            <div key={group.employer_id}>
                                <EmployerGroupRow group={group} expanded={expanded} onToggle={() => toggleGroup(group.employer_id)} />
                                {expanded && (
                                    <div>
                                        <WorkerTableHeader />
                                        {group.workers.map(w => <WorkerRow key={w.id} w={w} />)}
                                    </div>
                                )}
                            </div>
                        );
                    })
                )}

                {!isLoading && totalWorkers > 20 && (
                    <div style={{ padding: '12px 16px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8 }}>
                        <Text style={{ fontSize: 12, color: '#64748b' }}>{totalWorkers} total</Text>
                        <Button size="small" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</Button>
                        <span style={{ fontSize: 12, color: '#475569', padding: '0 4px' }}>Page {page} of {totalPages}</span>
                        <Button size="small" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next →</Button>
                    </div>
                )}
            </div>
        </div>
    );
}
