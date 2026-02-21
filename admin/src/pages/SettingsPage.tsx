import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Table, Typography, Button, Modal, Form, Input, message, Space, Tooltip, Tag,
    Tabs, Card, Row, Col, Statistic, Badge, Popconfirm, Select, Alert,
    Descriptions, Empty, Spin,
} from 'antd';
import {
    EditOutlined, PlusOutlined, EyeOutlined, CopyOutlined,
    DeleteOutlined, ReloadOutlined, PlayCircleOutlined, PauseCircleOutlined,
    ClearOutlined, SettingOutlined, ThunderboltOutlined, ClockCircleOutlined,
    WarningOutlined,
} from '@ant-design/icons';
import { useState } from 'react';
import { adminSystemConfig, adminOperations } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

// ─── Shared helpers ───────────────────────────────────────────────────────────

const isSecretKey = (key: string) => /key|secret|token|password|pwd/i.test(key || '');

// ─── Tab 1: Configuration ─────────────────────────────────────────────────────

function ConfigTab() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';
    const qc = useQueryClient();
    const [editModal, setEditModal] = useState<{ open: boolean; record?: any; isNew?: boolean }>({ open: false });
    const [viewModal, setViewModal] = useState<{ open: boolean; record?: any }>({ open: false });
    const [form] = Form.useForm();

    const { data: configs, isLoading } = useQuery({
        queryKey: ['admin-system-config'],
        queryFn: adminSystemConfig.list,
    });

    const updateMut = useMutation({
        mutationFn: ({ key, data }: { key: string; data: any }) => adminSystemConfig.update(key, data),
        onSuccess: () => {
            message.success(editModal.isNew ? 'Setting created' : 'Setting updated');
            setEditModal({ open: false });
            qc.invalidateQueries({ queryKey: ['admin-system-config'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Save failed'),
    });

    const openEdit = (record?: any) => {
        form.resetFields();
        if (record) form.setFieldsValue(record);
        setEditModal({ open: true, record, isNew: !record });
    };

    const copyToClipboard = (val: string) => {
        navigator.clipboard.writeText(val).then(() => message.success('Copied to clipboard'));
    };

    const columns = [
        {
            title: 'Configuration Key',
            dataIndex: 'key',
            key: 'key',
            width: 240,
            render: (v: string) => <Text code>{v}</Text>,
        },
        {
            title: 'Value',
            dataIndex: 'value',
            key: 'value',
            render: (v: string, r: any) => {
                const isLong = v && v.length > 60;
                const isSecret = isSecretKey(r.key);
                return (
                    <Space>
                        <span style={{
                            maxWidth: 340, display: 'inline-block', overflow: 'hidden',
                            textOverflow: 'ellipsis', whiteSpace: 'nowrap', verticalAlign: 'middle',
                            fontFamily: isSecret ? 'monospace' : undefined,
                        }}>
                            {isSecret ? '••••••••••••' : (isLong ? v.substring(0, 60) + '…' : v)}
                        </span>
                        {isLong && <Tag color="blue" style={{ fontSize: 11 }}>long</Tag>}
                        {isSecret && <Tag color="orange" style={{ fontSize: 11 }}>secret</Tag>}
                    </Space>
                );
            },
        },
        {
            title: 'Description',
            dataIndex: 'description',
            key: 'desc',
            render: (v: string) => <Text type="secondary">{v || '—'}</Text>,
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 130,
            render: (_: any, r: any) => (
                <Space>
                    <Tooltip title="View full value">
                        <Button icon={<EyeOutlined />} size="small" onClick={() => setViewModal({ open: true, record: r })} />
                    </Tooltip>
                    <Tooltip title="Copy value">
                        <Button icon={<CopyOutlined />} size="small" onClick={() => copyToClipboard(r.value)} />
                    </Tooltip>
                    {canEdit && (
                        <Tooltip title="Edit">
                            <Button icon={<EditOutlined />} size="small" type="primary" ghost onClick={() => openEdit(r)} />
                        </Tooltip>
                    )}
                </Space>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <Text type="secondary">Global configuration keys used by platform services. Changes take effect immediately.</Text>
                {canEdit && (
                    <Button type="primary" icon={<PlusOutlined />} style={{ background: '#6366f1' }} onClick={() => openEdit()}>
                        Add Setting
                    </Button>
                )}
            </div>

            <Table
                columns={columns}
                dataSource={configs || []}
                rowKey="key"
                loading={isLoading}
                pagination={false}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            {/* Edit / Create Modal */}
            <Modal
                title={editModal.isNew ? 'Add New Setting' : `Edit: ${editModal.record?.key}`}
                open={editModal.open}
                onCancel={() => setEditModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={updateMut.isPending}
                okText={editModal.isNew ? 'Create' : 'Save'}
            >
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={(v) => updateMut.mutate({ key: editModal.isNew ? v.key : editModal.record?.key, data: { value: v.value, description: v.description } })}
                >
                    {editModal.isNew && (
                        <Form.Item
                            label="Configuration Key" name="key"
                            rules={[{ required: true }, { pattern: /^[A-Z0-9_]+$/, message: 'Use UPPER_SNAKE_CASE' }]}
                            extra="Use UPPER_SNAKE_CASE format"
                        >
                            <Input placeholder="e.g. FEATURE_FLAG_NAME" style={{ fontFamily: 'monospace' }} />
                        </Form.Item>
                    )}
                    <Form.Item label="Value" name="value" rules={[{ required: true }]}>
                        <Input.TextArea rows={4} placeholder="Setting value..." />
                    </Form.Item>
                    <Form.Item label="Description" name="description">
                        <Input placeholder="What this setting controls..." />
                    </Form.Item>
                </Form>
            </Modal>

            {/* View Full Value Modal */}
            <Modal
                title={`Full Value: ${viewModal.record?.key}`}
                open={viewModal.open}
                onCancel={() => setViewModal({ open: false })}
                footer={[
                    <Button key="copy" icon={<CopyOutlined />} onClick={() => copyToClipboard(viewModal.record?.value)}>Copy</Button>,
                    <Button key="close" onClick={() => setViewModal({ open: false })}>Close</Button>,
                ]}
            >
                <pre style={{ background: '#f8fafc', padding: 16, borderRadius: 8, border: '1px solid #e2e8f0', whiteSpace: 'pre-wrap', wordBreak: 'break-all', fontSize: 13, maxHeight: 400, overflowY: 'auto' }}>
                    {viewModal.record?.value}
                </pre>
                {viewModal.record?.description && (
                    <p style={{ color: '#64748b', marginTop: 12, marginBottom: 0 }}>{viewModal.record.description}</p>
                )}
            </Modal>
        </div>
    );
}

// ─── Tab 2: Account Cleanup ───────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
    PENDING: 'gold',
    PROCESSING: 'blue',
    COMPLETED: 'green',
    FAILED: 'red',
};

function AccountCleanupTab() {
    const { user } = useAuth();
    const isSuperAdmin = user?.role === 'SUPER_ADMIN';
    const qc = useQueryClient();
    const [statusFilter, setStatusFilter] = useState<string | undefined>();
    const [triggerModal, setTriggerModal] = useState(false);
    const [form] = Form.useForm();

    const { data, isLoading, refetch } = useQuery({
        queryKey: ['admin-deletions', statusFilter],
        queryFn: () => adminOperations.listDeletions({ status: statusFilter, limit: 50 }),
        refetchInterval: 10000, // Poll every 10s while tab is active
    });

    const triggerMut = useMutation({
        mutationFn: adminOperations.triggerDeletion,
        onSuccess: () => {
            message.success('Deletion request queued — will be processed within the hour');
            setTriggerModal(false);
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-deletions'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Failed to queue deletion'),
    });

    const retryMut = useMutation({
        mutationFn: adminOperations.retryDeletion,
        onSuccess: () => {
            message.success('Request reset to PENDING');
            qc.invalidateQueries({ queryKey: ['admin-deletions'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Retry failed'),
    });

    const summary = data?.summary || {};

    const columns = [
        {
            title: 'Email', dataIndex: 'email', key: 'email',
            render: (v: string) => <Text code style={{ fontSize: 12 }}>{v}</Text>,
        },
        {
            title: 'Reason', dataIndex: 'reason', key: 'reason', ellipsis: true,
            render: (v: string) => <Text type="secondary">{v || '—'}</Text>,
        },
        {
            title: 'Status', dataIndex: 'status', key: 'status', width: 120,
            render: (v: string) => <Tag color={STATUS_COLORS[v] || 'default'}>{v}</Tag>,
        },
        {
            title: 'Requested', dataIndex: 'requestedAt', key: 'requestedAt', width: 160,
            render: (v: string) => <Text style={{ fontSize: 12 }}>{new Date(v).toLocaleString()}</Text>,
        },
        {
            title: 'Processed', dataIndex: 'processedAt', key: 'processedAt', width: 160,
            render: (v: string) => v
                ? <Text style={{ fontSize: 12 }}>{new Date(v).toLocaleString()}</Text>
                : <Text type="secondary">—</Text>,
        },
        {
            title: 'Error', dataIndex: 'errorMessage', key: 'errorMessage', ellipsis: true,
            render: (v: string) => v
                ? <Tooltip title={v}><Text type="danger" style={{ fontSize: 12 }}>⚠ {v.substring(0, 50)}{v.length > 50 ? '…' : ''}</Text></Tooltip>
                : null,
        },
        {
            title: '', key: 'actions', width: 80,
            render: (_: any, r: any) => r.status === 'FAILED' && isSuperAdmin ? (
                <Popconfirm title="Reset this request to PENDING?" onConfirm={() => retryMut.mutate(r.id)} okText="Retry">
                    <Button size="small" icon={<ReloadOutlined />} loading={retryMut.isPending}>Retry</Button>
                </Popconfirm>
            ) : null,
        },
    ];

    return (
        <div>
            <Alert
                type="warning"
                showIcon
                icon={<WarningOutlined />}
                message="Permanent Deletion"
                description="Queued account deletions are irreversible and remove all user data including payroll records, workers, transactions, and subscriptions. The deletion scheduler runs hourly."
                style={{ marginBottom: 20 }}
            />

            {/* Summary cards */}
            <Row gutter={16} style={{ marginBottom: 20 }}>
                {(['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'] as const).map((s) => (
                    <Col key={s} xs={12} sm={6}>
                        <Card
                            size="small"
                            style={{
                                borderRadius: 10,
                                textAlign: 'center',
                                cursor: 'pointer',
                                border: statusFilter === s ? '2px solid #6366f1' : undefined,
                            }}
                            onClick={() => setStatusFilter(statusFilter === s ? undefined : s)}
                        >
                            <Statistic
                                title={s}
                                value={summary[s] ?? 0}
                                valueStyle={{
                                    color: s === 'FAILED' ? '#ef4444' : s === 'COMPLETED' ? '#22c55e' : s === 'PROCESSING' ? '#3b82f6' : '#f59e0b',
                                    fontSize: 24,
                                }}
                            />
                        </Card>
                    </Col>
                ))}
            </Row>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <Space>
                    <Select
                        placeholder="Filter by status"
                        allowClear
                        style={{ width: 160 }}
                        value={statusFilter}
                        onChange={setStatusFilter}
                        options={['PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'].map(s => ({ label: s, value: s }))}
                    />
                    <Button icon={<ReloadOutlined />} onClick={() => refetch()}>Refresh</Button>
                </Space>
                {isSuperAdmin && (
                    <Button type="primary" danger icon={<DeleteOutlined />} onClick={() => setTriggerModal(true)}>
                        Queue Account Deletion
                    </Button>
                )}
            </div>

            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey="id"
                loading={isLoading}
                pagination={{ pageSize: 20, total: data?.total, showSizeChanger: false }}
                style={{ background: '#fff', borderRadius: 12 }}
                locale={{ emptyText: <Empty description="No deletion requests" image={Empty.PRESENTED_IMAGE_SIMPLE} /> }}
            />

            {/* Trigger deletion modal */}
            <Modal
                title={<Space><DeleteOutlined style={{ color: '#ef4444' }} /> Queue Account Deletion</Space>}
                open={triggerModal}
                onCancel={() => { setTriggerModal(false); form.resetFields(); }}
                onOk={() => form.submit()}
                okText="Queue Deletion"
                okButtonProps={{ danger: true, loading: triggerMut.isPending }}
            >
                <Alert
                    type="error"
                    showIcon
                    message="This action is irreversible"
                    description="All data for this account will be permanently deleted during the next scheduler run."
                    style={{ marginBottom: 16 }}
                />
                <Form form={form} layout="vertical" onFinish={(v) => triggerMut.mutate(v)}>
                    <Form.Item label="User Email" name="email" rules={[{ required: true, type: 'email', message: 'Valid email required' }]}>
                        <Input placeholder="user@example.com" />
                    </Form.Item>
                    <Form.Item label="Reason" name="reason">
                        <Input.TextArea rows={3} placeholder="e.g. GDPR right-to-erasure request, account fraud..." />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}

// ─── Tab 3: Queue Monitor ─────────────────────────────────────────────────────

const QUEUE_COLORS: Record<string, string> = {
    wallets: '#6366f1',
    subscriptions: '#22c55e',
    'payroll-processing': '#f59e0b',
};

function QueueMonitorTab() {
    const { user } = useAuth();
    const isSuperAdmin = user?.role === 'SUPER_ADMIN';
    const qc = useQueryClient();

    const { data: queues = [], isLoading, refetch } = useQuery({
        queryKey: ['admin-queues'],
        queryFn: adminOperations.listQueues,
        refetchInterval: 5000,
    });

    const pauseMut = useMutation({
        mutationFn: adminOperations.pauseQueue,
        onSuccess: (_: any, name: string) => {
            message.success(`Queue "${name}" paused`);
            qc.invalidateQueries({ queryKey: ['admin-queues'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Action failed'),
    });

    const resumeMut = useMutation({
        mutationFn: adminOperations.resumeQueue,
        onSuccess: (_: any, name: string) => {
            message.success(`Queue "${name}" resumed`);
            qc.invalidateQueries({ queryKey: ['admin-queues'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Action failed'),
    });

    const drainMut = useMutation({
        mutationFn: adminOperations.drainQueue,
        onSuccess: (_: any, name: string) => {
            message.success(`Queue "${name}" drained`);
            qc.invalidateQueries({ queryKey: ['admin-queues'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Drain failed'),
    });

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                <Text type="secondary">Real-time BullMQ queue depths. Auto-refreshes every 5 seconds.</Text>
                <Button icon={<ReloadOutlined />} onClick={() => refetch()}>Refresh</Button>
            </div>

            {isLoading ? (
                <div style={{ textAlign: 'center', padding: 60 }}><Spin size="large" /></div>
            ) : (
                <Row gutter={[20, 20]}>
                    {(queues as any[]).map((q) => {
                        const color = QUEUE_COLORS[q.name] || '#6366f1';
                        const hasProblems = q.failed > 0 || q.paused;
                        return (
                            <Col key={q.name} xs={24} md={8}>
                                <Card
                                    style={{
                                        borderRadius: 14,
                                        border: `1.5px solid ${hasProblems ? '#fca5a5' : '#e2e8f0'}`,
                                        background: hasProblems ? '#fff5f5' : '#fff',
                                    }}
                                    title={
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Space>
                                                <span style={{ width: 10, height: 10, borderRadius: '50%', background: color, display: 'inline-block' }} />
                                                <Text strong style={{ textTransform: 'capitalize' }}>{q.name}</Text>
                                            </Space>
                                            {q.paused ? (
                                                <Badge status="warning" text={<Text style={{ fontSize: 12, color: '#d97706' }}>PAUSED</Text>} />
                                            ) : (
                                                <Badge status="processing" text={<Text style={{ fontSize: 12, color: '#16a34a' }}>RUNNING</Text>} />
                                            )}
                                        </div>
                                    }
                                >
                                    <Row gutter={12} style={{ marginBottom: 16 }}>
                                        {[
                                            { label: 'Waiting', value: q.waiting, valueColor: '#64748b' },
                                            { label: 'Active', value: q.active, valueColor: '#3b82f6' },
                                            { label: 'Delayed', value: q.delayed, valueColor: '#f59e0b' },
                                            { label: 'Failed', value: q.failed, valueColor: q.failed > 0 ? '#ef4444' : '#64748b' },
                                            { label: 'Done', value: q.completed, valueColor: '#22c55e' },
                                        ].map(({ label, value, valueColor }) => (
                                            <Col key={label} span={12} style={{ marginBottom: 8 }}>
                                                <div style={{ fontSize: 11, color: '#94a3b8', marginBottom: 2 }}>{label}</div>
                                                <div style={{ fontSize: 20, fontWeight: 700, color: valueColor }}>{value ?? '—'}</div>
                                            </Col>
                                        ))}
                                    </Row>

                                    {isSuperAdmin && (
                                        <Space wrap>
                                            {q.paused ? (
                                                <Popconfirm title={`Resume "${q.name}" queue?`} onConfirm={() => resumeMut.mutate(q.name)} okText="Resume">
                                                    <Button size="small" icon={<PlayCircleOutlined />} type="primary" ghost loading={resumeMut.isPending}>
                                                        Resume
                                                    </Button>
                                                </Popconfirm>
                                            ) : (
                                                <Popconfirm
                                                    title={`Pause "${q.name}" queue? New jobs will queue but won't be processed.`}
                                                    onConfirm={() => pauseMut.mutate(q.name)}
                                                    okText="Pause"
                                                    okButtonProps={{ danger: true }}
                                                >
                                                    <Button size="small" icon={<PauseCircleOutlined />} loading={pauseMut.isPending}>
                                                        Pause
                                                    </Button>
                                                </Popconfirm>
                                            )}
                                            <Popconfirm
                                                title={`Drain "${q.name}"? All WAITING jobs will be removed.`}
                                                onConfirm={() => drainMut.mutate(q.name)}
                                                okText="Drain"
                                                okButtonProps={{ danger: true }}
                                            >
                                                <Button size="small" danger icon={<ClearOutlined />} loading={drainMut.isPending}>
                                                    Drain
                                                </Button>
                                            </Popconfirm>
                                        </Space>
                                    )}
                                </Card>
                            </Col>
                        );
                    })}
                </Row>
            )}
        </div>
    );
}

// ─── Tab 4: Scheduled Jobs ────────────────────────────────────────────────────

function ScheduledJobsTab() {
    const { data: jobs = [], isLoading } = useQuery({
        queryKey: ['admin-cron-jobs'],
        queryFn: adminOperations.listCronJobs,
    });

    return (
        <div>
            <div style={{ marginBottom: 20 }}>
                <Text type="secondary">
                    Scheduled cron jobs that run automatically. Schedules cannot be modified at runtime without a redeploy.
                </Text>
            </div>

            {isLoading ? (
                <div style={{ textAlign: 'center', padding: 60 }}><Spin size="large" /></div>
            ) : (
                <Row gutter={[16, 16]}>
                    {(jobs as any[]).map((job, i) => (
                        <Col key={i} xs={24} lg={12}>
                            <Card style={{ borderRadius: 12, border: '1px solid #e2e8f0' }} size="small">
                                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                                    <div style={{
                                        width: 36, height: 36, borderRadius: 8, background: '#f0f4ff',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                                    }}>
                                        <ClockCircleOutlined style={{ color: '#6366f1', fontSize: 16 }} />
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Text strong style={{ fontSize: 14 }}>{job.name}</Text>
                                            <Badge status="success" text={<Text style={{ fontSize: 11, color: '#16a34a' }}>ACTIVE</Text>} />
                                        </div>
                                        <Text type="secondary" style={{ fontSize: 12, display: 'block', marginTop: 2, marginBottom: 8 }}>
                                            {job.description}
                                        </Text>
                                        <Descriptions size="small" column={2} style={{ marginTop: 4 }}>
                                            <Descriptions.Item label="Schedule">
                                                <Tag color="blue" style={{ fontFamily: 'monospace', fontSize: 11 }}>{job.schedule}</Tag>
                                            </Descriptions.Item>
                                            <Descriptions.Item label="Cron">
                                                <Text code style={{ fontSize: 11 }}>{job.cronExpr}</Text>
                                            </Descriptions.Item>
                                            <Descriptions.Item label="Service" span={2}>
                                                <Text code style={{ fontSize: 11, color: '#6366f1' }}>{job.service}</Text>
                                            </Descriptions.Item>
                                        </Descriptions>
                                    </div>
                                </div>
                            </Card>
                        </Col>
                    ))}
                </Row>
            )}

            <Alert
                type="info"
                showIcon
                style={{ marginTop: 24, borderRadius: 10 }}
                message="Cron Configuration"
                description="To modify cron schedules, update the @Cron() decorators in the corresponding scheduler service and redeploy the backend. Live schedule changes require a service restart."
            />
        </div>
    );
}

// ─── Root Page ────────────────────────────────────────────────────────────────

export default function SettingsPage() {
    const { user } = useAuth();
    const isSuperAdmin = user?.role === 'SUPER_ADMIN';

    const tabItems = [
        {
            key: 'config',
            label: <Space><SettingOutlined /> Configuration</Space>,
            children: <ConfigTab />,
        },
        {
            key: 'cleanup',
            label: <Space><DeleteOutlined /> Account Cleanup</Space>,
            children: <AccountCleanupTab />,
        },
        {
            key: 'queues',
            label: <Space><ThunderboltOutlined /> Queue Monitor</Space>,
            children: <QueueMonitorTab />,
        },
        {
            key: 'cron',
            label: <Space><ClockCircleOutlined /> Scheduled Jobs</Space>,
            children: <ScheduledJobsTab />,
        },
    ];

    return (
        <div>
            <div style={{ marginBottom: 24 }}>
                <Title level={3} style={{ margin: 0 }}>System Settings</Title>
                <Text type="secondary">
                    Platform configuration, account management, background job monitoring, and queue controls.
                    {!isSuperAdmin && ' Some destructive actions require Super Admin access.'}
                </Text>
            </div>

            <Tabs
                defaultActiveKey="config"
                items={tabItems}
                type="card"
                style={{ background: '#fff', borderRadius: 12, padding: 20 }}
            />
        </div>
    );
}
