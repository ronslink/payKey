import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Modal, Space, Input, DatePicker, Tooltip, Card, Statistic, Row, Col } from 'antd';
import {
    EyeOutlined, PlusCircleOutlined, EditOutlined, DeleteOutlined,
    LoginOutlined, StopOutlined, UserOutlined, SearchOutlined,
    FilterOutlined, AuditOutlined,
} from '@ant-design/icons';
import { useState } from 'react';
import { adminAuditLogs } from '../api/client';

const { Title, Text } = Typography;

const actionColors: Record<string, string> = {
    CREATE: 'green',
    UPDATE: 'blue',
    DEACTIVATE: 'orange',
    DELETE: 'red',
    LOGIN: 'purple',
};

const actionIcons: Record<string, React.ReactNode> = {
    CREATE: <PlusCircleOutlined />,
    UPDATE: <EditOutlined />,
    DEACTIVATE: <StopOutlined />,
    DELETE: <DeleteOutlined />,
    LOGIN: <LoginOutlined />,
};

// ── JSON diff viewer ──────────────────────────────────────────────────────────
function JsonDiff({ label, data, color }: { label: string; data: any; color: string }) {
    if (!data) {
        return (
            <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                    <div
                        style={{
                            width: 10, height: 10, borderRadius: '50%',
                            background: color, flexShrink: 0,
                        }}
                    />
                    <Text strong style={{ color, fontSize: 13 }}>{label}</Text>
                </div>
                <pre
                    style={{
                        background: '#f8fafc', padding: 16, borderRadius: 10,
                        fontSize: 12, border: '1px solid #e2e8f0',
                        color: '#cbd5e1', minHeight: 80, margin: 0,
                    }}
                >
                    (none)
                </pre>
            </div>
        );
    }

    const highlighted = JSON.stringify(data, null, 2)
        .replace(/("[\w]+")\s*:/g, '<span style="color:#6366f1;font-weight:600">$1</span>:')
        .replace(/:\s*(".*?")/g, ': <span style="color:#16a34a">$1</span>')
        .replace(/:\s*(true|false)/g, ': <span style="color:#ea580c">$1</span>')
        .replace(/:\s*(\d+\.?\d*)/g, ': <span style="color:#0369a1">$1</span>')
        .replace(/:\s*(null)/g, ': <span style="color:#94a3b8">$1</span>');

    return (
        <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <div
                    style={{
                        width: 10, height: 10, borderRadius: '50%',
                        background: color, flexShrink: 0,
                    }}
                />
                <Text strong style={{ color, fontSize: 13 }}>{label}</Text>
            </div>
            <pre
                style={{
                    background: '#f8fafc', padding: 16, borderRadius: 10,
                    fontSize: 12, border: `1px solid ${color}33`,
                    overflowX: 'auto', whiteSpace: 'pre-wrap',
                    wordBreak: 'break-word', maxHeight: 380,
                    overflowY: 'auto', margin: 0,
                }}
                dangerouslySetInnerHTML={{ __html: highlighted }}
            />
        </div>
    );
}

