import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Modal, Space, Input, DatePicker } from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminAuditLogs } from '../api/client';

const { Title, Text } = Typography;

const actionColors: Record<string, string> = {
    CREATE: 'green', UPDATE: 'blue', DEACTIVATE: 'orange', DELETE: 'red', LOGIN: 'purple',
};

function JsonDiff({ label, data, color }: { label: string; data: any; color: string }) {
    if (!data) return (
        <div style={{ flex: 1, minWidth: 0 }}>
            <Title level={5} style={{ color }}>{label}</Title>
            <pre style={{ background: '#f8fafc', padding: 16, borderRadius: 8, fontSize: 13, border: '1px solid #e2e8f0', color: '#94a3b8', minHeight: 80 }}>
                (none)
            </pre>
        </div>
    );

    // Attempt to colour JSON syntax
    const highlighted = JSON.stringify(data, null, 2)
        .replace(/("[\w]+")\s*:/g, '<span style="color:#6366f1;font-weight:600">$1</span>:')
        .replace(/:\s*(".*?")/g, ': <span style="color:#16a34a">$1</span>')
        .replace(/:\s*(true|false)/g, ': <span style="color:#ea580c">$1</span>')
        .replace(/:\s*(\d+\.?\d*)/g, ': <span style="color:#0369a1">$1</span>')
        .replace(/:\s*(null)/g, ': <span style="color:#94a3b8">$1</span>');

    return (
        <div style={{ flex: 1, minWidth: 0 }}>
            <Title level={5} style={{ color }}>{label}</Title>
            <pre
                style={{ background: '#f8fafc', padding: 16, borderRadius: 8, fontSize: 12, border: `1px solid ${color}33`, overflowX: 'auto', whiteSpace: 'pre-wrap', wordBreak: 'break-word', maxHeight: 400, overflowY: 'auto' }}
                dangerouslySetInnerHTML={{ __html: highlighted }}
            />
        </div>
    );
}

export default function AuditLogsPage() {
    const [page, setPage] = useState(1);
    const [action, setAction] = useState<string>();
    const [entityType, setEntityType] = useState<string>();
    const [adminEmail, setAdminEmail] = useState<string>();
    const [dateRange, setDateRange] = useState<[string, string] | null>(null);
    const [detailModal, setDetailModal] = useState<{ open: boolean; log?: any }>({ open: false });

    const { data, isLoading } = useQuery({
        queryKey: ['admin-audit-logs', page, action, entityType, adminEmail, dateRange],
        queryFn: () => adminAuditLogs.list({ page, action, entityType, adminEmail, startDate: dateRange?.[0], endDate: dateRange?.[1] }),
    });

    const columns = [
        {
            title: 'Date',
            dataIndex: 'createdAt',
            key: 'date',
            width: 170,
            render: (v: string) => new Date(v).toLocaleString(),
        },
        {
            title: 'Admin',
            dataIndex: 'adminEmail',
            key: 'admin',
            render: (v: string) => <Text style={{ fontFamily: 'monospace', fontSize: 13 }}>{v}</Text>,
        },
        {
            title: 'Action',
            dataIndex: 'action',
            key: 'action',
            width: 120,
            render: (v: string) => <Tag color={actionColors[v] || 'default'}>{v}</Tag>,
        },
        {
            title: 'Entity',
            dataIndex: 'entityType',
            key: 'entity',
            width: 180,
            render: (v: string) => <Tag>{v?.replace(/_/g, ' ')}</Tag>,
        },
        {
            title: 'IP Address',
            dataIndex: 'ipAddress',
            key: 'ip',
            width: 130,
            render: (v: string) => <Text type="secondary" style={{ fontFamily: 'monospace', fontSize: 12 }}>{v || '—'}</Text>,
        },
        {
            title: '',
            key: 'details',
            width: 80,
            render: (_: any, r: any) => (
                <Button icon={<EyeOutlined />} size="small" onClick={() => setDetailModal({ open: true, log: r })}>
                    View
                </Button>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, alignItems: 'center', flexWrap: 'wrap', gap: 16 }}>
                <Title level={3} style={{ margin: 0 }}>Audit Logs</Title>
                <Space wrap>
                    <Input.Search
                        placeholder="Search admin email"
                        allowClear
                        onSearch={setAdminEmail}
                        style={{ width: 220 }}
                    />
                    <DatePicker.RangePicker
                        allowClear
                        onChange={(dates) => {
                            if (dates && dates[0] && dates[1]) {
                                setDateRange([dates[0].toISOString(), dates[1].toISOString()]);
                            } else {
                                setDateRange(null);
                            }
                            setPage(1);
                        }}
                    />
                    <Select placeholder="Action" allowClear style={{ width: 140 }} onChange={(v) => { setAction(v); setPage(1); }}>
                        {['CREATE', 'UPDATE', 'DEACTIVATE', 'DELETE'].map(a =>
                            <Select.Option key={a} value={a}>
                                <Tag color={actionColors[a]} style={{ margin: 0 }}>{a}</Tag>
                            </Select.Option>
                        )}
                    </Select>
                    <Select placeholder="Entity Type" allowClear style={{ width: 200 }} onChange={(v) => { setEntityType(v); setPage(1); }}>
                        {['SUBSCRIPTION_PLAN', 'TAX_CONFIG', 'SYSTEM_CONFIG', 'CAMPAIGN', 'PROMOTIONAL_ITEM'].map(e =>
                            <Select.Option key={e} value={e}>{e.replace(/_/g, ' ')}</Select.Option>
                        )}
                    </Select>
                </Space>
            </div>

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
                }}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            <Modal
                title={
                    detailModal.log && (
                        <Space>
                            <span>Audit Log Detail</span>
                            <Tag color={actionColors[detailModal.log.action] || 'default'}>{detailModal.log.action}</Tag>
                            <Tag>{detailModal.log.entityType?.replace(/_/g, ' ')}</Tag>
                        </Space>
                    )
                }
                open={detailModal.open}
                onCancel={() => setDetailModal({ open: false })}
                footer={[<Button key="close" onClick={() => setDetailModal({ open: false })}>Close</Button>]}
                width={860}
            >
                {detailModal.log && (
                    <>
                        <div style={{ marginBottom: 12, padding: '8px 12px', background: '#f8fafc', borderRadius: 8, fontSize: 13, color: '#64748b' }}>
                            <strong>Admin:</strong> {detailModal.log.adminEmail} &nbsp;·&nbsp;
                            <strong>Time:</strong> {new Date(detailModal.log.createdAt).toLocaleString()} &nbsp;·&nbsp;
                            <strong>IP:</strong> {detailModal.log.ipAddress || '—'}
                        </div>
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
