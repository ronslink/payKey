import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Typography, Tag, Button, Modal, Form, Input, DatePicker, InputNumber, Select, Space, message, Tooltip } from 'antd';
import {
    PlusOutlined, DeleteOutlined, CheckCircleOutlined, StopOutlined,
    PercentageOutlined, ThunderboltOutlined, OrderedListOutlined, AppstoreOutlined,
    CalendarOutlined, GlobalOutlined, InfoCircleOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { useState, useMemo } from 'react';
import { adminTaxConfigs } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

// ─── Tax type metadata ───────────────────────────────────────────────────────

const TAX_TYPE: Record<string, { label: string; color: string; bg: string; description: string }> = {
    PAYE: { label: 'PAYE', color: '#6366f1', bg: '#eef2ff', description: 'Pay As You Earn — income tax on employment' },
    NHIF: { label: 'NHIF', color: '#0ea5e9', bg: '#e0f2fe', description: 'National Hospital Insurance Fund contributions' },
    NSSF: { label: 'NSSF', color: '#8b5cf6', bg: '#ede9fe', description: 'National Social Security Fund contributions' },
    SHIF: { label: 'SHIF', color: '#06b6d4', bg: '#e0f9ff', description: 'Social Health Insurance Fund (replaced NHIF 2024)' },
    HOUSING_LEVY: { label: 'Housing Levy', color: '#f59e0b', bg: '#fffbeb', description: 'Affordable Housing Levy — 1.5% of gross' },
    VAT: { label: 'VAT', color: '#10b981', bg: '#ecfdf5', description: 'Value Added Tax on applicable supplies' },
};

const RATE_TYPE: Record<string, { label: string; icon: React.ReactNode; color: string }> = {
    PERCENTAGE: { label: 'Flat %', icon: <PercentageOutlined />, color: '#6366f1' },
    GRADUATED: { label: 'Graduated', icon: <OrderedListOutlined />, color: '#f59e0b' },
    TIERED: { label: 'Tiered', icon: <AppstoreOutlined />, color: '#8b5cf6' },
    BANDED: { label: 'Banded', icon: <ThunderboltOutlined />, color: '#10b981' },
};

const TAX_TYPES_LIST = ['PAYE', 'NHIF', 'NSSF', 'SHIF', 'HOUSING_LEVY', 'VAT'];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function fmtDate(v?: string | null) {
    if (!v) return null;
    return new Date(v).toLocaleDateString('en-KE', { day: 'numeric', month: 'short', year: 'numeric' });
}

function fmtKES(v: number) {
    return 'KES ' + Number(v).toLocaleString();
}

// ─── Stat cards ───────────────────────────────────────────────────────────────

function StatCard({ label, value, color, bg, icon, active }: {
    label: string; value: number; color: string; bg: string; icon: React.ReactNode; active: boolean;
}) {
    return (
        <div style={{
            background: active ? bg : '#f8fafc',
            borderRadius: 12,
            padding: '16px 20px',
            border: `1.5px solid ${active ? color + '55' : '#e8e8e8'}`,
            flex: 1,
            minWidth: 120,
            transition: 'all 0.15s',
        }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                    <div style={{ fontSize: 11, color: '#64748b', marginBottom: 6, fontWeight: 500, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{label}</div>
                    <div style={{ fontSize: 28, fontWeight: 700, lineHeight: 1, color: active ? color : '#94a3b8' }}>{value}</div>
                </div>
                <div style={{
                    width: 38, height: 38, borderRadius: 10,
                    background: active ? color + '20' : '#e2e8f0',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 17, color: active ? color : '#94a3b8',
                }}>
                    {icon}
                </div>
            </div>
        </div>
    );
}

// ─── Configuration display ────────────────────────────────────────────────────

function ConfigDisplay({ rateType, config }: { rateType: string; config: any }) {
    if (!config) return <span style={{ color: '#94a3b8' }}>—</span>;

    if (rateType === 'PERCENTAGE') {
        return (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                {config.percentage != null && (
                    <span style={{
                        display: 'inline-flex', alignItems: 'center', gap: 4,
                        background: '#eef2ff', color: '#6366f1', borderRadius: 6,
                        padding: '3px 10px', fontSize: 13, fontWeight: 600,
                    }}>
                        <PercentageOutlined style={{ fontSize: 11 }} />
                        {config.percentage}%
                    </span>
                )}
                {config.minAmount != null && (
                    <Tooltip title="Minimum deductible amount">
                        <span style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            background: '#f0fdf4', color: '#16a34a', borderRadius: 6,
                            padding: '3px 10px', fontSize: 12,
                        }}>
                            Min {fmtKES(config.minAmount)}
                        </span>
                    </Tooltip>
                )}
                {config.maxAmount != null && (
                    <Tooltip title="Maximum deductible amount">
                        <span style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            background: '#fef9c3', color: '#a16207', borderRadius: 6,
                            padding: '3px 10px', fontSize: 12,
                        }}>
                            Max {fmtKES(config.maxAmount)}
                        </span>
                    </Tooltip>
                )}
            </div>
        );
    }

    if (rateType === 'GRADUATED' && config.brackets) {
        return (
            <div>
                {config.personalRelief != null && (
                    <div style={{ marginBottom: 6 }}>
                        <span style={{
                            display: 'inline-flex', gap: 4,
                            background: '#f0fdf4', color: '#16a34a', borderRadius: 6,
                            padding: '2px 9px', fontSize: 12, fontWeight: 500,
                        }}>
                            Relief {fmtKES(config.personalRelief)}
                        </span>
                    </div>
                )}
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                    {config.brackets.map((b: any, i: number) => (
                        <Tooltip
                            key={i}
                            title={b.to ? `${fmtKES(b.from)} – ${fmtKES(b.to)}` : `${fmtKES(b.from)}+`}
                        >
                            <span style={{
                                display: 'inline-flex', alignItems: 'center',
                                background: '#faf5ff', color: '#7c3aed',
                                borderRadius: 5, padding: '2px 8px', fontSize: 12, fontWeight: 600,
                                cursor: 'default',
                            }}>
                                {b.rate * 100}%
                            </span>
                        </Tooltip>
                    ))}
                </div>
                <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 4 }}>
                    {config.brackets.length} bracket{config.brackets.length !== 1 ? 's' : ''} — hover for ranges
                </div>
            </div>
        );
    }

    if (rateType === 'TIERED' && config.tiers) {
        return (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {config.tiers.map((t: any, i: number) => (
                    <Tooltip
                        key={i}
                        title={`${t.name}: ${t.salaryFrom}–${t.salaryTo || '∞'} → ${t.rate != null ? (t.rate * 100) + '%' : 'KES ' + t.amount}`}
                    >
                        <span style={{
                            display: 'inline-flex', alignItems: 'center', gap: 4,
                            background: '#fffbeb', color: '#d97706',
                            borderRadius: 5, padding: '2px 9px', fontSize: 12, fontWeight: 600,
                            cursor: 'default',
                        }}>
                            {t.name}
                        </span>
                    </Tooltip>
                ))}
                <div style={{ width: '100%', fontSize: 11, color: '#94a3b8', marginTop: 2 }}>
                    {config.tiers.length} tier{config.tiers.length !== 1 ? 's' : ''} — hover for detail
                </div>
            </div>
        );
    }

    return (
        <span style={{ display: 'inline-flex', gap: 4, background: '#f1f5f9', color: '#64748b', borderRadius: 5, padding: '2px 9px', fontSize: 12 }}>
            <InfoCircleOutlined /> Complex config
        </span>
    );
}