// ── AuditLogsPage ─────────────────────────────────────────────────────────────
export default function AuditLogsPage() {
    const [page, setPage] = useState(1);
    const [action, setAction] = useState<string>();
    const [entityType, setEntityType] = useState<string>();
    const [adminEmail, setAdminEmail] = useState<string>();
    const [dateRange, setDateRange] = useState<[string, string] | null>(null);
    const [detailModal, setDetailModal] = useState<{ open: boolean; log?: any }>({ open: false });

    const { data, isLoading } = useQuery({
        queryKey: ['admin-audit-logs', page, action, entityType, adminEmail, dateRange],
        queryFn: () =>
            adminAuditLogs.list({
                page, action, entityType, adminEmail,
                startDate: dateRange?.[0], endDate: dateRange?.[1],
            }),
    });

    const logs: any[] = data?.data || [];

    // Summary counts from current page
    const createCount    = logs.filter((l) => l.action === 'CREATE').length;
    const updateCount    = logs.filter((l) => l.action === 'UPDATE').length;
    const deleteCount    = logs.filter((l) => l.action === 'DELETE').length;
    const loginCount     = logs.filter((l) => l.action === 'LOGIN').length;

    const columns = [
        {
            title: 'Date & Time',
            dataIndex: 'createdAt',
            key: 'date',
            width: 175,
            render: (v: string) => {
                const d = new Date(v);
                return (
                    <div style={{ lineHeight: 1.4 }}>
                        <div style={{ fontWeight: 500, fontSize: 13, color: '#0f172a' }}>
                            {d.toLocaleDateString()}
                        </div>
                        <div style={{ fontSize: 11, color: '#94a3b8' }}>
                            {d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                        </div>
                    </div>
                );
            },
        },
        {
            title: 'Admin',
            dataIndex: 'adminEmail',
            key: 'admin',
            render: (v: string) => (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div
                        style={{
                            width: 26, height: 26, borderRadius: 8,
                            background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            flexShrink: 0,
                        }}
                    >
                        <UserOutlined style={{ color: '#fff', fontSize: 12 }} />
                    </div>
                    <Text style={{ fontFamily: 'monospace', fontSize: 13 }}>
                        {v || <Text type="secondary">—</Text>}
                    </Text>
                </div>
            ),
        },
        {
            title: 'Action',
            dataIndex: 'action',
            key: 'action',
            width: 130,
            render: (v: string) => (
                <Tag
                    icon={actionIcons[v]}
                    color={actionColors[v] || 'default'}
                    style={{ borderRadius: 6, fontWeight: 600 }}
                >
                    {v}
                </Tag>
            ),
        },
        {
            title: 'Entity',
            dataIndex: 'entityType',
            key: 'entity',
            width: 190,
            render: (v: string, r: any) => (
                <div>
                    <Tag style={{ borderRadius: 6 }}>{v?.replace(/_/g, ' ')}</Tag>
                    {r.entityId && (
                        <Tooltip title={r.entityId}>
                            <Text
                                type="secondary"
                                style={{ fontFamily: 'monospace', fontSize: 10, display: 'block', marginTop: 2 }}
                            >
                                #{r.entityId.substring(0, 8)}…
                            </Text>
                        </Tooltip>
                    )}
                </div>
            ),
        },
        {
            title: 'IP Address',
            dataIndex: 'ipAddress',
            key: 'ip',
            width: 135,
            render: (v: string) => (
                <Text type="secondary" style={{ fontFamily: 'monospace', fontSize: 12 }}>
                    {v || '—'}
                </Text>
            ),
        },
        {
            title: '',
            key: 'details',
            width: 80,
            render: (_: any, r: any) => (
                <Button
                    icon={<EyeOutlined />}
                    size="small"
                    type="primary"
                    ghost
                    style={{ borderColor: '#6366f1', color: '#6366f1', borderRadius: 6 }}
                    onClick={() => setDetailModal({ open: true, log: r })}
                >
                    View
                </Button>
            ),
        },
    ];

    return (
        <div>
            {/* ── Page header ────────────────────────────────────────────────── */}
            <div
                style={{
                    display: 'flex', justifyContent: 'space-between',
                    marginBottom: 20, alignItems: 'center', flexWrap: 'wrap', gap: 16,
                }}
            >
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div
                        style={{
                            width: 40, height: 40, borderRadius: 12,
                            background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}
                    >
                        <AuditOutlined style={{ color: '#fff', fontSize: 18 }} />
                    </div>
                    <div>
                        <Title level={3} style={{ margin: 0, color: '#0f172a' }}>Audit Logs</Title>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                            Track all admin actions
                        </Text>
                    </div>
                </div>

                <Space wrap>
                    <Input.Search
                        placeholder="Search admin email"
                        prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
                        allowClear
                        onSearch={setAdminEmail}
                        style={{ width: 220 }}
                    />
                    <DatePicker.RangePicker
                        allowClear
                        style={{ borderRadius: 8 }}
                        onChange={(dates) => {
                            if (dates && dates[0] && dates[1]) {
                                setDateRange([dates[0].toISOString(), dates[1].toISOString()]);
                            } else {
                                setDateRange(null);
                            }
                            setPage(1);
                        }}
                    />
                    <Select
                        placeholder={<><FilterOutlined /> Action</>}
                        allowClear
                        style={{ width: 145 }}
                        onChange={(v) => { setAction(v); setPage(1); }}
                    >
                        {['CREATE', 'UPDATE', 'DEACTIVATE', 'DELETE', 'LOGIN'].map((a) => (
                            <Select.Option key={a} value={a}>
                                <Tag icon={actionIcons[a]} color={actionColors[a]} style={{ margin: 0, borderRadius: 6 }}>
                                    {a}
                                </Tag>
                            </Select.Option>
                        ))}
                    </Select>
                    <Select
                        placeholder="Entity Type"
                        allowClear
                        style={{ width: 200 }}
                        onChange={(v) => { setEntityType(v); setPage(1); }}
                    >
                        {['SUBSCRIPTION_PLAN', 'TAX_CONFIG', 'SYSTEM_CONFIG', 'CAMPAIGN', 'PROMOTIONAL_ITEM'].map((e) => (
                            <Select.Option key={e} value={e}>
                                {e.replace(/_/g, ' ')}
                            </Select.Option>
                        ))}
                    </Select>
                </Space>
            </div>

            {/* ── Mini stat row ──────────────────────────────────────────────── */}
            {!action && logs.length > 0 && (
                <Row gutter={12} style={{ marginBottom: 20 }}>
                    {[
                        { label: 'Creates', val: createCount, color: '#22c55e', icon: <PlusCircleOutlined /> },
                        { label: 'Updates', val: updateCount, color: '#3b82f6', icon: <EditOutlined /> },
                        { label: 'Deletes', val: deleteCount, color: '#ef4444', icon: <DeleteOutlined /> },
                        { label: 'Logins', val: loginCount, color: '#8b5cf6', icon: <LoginOutlined /> },
                    ].map(({ label, val, color, icon }) => (
                        <Col xs={12} sm={6} key={label}>
                            <Card
                                size="small"
                                style={{ borderRadius: 12 }}
                                bodyStyle={{ padding: '10px 14px' }}
                            >
                                <Statistic
                                    title={<span style={{ fontSize: 11, color: '#94a3b8' }}>{label}</span>}
                                    value={val}
                                    prefix={<span style={{ color }}>{icon}</span>}
                                    valueStyle={{ color, fontSize: 20, fontWeight: 700 }}
                                />
                            </Card>
                        </Col>
                    ))}
                </Row>
            )}

            {/* ── Table ─────────────────────────────────────────────────────── */}
            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey="id"
                loading={isLoading}
                pagination={{
                    total: data?.total,
                    pageSize: 20,
                    current: page,
                    onChange: setPage,
                    showTotal: (t) => `${t} entries`,
                    showSizeChanger: false,
                }}
                style={{ background: '#fff', borderRadius: 14 }}
                rowClassName={(r: any) => r.action === 'DELETE' ? 'audit-row-delete' : ''}
            />

            {/* ── Detail modal ──────────────────────────────────────────────── */}
            <Modal
                title={
                    detailModal.log ? (
                        <Space align="center">
                            <div
                                style={{
                                    width: 36, height: 36, borderRadius: 10,
                                    background: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                }}
                            >
                                <AuditOutlined style={{ color: '#fff', fontSize: 16 }} />
                            </div>
                            <div>
                                <div style={{ fontWeight: 700, color: '#0f172a', lineHeight: 1.3 }}>
                                    Audit Log Detail
                                </div>
                                <div style={{ display: 'flex', gap: 6, marginTop: 4 }}>
                                    <Tag
                                        icon={actionIcons[detailModal.log.action]}
                                        color={actionColors[detailModal.log.action] || 'default'}
                                        style={{ borderRadius: 6, fontWeight: 600, margin: 0 }}
                                    >
                                        {detailModal.log.action}
                                    </Tag>
                                    <Tag style={{ borderRadius: 6, margin: 0 }}>
                                        {detailModal.log.entityType?.replace(/_/g, ' ')}
                                    </Tag>
                                </div>
                            </div>
                        </Space>
                    ) : null
                }
                open={detailModal.open}
                onCancel={() => setDetailModal({ open: false })}
                footer={[
                    <Button
                        key="close"
                        onClick={() => setDetailModal({ open: false })}
                        style={{ borderRadius: 8 }}
                    >
                        Close
                    </Button>,
                ]}
                width={900}
                styles={{ body: { paddingTop: 8 } }}
            >
                {detailModal.log && (
                    <>
                        {/* Meta row */}
                        <Card
                            size="small"
                            style={{ marginBottom: 16, borderRadius: 12 }}
                            bodyStyle={{ padding: '10px 14px' }}
                        >
                            <Row gutter={[16, 8]}>
                                <Col xs={24} sm={8}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>ADMIN</Text>
                                    <div style={{ marginTop: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
                                        <div
                                            style={{
                                                width: 22, height: 22, borderRadius: 6,
                                                background: '#6366f1',
                                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            }}
                                        >
                                            <UserOutlined style={{ color: '#fff', fontSize: 10 }} />
                                        </div>
                                        <Text style={{ fontFamily: 'monospace', fontSize: 13 }}>
                                            {detailModal.log.adminEmail || '—'}
                                        </Text>
                                    </div>
                                </Col>
                                <Col xs={24} sm={8}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>TIMESTAMP</Text>
                                    <div style={{ fontWeight: 500, fontSize: 13, marginTop: 2 }}>
                                        {new Date(detailModal.log.createdAt).toLocaleString()}
                                    </div>
                                </Col>
                                <Col xs={12} sm={4}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>IP ADDRESS</Text>
                                    <div
                                        style={{
                                            fontFamily: 'monospace', fontSize: 12,
                                            marginTop: 2, color: '#374151',
                                        }}
                                    >
                                        {detailModal.log.ipAddress || '—'}
                                    </div>
                                </Col>
                                <Col xs={12} sm={4}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>ENTITY ID</Text>
                                    {detailModal.log.entityId ? (
                                        <Tooltip title={detailModal.log.entityId}>
                                            <div
                                                style={{
                                                    fontFamily: 'monospace', fontSize: 12,
                                                    marginTop: 2, color: '#6366f1', cursor: 'help',
                                                }}
                                            >
                                                #{detailModal.log.entityId.substring(0, 8)}…
                                            </div>
                                        </Tooltip>
                                    ) : (
                                        <div style={{ color: '#94a3b8', fontSize: 12, marginTop: 2 }}>—</div>
                                    )}
                                </Col>
                            </Row>
                        </Card>

                        {/* Before / After diff */}
                        <div style={{ display: 'flex', gap: 16 }}>
                            <JsonDiff label="Before" data={detailModal.log.oldValues} color="#ef4444" />
                            <JsonDiff label="After" data={detailModal.log.newValues} color="#22c55e" />
                        </div>
                    </>
                )}
            </Modal>
        </div>
    );
}
