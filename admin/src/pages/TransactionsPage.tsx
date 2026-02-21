import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Input, Select, Typography, Button, Modal, Form, message,
    Space, DatePicker, Alert, Descriptions, Avatar, Tooltip, Row, Col,
} from 'antd';
import {
    SearchOutlined, RollbackOutlined, WarningOutlined,
    UserOutlined, CaretRightOutlined, CaretDownOutlined,
    CreditCardOutlined, MobileOutlined, BankOutlined, WalletOutlined,
} from '@ant-design/icons';
import { adminTransactions } from '../api/client';

const { Title, Text } = Typography;

// ─── Colour maps ──────────────────────────────────────────────────────────────

const STATUS_COLOR: Record<string, string> = {
    SUCCESS: '#22c55e',
    FAILED: '#ef4444',
    PENDING: '#f59e0b',
    CLEARING: '#3b82f6',
    MANUAL_INTERVENTION: '#8b5cf6',
};

const TYPE_COLOR: Record<string, string> = {
    SUBSCRIPTION: '#6366f1',
    SALARY_PAYOUT: '#0ea5e9',
    TOPUP: '#22c55e',
    DEPOSIT: '#22c55e',
    REFUND: '#f97316',
};

const TYPE_BG: Record<string, string> = {
    SUBSCRIPTION: '#eef2ff',
    SALARY_PAYOUT: '#e0f2fe',
    TOPUP: '#dcfce7',
    DEPOSIT: '#dcfce7',
    REFUND: '#fff7ed',
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

const formatAmount = (v: number) =>
    Math.abs(Number(v)).toLocaleString('en-KE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const fmtDate = (v: string) =>
    new Date(v).toLocaleDateString('en-KE', { day: '2-digit', month: 'short', year: 'numeric' });

const fmtTime = (v: string) =>
    new Date(v).toLocaleTimeString('en-KE', { hour: '2-digit', minute: '2-digit' });

const initials = (name: string) =>
    name?.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2) || '?';

const employerColor = (id: string) => {
    const palette = ['#6366f1', '#0ea5e9', '#22c55e', '#f59e0b', '#ec4899', '#8b5cf6', '#14b8a6', '#f97316'];
    let hash = 0;
    for (let i = 0; i < id.length; i++) hash = id.charCodeAt(i) + ((hash << 5) - hash);
    return palette[Math.abs(hash) % palette.length];
};

// ─── Payment method badge ─────────────────────────────────────────────────────

function MethodBadge({ method }: { method: string }) {
    const map: Record<string, { icon: React.ReactNode; label: string; color: string }> = {
        MPESA_STK: { icon: <MobileOutlined />, label: 'M-Pesa', color: '#16a34a' },
        PESALINK: { icon: <BankOutlined />, label: 'PesaLink', color: '#0369a1' },
        CARD: { icon: <CreditCardOutlined />, label: 'Card', color: '#7c3aed' },
        WALLET: { icon: <WalletOutlined />, label: 'Wallet', color: '#b45309' },
        STRIPE: { icon: <CreditCardOutlined />, label: 'Stripe', color: '#6366f1' },
    };
    const m = map[method];
    if (!m) return <Text style={{ fontSize: 11, color: '#cbd5e1' }}>—</Text>;
    return (
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, fontSize: 11, color: m.color, fontWeight: 500 }}>
            {m.icon} {m.label}
        </span>
    );
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface EmployerGroup {
    employer_id: string;
    employer_name: string;
    employer_email: string;
    transactions: any[];
}

// ─── Summary bar ─────────────────────────────────────────────────────────────

function SummaryBar({ data }: { data: any[] }) {
    const total = data.reduce((s, t) => s + Math.abs(Number(t.amount)), 0);
    const success = data.filter(t => t.status === 'SUCCESS').length;
    const failed = data.filter(t => t.status === 'FAILED').length;
    const pending = data.filter(t => t.status === 'PENDING' || t.status === 'CLEARING').length;

    return (
        <Row gutter={12} style={{ marginBottom: 16 }}>
            {[
                { label: 'Total Volume', value: `KES ${formatAmount(total)}`, color: '#6366f1', bg: '#eef2ff' },
                { label: 'Successful', value: String(success), color: '#16a34a', bg: '#dcfce7' },
                { label: 'Pending', value: String(pending), color: '#d97706', bg: '#fef3c7' },
                { label: 'Failed', value: String(failed), color: '#dc2626', bg: '#fee2e2' },
            ].map(({ label, value, color, bg }) => (
                <Col key={label} xs={12} sm={6}>
                    <div style={{ background: bg, borderRadius: 10, padding: '10px 14px' }}>
                        <div style={{ fontSize: 10, color, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.6 }}>{label}</div>
                        <div style={{ fontSize: 18, fontWeight: 800, color, marginTop: 2 }}>{value}</div>
                    </div>
                </Col>
            ))}
        </Row>
    );
}

