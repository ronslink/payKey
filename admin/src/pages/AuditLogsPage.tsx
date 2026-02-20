import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Modal, Space } from 'antd';
import { EyeOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminAuditLogs } from '../api/client';

const { Title, Text } = Typography;

export default function AuditLogsPage() {
    const [page, setPage] = useState(1);
    const [action, setAction] = useState<string>();
    const [entityType, setEntityType] = useState<string>();
    const [detailModal, setDetailModal] = useState<{ open: boolean; log?: any }>({ open: false });

    const { data, isLoading } = useQuery({
        queryKey: ['admin-audit-logs', page, action, entityType],
        queryFn: () => adminAuditLogs.list({ page, action, entityType }),
    });

    const actionColors: Record<string, string> = {
        CREATE: 'green',
        UPDATE: 'blue',
        DEACTIVATE: 'red',
        DELETE: 'red',
    };

    const columns = [
        { title: 'Date', dataIndex: 'createdAt', key: 'date', render: (v: string) => new Date(v).toLocaleString() },
        { title: 'Admin', dataIndex: 'adminEmail', key: 'admin' },
        { title: 'Action', dataIndex: 'action', key: 'action', render: (v: string) => <Tag color={actionColors[v] || 'default'}>{v}</Tag> },
        { title: 'Entity', dataIndex: 'entityType', key: 'entity', render: (v: string) => <Tag>{v}</Tag> },
        { title: 'IP Address', dataIndex: 'ipAddress', key: 'ip', render: (v: string) => <Text type="secondary">{v || '—'}</Text> },
        {
            title: '',
            key: 'details',
            render: (_: any, r: any) => (
                <Button icon={<EyeOutlined />} size="small" onClick={() => setDetailModal({ open: true, log: r })}>View</Button>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, alignItems: 'center' }}>
                <Title level={3} style={{ margin: 0 }}>Audit Logs</Title>
                <Space>
                    <Select placeholder="Filter Action" allowClear style={{ width: 150 }} onChange={setAction}>
                        {['CREATE', 'UPDATE', 'DEACTIVATE', 'DELETE'].map((a) => <Select.Option key={a} value={a}>{a}</Select.Option>)}
                    </Select>
                    <Select placeholder="Filter Entity" allowClear style={{ width: 180 }} onChange={setEntityType}>
                        {['SUBSCRIPTION_PLAN', 'TAX_CONFIG', 'SYSTEM_CONFIG'].map((e) => <Select.Option key={e} value={e}>{e}</Select.Option>)}
                    </Select>
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey="id"
                loading={isLoading}
                pagination={{ total: data?.total, pageSize: 20, current: page, onChange: setPage }}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            <Modal
                title={`Audit Log Detail`}
                open={detailModal.open}
                onCancel={() => setDetailModal({ open: false })}
                footer={[<Button key="close" onClick={() => setDetailModal({ open: false })}>Close</Button>]}
                width={800}
            >
                {detailModal.log && (
                    <div style={{ display: 'flex', gap: 16 }}>
                        <div style={{ flex: 1 }}>
                            <Title level={5}>Before Context</Title>
                            <pre style={{ background: '#f8fafc', padding: 12, borderRadius: 8, fontSize: 12, overflowX: 'auto' }}>
                                {JSON.stringify(detailModal.log.oldValues, null, 2)}
                            </pre>
                        </div>
                        <div style={{ flex: 1 }}>
                            <Title level={5}>After Context</Title>
                            <pre style={{ background: '#f8fafc', padding: 12, borderRadius: 8, fontSize: 12, overflowX: 'auto' }}>
                                {JSON.stringify(detailModal.log.newValues, null, 2)}
                            </pre>
                        </div>
                    </div>
                )}
            </Modal>
        </div>
    );
}