// ─── Tax Config Row ───────────────────────────────────────────────────────────

function TaxRow({
    record,
    canEdit,
    onEdit,
    onDeactivate,
    deactivating,
}: {
    record: any;
    canEdit: boolean;
    onEdit: (r: any) => void;
    onDeactivate: (id: string) => void;
    deactivating: boolean;
}) {
    const tt = TAX_TYPE[record.taxType] || { label: record.taxType, color: '#64748b', bg: '#f1f5f9' };
    const rt = RATE_TYPE[record.rateType] || { label: record.rateType, icon: <PercentageOutlined />, color: '#64748b' };
    const from = fmtDate(record.effectiveFrom);
    const to = fmtDate(record.effectiveTo);
    const active = record.isActive;

    return (
        <div style={{
            display: 'flex', alignItems: 'center', gap: 16,
            padding: '14px 20px',
            background: '#fff',
            borderBottom: '1px solid #f1f5f9',
            transition: 'background 0.12s',
        }}
            onMouseEnter={e => (e.currentTarget.style.background = '#fafbff')}
            onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
        >
            {/* Tax type pill */}
            <div style={{ width: 130, flexShrink: 0 }}>
                <Tooltip title={tt.description}>
                    <span style={{
                        display: 'inline-flex', alignItems: 'center', gap: 6,
                        background: tt.bg, color: tt.color,
                        borderRadius: 8, padding: '5px 12px',
                        fontSize: 13, fontWeight: 700, cursor: 'default',
                    }}>
                        {tt.label}
                    </span>
                </Tooltip>
            </div>

            {/* Country */}
            <div style={{ width: 60, flexShrink: 0, display: 'flex', alignItems: 'center', gap: 5 }}>
                <GlobalOutlined style={{ color: '#94a3b8', fontSize: 12 }} />
                <span style={{ fontSize: 13, fontWeight: 600, color: '#475569' }}>{record.country}</span>
            </div>

            {/* Rate type badge */}
            <div style={{ width: 110, flexShrink: 0 }}>
                <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 5,
                    background: rt.color + '15', color: rt.color,
                    borderRadius: 6, padding: '3px 10px', fontSize: 12, fontWeight: 600,
                }}>
                    {rt.icon} {rt.label}
                </span>
            </div>

            {/* Configuration */}
            <div style={{ flex: 1, minWidth: 0 }}>
                <ConfigDisplay rateType={record.rateType} config={record.configuration} />
            </div>

            {/* Effective dates */}
            <div style={{ width: 160, flexShrink: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, color: '#64748b' }}>
                    <CalendarOutlined style={{ fontSize: 11 }} />
                    {from ? (
                        <span>{from} → {to || <span style={{ color: '#10b981', fontWeight: 600 }}>Present</span>}</span>
                    ) : (
                        <span style={{ color: '#94a3b8' }}>No date set</span>
                    )}
                </div>
            </div>

            {/* Active status */}
            <div style={{ width: 80, flexShrink: 0 }}>
                <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 5,
                    background: active ? '#dcfce7' : '#fee2e2',
                    color: active ? '#16a34a' : '#dc2626',
                    borderRadius: 6, padding: '3px 10px', fontSize: 12, fontWeight: 600,
                }}>
                    {active ? <CheckCircleOutlined /> : <StopOutlined />}
                    {active ? 'Active' : 'Inactive'}
                </span>
            </div>

            {/* Actions */}
            {canEdit && (
                <div style={{ flexShrink: 0, display: 'flex', gap: 6 }}>
                    <Button size="small" type="default" onClick={() => onEdit(record)}
                        style={{ borderRadius: 6, fontSize: 12 }}>
                        Edit
                    </Button>
                    {active && (
                        <Button
                            size="small" danger
                            loading={deactivating}
                            onClick={() => onDeactivate(record.id)}
                            style={{ borderRadius: 6, fontSize: 12 }}
                        >
                            Deactivate
                        </Button>
                    )}
                </div>
            )}
        </div>
    );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function TaxConfigPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [createModal, setCreateModal] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [filterType, setFilterType] = useState<string | null>(null);
    const [filterActive, setFilterActive] = useState<boolean | null>(null);
    const [form] = Form.useForm();
    const rateType = Form.useWatch('rateType', form);

    const { data = [], isLoading } = useQuery({ queryKey: ['admin-tax-configs'], queryFn: adminTaxConfigs.list });

    const saveMut = useMutation({
        mutationFn: (vals: any) => {
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            const { country, id, createdAt, updatedAt, ...rest } = vals;
            const payload = {
                ...rest,
                effectiveFrom: vals.effectiveFrom ? vals.effectiveFrom.toISOString() : undefined,
                effectiveTo: vals.effectiveTo ? vals.effectiveTo.toISOString() : undefined,
            };
            return editingId ? adminTaxConfigs.update(editingId, payload) : adminTaxConfigs.create(payload);
        },
        onSuccess: () => {
            message.success(`Tax config ${editingId ? 'updated' : 'created'}`);
            setCreateModal(false);
            setEditingId(null);
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-tax-configs'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Save failed'),
    });

    const deactivateMut = useMutation({
        mutationFn: (id: string) => adminTaxConfigs.deactivate(id),
        onSuccess: () => {
            message.success('Deactivated');
            qc.invalidateQueries({ queryKey: ['admin-tax-configs'] });
        },
    });

    // Stats
    const stats = useMemo(() => {
        const active = (data as any[]).filter((r: any) => r.isActive).length;
        const inactive = (data as any[]).length - active;
        const byType: Record<string, number> = {};
        (data as any[]).forEach((r: any) => { byType[r.taxType] = (byType[r.taxType] || 0) + 1; });
        return { active, inactive, total: (data as any[]).length, byType };
    }, [data]);

    const filtered = useMemo(() => {
        let rows = data as any[];
        if (filterType) rows = rows.filter((r: any) => r.taxType === filterType);
        if (filterActive !== null) rows = rows.filter((r: any) => r.isActive === filterActive);
        return rows;
    }, [data, filterType, filterActive]);

    // Group by tax type for display
    const grouped = useMemo(() => {
        const map = new Map<string, any[]>();
        filtered.forEach((r: any) => {
            if (!map.has(r.taxType)) map.set(r.taxType, []);
            map.get(r.taxType)!.push(r);
        });
        return map;
    }, [filtered]);

    const openEdit = (r: any) => {
        form.setFieldsValue({
            ...r,
            effectiveFrom: r.effectiveFrom ? dayjs(r.effectiveFrom) : undefined,
            effectiveTo: r.effectiveTo ? dayjs(r.effectiveTo) : undefined,
        });
        setEditingId(r.id);
        setCreateModal(true);
    };

    return (
        <div>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 }}>
                <div>
                    <Title level={3} style={{ margin: 0 }}>Tax Configurations</Title>
                    <Text style={{ color: '#64748b', fontSize: 14 }}>Manage statutory deduction rules and tax brackets for Kenya payroll</Text>
                </div>
                {canEdit && (
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        style={{ background: '#6366f1', borderColor: '#6366f1', borderRadius: 8 }}
                        onClick={() => {
                            form.resetFields();
                            setEditingId(null);
                            form.setFieldsValue({ rateType: 'PERCENTAGE', country: 'KE' });
                            setCreateModal(true);
                        }}
                    >
                        Add Config
                    </Button>
                )}
            </div>

            {/* Stat cards */}
            {!isLoading && (
                <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 20 }}>
                    <StatCard
                        label="Total Configs"
                        value={stats.total}
                        color="#6366f1" bg="#eef2ff"
                        icon={<AppstoreOutlined />}
                        active={filterActive === null && filterType === null}
                    />
                    <div
                        onClick={() => setFilterActive(filterActive === true ? null : true)}
                        style={{ flex: 1, minWidth: 120, cursor: 'pointer' }}
                    >
                        <StatCard
                            label="Active"
                            value={stats.active}
                            color="#16a34a" bg="#dcfce7"
                            icon={<CheckCircleOutlined />}
                            active={filterActive === true}
                        />
                    </div>
                    <div
                        onClick={() => setFilterActive(filterActive === false ? null : false)}
                        style={{ flex: 1, minWidth: 120, cursor: 'pointer' }}
                    >
                        <StatCard
                            label="Inactive"
                            value={stats.inactive}
                            color="#dc2626" bg="#fee2e2"
                            icon={<StopOutlined />}
                            active={filterActive === false}
                        />
                    </div>
                </div>
            )}

            {/* Tax type filter pills */}
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginBottom: 20 }}>
                <span
                    onClick={() => setFilterType(null)}
                    style={{
                        display: 'inline-flex', alignItems: 'center',
                        background: filterType === null ? '#6366f1' : '#f1f5f9',
                        color: filterType === null ? '#fff' : '#64748b',
                        borderRadius: 20, padding: '4px 14px', fontSize: 12, fontWeight: 600,
                        cursor: 'pointer', transition: 'all 0.12s',
                    }}
                >
                    All Types
                </span>
                {TAX_TYPES_LIST.map((t) => {
                    const tt = TAX_TYPE[t];
                    const isActive = filterType === t;
                    const count = stats.byType[t] || 0;
                    if (count === 0) return null;
                    return (
                        <span
                            key={t}
                            onClick={() => setFilterType(isActive ? null : t)}
                            style={{
                                display: 'inline-flex', alignItems: 'center', gap: 6,
                                background: isActive ? tt.color : tt.bg,
                                color: isActive ? '#fff' : tt.color,
                                borderRadius: 20, padding: '4px 14px',
                                fontSize: 12, fontWeight: 600,
                                cursor: 'pointer', transition: 'all 0.12s',
                            }}
                        >
                            {tt.label}
                            <span style={{
                                background: isActive ? 'rgba(255,255,255,0.25)' : tt.color + '25',
                                borderRadius: 10, padding: '0px 6px', fontSize: 11,
                            }}>
                                {count}
                            </span>
                        </span>
                    );
                })}
            </div>

            {/* Config list */}
            <div style={{ background: '#fff', borderRadius: 14, border: '1px solid #e8e8e8', overflow: 'hidden' }}>
                {/* Column header */}
                <div style={{
                    display: 'flex', alignItems: 'center', gap: 16,
                    padding: '10px 20px',
                    background: '#f8fafc',
                    borderBottom: '1px solid #e8e8e8',
                    fontSize: 11, fontWeight: 700,
                    color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.06em',
                }}>
                    <div style={{ width: 130, flexShrink: 0 }}>Tax Type</div>
                    <div style={{ width: 60, flexShrink: 0 }}>Country</div>
                    <div style={{ width: 110, flexShrink: 0 }}>Rate Type</div>
                    <div style={{ flex: 1 }}>Configuration</div>
                    <div style={{ width: 160, flexShrink: 0 }}>Effective Period</div>
                    <div style={{ width: 80, flexShrink: 0 }}>Status</div>
                    {canEdit && <div style={{ width: 130, flexShrink: 0 }}>Actions</div>}
                </div>

                {isLoading ? (
                    <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>Loading…</div>
                ) : filtered.length === 0 ? (
                    <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>
                        No tax configurations found
                    </div>
                ) : (
                    /* Group by tax type */
                    Array.from(grouped.entries()).map(([taxType, rows]) => {
                        const tt = TAX_TYPE[taxType] || { label: taxType, color: '#64748b', bg: '#f1f5f9', description: '' };
                        return (
                            <div key={taxType}>
                                {/* Group label */}
                                <div style={{
                                    padding: '8px 20px',
                                    background: tt.bg + '88',
                                    borderBottom: '1px solid ' + tt.color + '22',
                                    display: 'flex', alignItems: 'center', gap: 8,
                                }}>
                                    <span style={{
                                        fontSize: 12, fontWeight: 700, color: tt.color,
                                        textTransform: 'uppercase', letterSpacing: '0.05em',
                                    }}>
                                        {tt.label}
                                    </span>
                                    <span style={{
                                        background: tt.color + '20', color: tt.color,
                                        borderRadius: 10, padding: '0 7px', fontSize: 11, fontWeight: 600,
                                    }}>
                                        {rows.length}
                                    </span>
                                    {tt.description && (
                                        <Tooltip title={tt.description}>
                                            <InfoCircleOutlined style={{ color: tt.color, fontSize: 12, opacity: 0.7 }} />
                                        </Tooltip>
                                    )}
                                </div>
                                {rows.map((r: any) => (
                                    <TaxRow
                                        key={r.id}
                                        record={r}
                                        canEdit={canEdit}
                                        onEdit={openEdit}
                                        onDeactivate={(id) => deactivateMut.mutate(id)}
                                        deactivating={deactivateMut.isPending}
                                    />
                                ))}
                            </div>
                        );
                    })
                )}
            </div>

            {/* Create / Edit Modal */}
            <Modal
                title={
                    <div>
                        <div style={{ fontWeight: 700, fontSize: 16 }}>
                            {editingId ? 'Edit Tax Configuration' : 'New Tax Configuration'}
                        </div>
                        <div style={{ fontSize: 13, color: '#64748b', fontWeight: 400 }}>
                            {editingId ? 'Modify an existing tax rule' : 'Add a new statutory deduction rule'}
                        </div>
                    </div>
                }
                open={createModal}
                onCancel={() => { setCreateModal(false); setEditingId(null); form.resetFields(); }}
                onOk={() => form.submit()}
                confirmLoading={saveMut.isPending}
                width={700}
                styles={{ body: { paddingTop: 8 } }}
            >
                <Form form={form} layout="vertical" onFinish={(v) => saveMut.mutate(v)}>
                    <div style={{ display: 'flex', gap: 12 }}>
                        <Form.Item label="Tax Type" name="taxType" rules={[{ required: true }]} style={{ flex: 1 }}>
                            <Select disabled={!!editingId}>
                                {TAX_TYPES_LIST.map((t) => (
                                    <Select.Option key={t} value={t}>
                                        <span style={{ color: TAX_TYPE[t]?.color, fontWeight: 600 }}>{TAX_TYPE[t]?.label || t}</span>
                                    </Select.Option>
                                ))}
                            </Select>
                        </Form.Item>
                        <Form.Item label="Country" name="country" initialValue="KE" rules={[{ required: true }]} style={{ width: 90 }}>
                            <Input disabled={!!editingId} />
                        </Form.Item>
                        <Form.Item label="Rate Type" name="rateType" initialValue="PERCENTAGE" rules={[{ required: true }]} style={{ flex: 1 }}>
                            <Select>
                                {Object.entries(RATE_TYPE).map(([k, v]) => (
                                    <Select.Option key={k} value={k}>
                                        <span style={{ color: v.color }}>
                                            {v.icon} {v.label}
                                        </span>
                                    </Select.Option>
                                ))}
                            </Select>
                        </Form.Item>
                    </div>

                    <div style={{
                        padding: '10px 14px', borderRadius: 8,
                        background: '#fffbeb', border: '1px solid #fde68a',
                        marginBottom: 16, display: 'flex', gap: 8, alignItems: 'flex-start',
                    }}>
                        <InfoCircleOutlined style={{ color: '#f59e0b', marginTop: 2 }} />
                        <Text style={{ fontSize: 13, color: '#92400e' }}>
                            Changes apply to future payroll runs only. Previous pay periods will not be retroactively updated.
                        </Text>
                    </div>

                    {rateType === 'PERCENTAGE' && (
                        <>
                            <Form.Item label="Percentage Rate (%)" name={['configuration', 'percentage']}>
                                <InputNumber min={0} max={100} step={0.01} style={{ width: '100%' }} addonAfter="%" />
                            </Form.Item>
                            <Space style={{ width: '100%' }} size={12}>
                                <Form.Item label="Min Amount (KES)" name={['configuration', 'minAmount']} style={{ flex: 1 }}>
                                    <InputNumber min={0} style={{ width: '100%' }} addonBefore="KES" />
                                </Form.Item>
                                <Form.Item label="Max Amount (KES)" name={['configuration', 'maxAmount']} style={{ flex: 1 }}>
                                    <InputNumber min={0} style={{ width: '100%' }} addonBefore="KES" />
                                </Form.Item>
                            </Space>
                        </>
                    )}

                    {rateType === 'GRADUATED' && (
                        <div style={{ padding: 16, background: '#faf5ff', borderRadius: 8, marginBottom: 16, border: '1px solid #ede9fe' }}>
                            <Form.Item label="Personal Relief (KES)" name={['configuration', 'personalRelief']}>
                                <InputNumber min={0} style={{ width: '100%' }} addonBefore="KES" />
                            </Form.Item>
                            <Title level={5} style={{ marginTop: 0, color: '#7c3aed' }}>Tax Brackets</Title>
                            <Form.List name={['configuration', 'brackets']}>
                                {(fields, { add, remove }) => (
                                    <>
                                        {fields.map(({ key, name, ...restField }) => (
                                            <Space key={key} style={{ display: 'flex', marginBottom: 8 }} align="baseline" wrap>
                                                <Form.Item {...restField} name={[name, 'from']} rules={[{ required: true, message: 'Missing' }]}>
                                                    <InputNumber placeholder="From (KES)" min={0} />
                                                </Form.Item>
                                                <Form.Item {...restField} name={[name, 'to']}>
                                                    <InputNumber placeholder="To (KES, blank=∞)" min={0} />
                                                </Form.Item>
                                                <Form.Item {...restField} name={[name, 'rate']} rules={[{ required: true, message: 'Missing' }]}>
                                                    <InputNumber placeholder="Rate (0–1)" min={0} max={1} step={0.01} />
                                                </Form.Item>
                                                <DeleteOutlined onClick={() => remove(name)} style={{ color: '#dc2626', cursor: 'pointer' }} />
                                            </Space>
                                        ))}
                                        <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                                            Add Bracket
                                        </Button>
                                    </>
                                )}
                            </Form.List>
                        </div>
                    )}

                    {rateType === 'TIERED' && (
                        <div style={{ padding: 16, background: '#fffbeb', borderRadius: 8, marginBottom: 16, border: '1px solid #fde68a' }}>
                            <Title level={5} style={{ marginTop: 0, color: '#d97706' }}>Salary Tiers</Title>
                            <Form.List name={['configuration', 'tiers']}>
                                {(fields, { add, remove }) => (
                                    <>
                                        {fields.map(({ key, name, ...restField }) => (
                                            <div key={key} style={{ border: '1px solid #fde68a', padding: 14, marginBottom: 12, borderRadius: 8, background: '#fff' }}>
                                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                                                    <Text strong style={{ color: '#d97706' }}>Tier {name + 1}</Text>
                                                    <DeleteOutlined onClick={() => remove(name)} style={{ color: '#dc2626', cursor: 'pointer' }} />
                                                </div>
                                                <Space wrap>
                                                    <Form.Item {...restField} name={[name, 'name']} rules={[{ required: true }]}>
                                                        <Input placeholder="Tier name (e.g. Band 1)" />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'salaryFrom']} rules={[{ required: true }]}>
                                                        <InputNumber placeholder="Salary From (KES)" min={0} />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'salaryTo']}>
                                                        <InputNumber placeholder="Salary To (KES)" min={0} />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'rate']}>
                                                        <InputNumber placeholder="Rate (0–1)" min={0} max={1} step={0.01} />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'amount']}>
                                                        <InputNumber placeholder="Fixed (KES)" min={0} />
                                                    </Form.Item>
                                                </Space>
                                            </div>
                                        ))}
                                        <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                                            Add Tier
                                        </Button>
                                    </>
                                )}
                            </Form.List>
                        </div>
                    )}

                    <Form.Item label="Effective From" name="effectiveFrom">
                        <DatePicker style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item label="Notes" name="notes">
                        <Input.TextArea rows={2} placeholder="Optional internal notes about this configuration…" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