// ─── Column header for child rows ─────────────────────────────────────────────

function TxTableHeader() {
    return (
        <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            padding: '6px 16px 6px 46px',
            background: '#f8fafc',
            borderBottom: '1px solid #e2e8f0',
        }}>
            {[
                { label: 'Date', w: 80 },
                { label: 'Type', w: 108 },
                { label: 'Worker', flex: 1 },
                { label: 'Method', w: 80 },
                { label: 'Ref', w: 120 },
                { label: 'Status', w: 130 },
                { label: 'Amount', w: 110, right: true },
                { label: '', w: 76 },
            ].map(({ label, w, flex, right }) => (
                <div key={label} style={{ fontSize: 10, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.8, minWidth: w, flex: flex || undefined, textAlign: right ? 'right' : 'left', flexShrink: 0 }}>
                    {label}
                </div>
            ))}
        </div>
    );
}

// ─── Employer group header ────────────────────────────────────────────────────

function EmployerGroupRow({ group, expanded, onToggle }: { group: EmployerGroup; expanded: boolean; onToggle: () => void }) {
    const color = employerColor(group.employer_id);
    const successCount = group.transactions.filter(t => t.status === 'SUCCESS').length;
    const failedCount = group.transactions.filter(t => t.status === 'FAILED').length;
    const pendingCount = group.transactions.filter(t => !['SUCCESS', 'FAILED'].includes(t.status)).length;
    const total = group.transactions.reduce((s, t) => s + Math.abs(Number(t.amount)), 0);

    return (
        <div
            onClick={onToggle}
            style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 16px',
                background: expanded ? '#f5f7ff' : '#fafafa',
                borderBottom: '1px solid #e8eaf0',
                cursor: 'pointer', userSelect: 'none',
                transition: 'background 0.15s',
            }}
        >
            {/* Toggle caret */}
            <span style={{ color: '#94a3b8', fontSize: 11, width: 14, flexShrink: 0 }}>
                {expanded ? <CaretDownOutlined /> : <CaretRightOutlined />}
            </span>

            {/* Avatar */}
            <Avatar size={34} style={{ background: color, fontWeight: 700, fontSize: 13, flexShrink: 0 }}>
                {initials(group.employer_name)}
            </Avatar>

            {/* Name + email */}
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontWeight: 600, fontSize: 13, color: '#1e293b', lineHeight: 1.3 }}>{group.employer_name}</div>
                <div style={{ fontSize: 11, color: '#94a3b8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{group.employer_email}</div>
            </div>

            {/* Status pills */}
            <Space size={4} style={{ flexShrink: 0 }}>
                {successCount > 0 && (
                    <Tooltip title={`${successCount} successful`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#dcfce7', color: '#16a34a', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#16a34a', display: 'inline-block' }} />{successCount}
                        </span>
                    </Tooltip>
                )}
                {pendingCount > 0 && (
                    <Tooltip title={`${pendingCount} pending/clearing`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#fef3c7', color: '#d97706', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#d97706', display: 'inline-block' }} />{pendingCount}
                        </span>
                    </Tooltip>
                )}
                {failedCount > 0 && (
                    <Tooltip title={`${failedCount} failed`}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#fee2e2', color: '#dc2626', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
                            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#dc2626', display: 'inline-block' }} />{failedCount}
                        </span>
                    </Tooltip>
                )}
            </Space>

            {/* Tx count */}
            <div style={{ textAlign: 'center', minWidth: 48, flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#475569' }}>{group.transactions.length}</div>
                <div style={{ fontSize: 10, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.5 }}>txns</div>
            </div>

            {/* Total */}
            <div style={{ textAlign: 'right', minWidth: 120, flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 14, color: '#1e293b' }}>KES {formatAmount(total)}</div>
                <div style={{ fontSize: 10, color: '#94a3b8' }}>total volume</div>
            </div>
        </div>
    );
}

// ─── Transaction child row ────────────────────────────────────────────────────

function TxRow({ tx, onRefund }: { tx: any; onRefund: (tx: any) => void }) {
    const typeColor = TYPE_COLOR[tx.type] || '#64748b';
    const typeBg = TYPE_BG[tx.type] || '#f1f5f9';
    const isNegative = Number(tx.amount) < 0;
    const canRefund = tx.status === 'SUCCESS' && tx.type !== 'REFUND';

    return (
        <div style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 16px 10px 46px',
            borderBottom: '1px solid #f1f5f9',
            background: '#fff',
            transition: 'background 0.1s',
        }}>
            {/* Date */}
            <div style={{ minWidth: 80, flexShrink: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 500, color: '#374151' }}>{fmtDate(tx.createdAt)}</div>
                <div style={{ fontSize: 11, color: '#94a3b8' }}>{fmtTime(tx.createdAt)}</div>
            </div>

            {/* Type pill */}
            <span style={{ display: 'inline-block', background: typeBg, color: typeColor, borderRadius: 6, padding: '2px 8px', fontSize: 11, fontWeight: 600, minWidth: 108, textAlign: 'center', flexShrink: 0 }}>
                {tx.type?.replace(/_/g, ' ')}
            </span>

            {/* Worker */}
            <div style={{ flex: 1, minWidth: 0 }}>
                {tx.worker_name
                    ? <span style={{ fontSize: 12, color: '#475569' }}><UserOutlined style={{ fontSize: 10, marginRight: 4, color: '#94a3b8' }} />{tx.worker_name}</span>
                    : <Text style={{ fontSize: 11, color: '#cbd5e1' }}>—</Text>
                }
            </div>

            {/* Method */}
            <div style={{ minWidth: 80, flexShrink: 0 }}><MethodBadge method={tx.paymentMethod} /></div>

            {/* Provider ref */}
            <div style={{ minWidth: 120, flexShrink: 0 }}>
                {tx.providerRef
                    ? <Tooltip title={tx.providerRef}><Text code style={{ fontSize: 10, color: '#64748b' }}>{tx.providerRef.length > 14 ? tx.providerRef.slice(0, 14) + '…' : tx.providerRef}</Text></Tooltip>
                    : <Text style={{ fontSize: 11, color: '#cbd5e1' }}>—</Text>
                }
            </div>

            {/* Status dot + label */}
            <div style={{ minWidth: 130, flexShrink: 0 }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 11, fontWeight: 600, color: STATUS_COLOR[tx.status] || '#64748b' }}>
                    <span style={{ width: 6, height: 6, borderRadius: '50%', background: STATUS_COLOR[tx.status] || '#94a3b8', display: 'inline-block', flexShrink: 0 }} />
                    {tx.status?.replace(/_/g, ' ')}
                </span>
            </div>

            {/* Amount */}
            <div style={{ minWidth: 110, textAlign: 'right', flexShrink: 0 }}>
                <span style={{ fontWeight: 700, fontSize: 13, color: isNegative ? '#ef4444' : '#1e293b' }}>
                    {isNegative ? '−' : ''}KES {formatAmount(tx.amount)}
                </span>
            </div>

            {/* Refund action */}
            <div style={{ minWidth: 76, textAlign: 'right', flexShrink: 0 }}>
                {canRefund
                    ? <Button icon={<RollbackOutlined />} size="small" danger ghost style={{ fontSize: 11 }} onClick={() => onRefund(tx)}>Refund</Button>
                    : <span style={{ display: 'inline-block', width: 76 }} />
                }
            </div>
        </div>
    );
}

// ─── Main page ────────────────────────────────────────────────────────────────

export default function TransactionsPage() {
    const qc = useQueryClient();
    const [search, setSearch] = useState('');
    const [status, setStatus] = useState<string | undefined>();
    const [type, setType] = useState<string | undefined>();
    const [page, setPage] = useState(1);
    const [dateRange, setDateRange] = useState<[string, string] | null>(null);
    const [refundModal, setRefundModal] = useState<{ open: boolean; tx?: any }>({ open: false });
    const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set());
    const [form] = Form.useForm();

    const { data, isLoading } = useQuery({
        queryKey: ['admin-transactions', search, status, type, page, dateRange],
        queryFn: () => adminTransactions.list({
            search: search || undefined,
            status,
            type,
            page,
            startDate: dateRange?.[0],
            endDate: dateRange?.[1],
        }),
    });

    const refundMut = useMutation({
        mutationFn: (vals: { amount?: number; reason: string }) =>
            adminTransactions.refund({ transactionId: refundModal.tx?.id!, ...vals }),
        onSuccess: () => {
            message.success('Refund initiated successfully');
            setRefundModal({ open: false });
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-transactions'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Refund failed'),
    });

    // Group transactions by employer
    const groups = useMemo<EmployerGroup[]>(() => {
        const txns: any[] = data?.data || [];
        const map = new Map<string, EmployerGroup>();
        for (const tx of txns) {
            const id = tx.employer_id || tx.employer_email || 'unknown';
            if (!map.has(id)) {
                map.set(id, {
                    employer_id: id,
                    employer_name: tx.employer_name || tx.employer_email || 'Unknown',
                    employer_email: tx.employer_email || '',
                    transactions: [],
                });
            }
            map.get(id)!.transactions.push(tx);
        }
        return Array.from(map.values());
    }, [data]);

    // Auto-expand all groups when data first loads
    useMemo(() => {
        if (groups.length > 0) {
            setExpandedGroups(new Set(groups.map(g => g.employer_id)));
        }
    }, [data]); // re-run when data changes (new page/filter)

    const toggleGroup = (id: string) =>
        setExpandedGroups(prev => {
            const next = new Set(prev);
            next.has(id) ? next.delete(id) : next.add(id);
            return next;
        });

    const allExpanded = groups.length > 0 && groups.every(g => expandedGroups.has(g.employer_id));
    const toggleAll = () => setExpandedGroups(allExpanded ? new Set() : new Set(groups.map(g => g.employer_id)));

    const openRefund = (tx: any) => { form.resetFields(); setRefundModal({ open: true, tx }); };
    const maxAmount = Math.abs(Number(refundModal.tx?.amount || 0));
    const totalPages = Math.ceil((data?.total || 0) / 20);

    return (
        <div>
            {/* ── Header ─────────────────────────────────────────────────── */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                <Title level={3} style={{ margin: 0 }}>Transactions</Title>
                <Space wrap>
                    <Input.Search
                        placeholder="Search employer, worker…"
                        prefix={<SearchOutlined />}
                        style={{ width: 220 }}
                        allowClear
                        onSearch={(v) => { setSearch(v); setPage(1); }}
                        onChange={(e) => { if (!e.target.value) { setSearch(''); setPage(1); } }}
                    />
                    <DatePicker.RangePicker
                        allowClear
                        onChange={(dates) => {
                            setDateRange(dates?.[0] && dates?.[1] ? [dates[0].toISOString(), dates[1].toISOString()] : null);
                            setPage(1);
                        }}
                    />
                    <Select
                        placeholder="Status"
                        allowClear
                        style={{ width: 160 }}
                        onChange={(v) => { setStatus(v); setPage(1); }}
                        options={['PENDING', 'SUCCESS', 'FAILED', 'CLEARING', 'MANUAL_INTERVENTION'].map(s => ({
                            value: s,
                            label: (
                                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                    <span style={{ width: 8, height: 8, borderRadius: '50%', background: STATUS_COLOR[s], flexShrink: 0, display: 'inline-block' }} />
                                    {s.replace(/_/g, ' ')}
                                </span>
                            ),
                        }))}
                    />
                    <Select
                        placeholder="Type"
                        allowClear
                        style={{ width: 160 }}
                        onChange={(v) => { setType(v); setPage(1); }}
                        options={['SUBSCRIPTION', 'SALARY_PAYOUT', 'TOPUP', 'DEPOSIT', 'REFUND'].map(t => ({
                            value: t,
                            label: (
                                <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                    <span style={{ width: 8, height: 8, borderRadius: 2, background: TYPE_COLOR[t] || '#64748b', flexShrink: 0, display: 'inline-block' }} />
                                    {t.replace(/_/g, ' ')}
                                </span>
                            ),
                        }))}
                    />
                </Space>
            </div>

            {/* ── Summary bar ────────────────────────────────────────────── */}
            {!isLoading && (data?.data?.length ?? 0) > 0 && <SummaryBar data={data!.data} />}

            {/* ── Grouped list ───────────────────────────────────────────── */}
            <div style={{ background: '#fff', borderRadius: 14, border: '1px solid #e2e8f0', overflow: 'hidden' }}>

                {/* Controls bar */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 16px', borderBottom: '1px solid #e8eaf0', background: '#f8fafc' }}>
                    <Text style={{ fontSize: 12, color: '#64748b' }}>
                        {isLoading ? 'Loading…' : `${groups.length} employer${groups.length !== 1 ? 's' : ''} · ${data?.total ?? 0} transactions`}
                    </Text>
                    {groups.length > 0 && (
                        <Button size="small" type="text" style={{ fontSize: 12, color: '#6366f1', fontWeight: 500 }} onClick={toggleAll}>
                            {allExpanded ? 'Collapse all' : 'Expand all'}
                        </Button>
                    )}
                </div>

                {isLoading ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8', fontSize: 14 }}>Loading transactions…</div>
                ) : groups.length === 0 ? (
                    <div style={{ padding: 56, textAlign: 'center', color: '#94a3b8', fontSize: 14 }}>No transactions found</div>
                ) : (
                    groups.map((group) => {
                        const expanded = expandedGroups.has(group.employer_id);
                        return (
                            <div key={group.employer_id}>
                                <EmployerGroupRow group={group} expanded={expanded} onToggle={() => toggleGroup(group.employer_id)} />
                                {expanded && (
                                    <div>
                                        <TxTableHeader />
                                        {group.transactions.map(tx => (
                                            <TxRow key={tx.id} tx={tx} onRefund={openRefund} />
                                        ))}
                                    </div>
                                )}
                            </div>
                        );
                    })
                )}

                {/* Pagination */}
                {!isLoading && (data?.total ?? 0) > 20 && (
                    <div style={{ padding: '12px 16px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 8 }}>
                        <Text style={{ fontSize: 12, color: '#64748b' }}>{data!.total} total</Text>
                        <Button size="small" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</Button>
                        <span style={{ fontSize: 12, color: '#475569', padding: '0 4px' }}>Page {page} of {totalPages}</span>
                        <Button size="small" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next →</Button>
                    </div>
                )}
            </div>

            {/* ── Refund modal ───────────────────────────────────────────── */}
            <Modal
                title={<Space><RollbackOutlined style={{ color: '#ef4444' }} /><span>Initiate Refund</span></Space>}
                open={refundModal.open}
                onCancel={() => setRefundModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={refundMut.isPending}
                okText="Confirm Refund"
                okButtonProps={{ danger: true }}
                width={520}
            >
                {refundModal.tx && (
                    <>
                        <Descriptions size="small" bordered column={2} style={{ marginBottom: 16 }}>
                            <Descriptions.Item label="Employer">{refundModal.tx.employer_name || refundModal.tx.employer_email}</Descriptions.Item>
                            <Descriptions.Item label="Worker">{refundModal.tx.worker_name || '—'}</Descriptions.Item>
                            <Descriptions.Item label="Type">
                                <span style={{ background: TYPE_BG[refundModal.tx.type] || '#f1f5f9', color: TYPE_COLOR[refundModal.tx.type] || '#64748b', borderRadius: 4, padding: '1px 7px', fontSize: 11, fontWeight: 600 }}>
                                    {refundModal.tx.type?.replace(/_/g, ' ')}
                                </span>
                            </Descriptions.Item>
                            <Descriptions.Item label="Date">{new Date(refundModal.tx.createdAt).toLocaleString()}</Descriptions.Item>
                            <Descriptions.Item label="Amount" span={2}>
                                <strong style={{ color: '#6366f1', fontSize: 16 }}>KES {formatAmount(maxAmount)}</strong>
                            </Descriptions.Item>
                            {refundModal.tx.providerRef && (
                                <Descriptions.Item label="Provider Ref" span={2}>
                                    <Text code style={{ fontSize: 12 }}>{refundModal.tx.providerRef}</Text>
                                </Descriptions.Item>
                            )}
                        </Descriptions>
                        <Alert type="warning" icon={<WarningOutlined />} showIcon message="Refunds cannot be undone once initiated." style={{ marginBottom: 16 }} />
                    </>
                )}
                <Form form={form} layout="vertical" onFinish={(v) => refundMut.mutate(v)}>
                    <Form.Item
                        label={`Refund Amount (KES) — max ${formatAmount(maxAmount)}`}
                        name="amount"
                        extra="Leave blank to refund the full amount"
                    >
                        <Input type="number" placeholder={`${maxAmount} (full amount)`} min={1} max={maxAmount} />
                    </Form.Item>
                    <Form.Item label="Reason for Refund" name="reason" rules={[{ required: true, message: 'Please enter a reason' }]}>
                        <Input.TextArea rows={3} placeholder="Describe why this refund is being processed…" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
