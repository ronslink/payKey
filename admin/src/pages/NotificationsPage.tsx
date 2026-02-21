import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Table, Typography, Button, Modal, Form, Input, Select,
    Tag, message, Spin, Alert, Space, Segmented, Badge, DatePicker,
} from 'antd';
import {
    SendOutlined, TeamOutlined, UserOutlined,
    CrownOutlined, MailOutlined, MessageOutlined, BellOutlined,
    ToolOutlined, WarningOutlined,
} from '@ant-design/icons';
import { useState } from 'react';
import dayjs from 'dayjs';
import { adminNotifications, adminUsers } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

// Subscription tier config — same order/colours used across admin UI
const TIERS = [
    { value: 'FREE',     label: 'Free',     color: '#6b7280', bg: '#f3f4f6' },
    { value: 'BASIC',    label: 'Basic',    color: '#2563eb', bg: '#eff6ff' },
    { value: 'GOLD',     label: 'Gold',     color: '#d97706', bg: '#fffbeb' },
    { value: 'PLATINUM', label: 'Platinum', color: '#7c3aed', bg: '#f5f3ff' },
];

type SendMode = 'broadcast' | 'tiers' | 'individual' | 'maintenance';

// Default maintenance subject/message templates
const MAINTENANCE_DEFAULTS = {
    subject: '🔧 Scheduled Maintenance Notice',
    message:
        'We will be performing scheduled maintenance on the PayDome platform. ' +
        'During this window the service may be temporarily unavailable. ' +
        'We apologise for any inconvenience and thank you for your patience.',
};

export default function NotificationsPage() {
    const { user } = useAuth();
    const canSend = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [sendModal, setSendModal]             = useState(false);
    const [sendMode, setSendMode]               = useState<SendMode>('broadcast');
    const [notifType, setNotifType]             = useState('EMAIL');
    const [selectedTiers, setSelectedTiers]     = useState<string[]>([]);
    const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);
    const [maintWindow, setMaintWindow]         = useState<[dayjs.Dayjs | null, dayjs.Dayjs | null]>([null, null]);
    const [form] = Form.useForm();
    const [page, setPage]                       = useState(1);
    const [typeFilter, setTypeFilter]           = useState<string>();

    // ── Data fetching ──────────────────────────────────────────────────────────
    const { data, isLoading } = useQuery({
        queryKey: ['admin-notifications', page, typeFilter],
        queryFn: () => adminNotifications.list({ page, type: typeFilter }),
    });

    const { data: usersData, isLoading: usersLoading } = useQuery({
        queryKey: ['admin-users-all'],
        queryFn: () => adminUsers.list({ limit: 1000 }),
        staleTime: 60000,
    });

    const sendMut = useMutation({
        mutationFn: (vals: any) => adminNotifications.send(vals),
        onSuccess: (res) => {
            message.success(res.message || 'Notifications sent');
            setSendModal(false);
            form.resetFields();
            setSelectedTiers([]);
            setSelectedUserIds([]);
            setMaintWindow([null, null]);
            setSendMode('broadcast');
            qc.invalidateQueries({ queryKey: ['admin-notifications'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Send failed'),
    });

    // ── Recipient count preview ────────────────────────────────────────────────
    const allUsers: any[]  = usersData?.data || [];
    const totalUsers       = allUsers.length;
    // Active subscription users: users with tier !== FREE (proxy; exact count comes from backend)
    const activeSubUsers   = allUsers.filter((u: any) => u.tier && u.tier !== 'FREE').length;

    const tierUserCounts = TIERS.reduce<Record<string, number>>((acc, t) => {
        acc[t.value] = allUsers.filter((u: any) => u.tier === t.value).length;
        return acc;
    }, {});

    const recipientCount =
        sendMode === 'broadcast'    ? totalUsers
        : sendMode === 'maintenance' ? activeSubUsers
        : sendMode === 'tiers'      ? selectedTiers.reduce((s, t) => s + (tierUserCounts[t] ?? 0), 0)
        : selectedUserIds.length;

    // ── Modal open ────────────────────────────────────────────────────────────
    const openModal = () => {
        form.resetFields();
        form.setFieldsValue({ type: 'EMAIL' });
        setSendMode('broadcast');
        setNotifType('EMAIL');
        setSelectedTiers([]);
        setSelectedUserIds([]);
        setMaintWindow([null, null]);
        setSendModal(true);
    };

    // Switch to maintenance mode pre-fills sensible defaults
    const handleModeChange = (v: SendMode) => {
        setSendMode(v);
        setSelectedTiers([]);
        setSelectedUserIds([]);
        setMaintWindow([null, null]);
        if (v === 'maintenance') {
            form.setFieldsValue({
                subject: MAINTENANCE_DEFAULTS.subject,
                message: MAINTENANCE_DEFAULTS.message,
            });
        }
    };

    // ── Form submit → normalise to API shape ──────────────────────────────────
    const handleFinish = (vals: any) => {
        const payload: any = {
            type: vals.type,
            subject: vals.subject,
            message: vals.message,
        };
        if (sendMode === 'broadcast') {
            payload.broadcast = true;
        } else if (sendMode === 'maintenance') {
            payload.maintenance = true;
            if (maintWindow[0] || maintWindow[1]) {
                payload.maintenanceWindow = {
                    startsAt: maintWindow[0]?.toISOString() ?? undefined,
                    endsAt:   maintWindow[1]?.toISOString() ?? undefined,
                };
            }
        } else if (sendMode === 'tiers') {
            payload.tiers = selectedTiers;
        } else {
            payload.userIds = selectedUserIds;
        }
        sendMut.mutate(payload);
    };

    // ── Alert text / colour by mode ───────────────────────────────────────────
    const alertProps = (() => {
        if (sendMode === 'broadcast') return {
            type: 'warning' as const,
            icon: <TeamOutlined />,
            message: `Broadcast to ALL ${totalUsers} employer accounts`,
        };
        if (sendMode === 'maintenance') return {
            type: 'warning' as const,
            icon: <WarningOutlined />,
            message: `Maintenance notice to ~${activeSubUsers} users with active subscriptions`,
            description: 'Targets every account with a currently active (paid) subscription.',
        };
        if (sendMode === 'tiers') {
            if (selectedTiers.length === 0) return {
                type: 'info' as const, icon: <CrownOutlined />,
                message: 'Select one or more tiers below',
            };
            const labels = selectedTiers.map(t => TIERS.find(x => x.value === t)?.label).join(', ');
            return {
                type: 'info' as const, icon: <CrownOutlined />,
                message: `Sending to ${recipientCount} employer${recipientCount === 1 ? '' : 's'} on: ${labels}`,
            };
        }
        return {
            type: 'info' as const, icon: <UserOutlined />,
            message: selectedUserIds.length > 0
                ? `Sending to ${selectedUserIds.length} selected employer${selectedUserIds.length === 1 ? '' : 's'}`
                : 'No recipients selected yet',
        };
    })();

    // ── Table helpers ─────────────────────────────────────────────────────────
    const typeColor = (v: string) =>
        v === 'EMAIL' ? 'blue' : v === 'SMS' ? 'orange' : 'purple';

    const typeIcon = (v: string) =>
        v === 'EMAIL' ? <MailOutlined /> : v === 'SMS' ? <MessageOutlined /> : <BellOutlined />;

    // Maintenance badge shown in the table for records flagged in metadata
    const isMaintenance = (r: any) => r.metadata?.notificationType === 'MAINTENANCE';

    const columns = [
        {
            title: 'Type',
            dataIndex: 'type',
            key: 'type',
            width: 100,
            render: (v: string, r: any) => (
                <Space size={4} direction="vertical" style={{ gap: 2 }}>
                    <Tag color={typeColor(v)} icon={typeIcon(v)}>{v}</Tag>
                    {isMaintenance(r) && (
                        <Tag icon={<ToolOutlined />} color="orange" style={{ fontSize: 10 }}>MAINT</Tag>
                    )}
                </Space>
            ),
        },
        {
            title: 'Recipient',
            key: 'recipient',
            render: (_: any, r: any) => (
                <span style={{ fontFamily: 'monospace', fontSize: 13, color: '#374151' }}>
                    {r.recipient || r.user?.email || '—'}
                </span>
            ),
        },
        {
            title: 'Subject',
            dataIndex: 'subject',
            key: 'subject',
            render: (v: string) => v || <Text type="secondary">—</Text>,
        },
        {
            title: 'Message',
            dataIndex: 'message',
            key: 'msg',
            render: (v: string) => (
                <div style={{ maxWidth: 300, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: '#64748b', fontSize: 13 }}>
                    {v}
                </div>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            width: 90,
            render: (v: string) => (
                <Tag color={v === 'SENT' ? 'green' : v === 'FAILED' ? 'red' : 'default'}>{v}</Tag>
            ),
        },
        {
            title: 'Sent At',
            dataIndex: 'sentAt',
            key: 'sentAt',
            width: 160,
            render: (v: string) => v ? new Date(v).toLocaleString() : '—',
        },
    ];

    // ── Render ────────────────────────────────────────────────────────────────
    return (
        <div>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, alignItems: 'center' }}>
                <Title level={3} style={{ margin: 0 }}>Notifications History</Title>
                {canSend && (
                    <Button
                        type="primary"
                        icon={<SendOutlined />}
                        style={{ background: '#6366f1' }}
                        onClick={openModal}
                    >
                        Compose
                    </Button>
                )}
            </div>

            {/* Type filter */}
            <div style={{ marginBottom: 16 }}>
                <Select
                    placeholder="Filter by Type"
                    allowClear
                    style={{ width: 160 }}
                    onChange={(v) => { setTypeFilter(v); setPage(1); }}
                >
                    {['EMAIL', 'SMS', 'PUSH'].map(t => (
                        <Select.Option key={t} value={t}>
                            <Tag color={typeColor(t)} icon={typeIcon(t)} style={{ margin: 0 }}>{t}</Tag>
                        </Select.Option>
                    ))}
                </Select>
            </div>

            {/* History table */}
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
                    showTotal: (t) => `${t} notifications`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            {/* Compose modal */}
            <Modal
                title="Compose Notification"
                open={sendModal}
                onCancel={() => setSendModal(false)}
                onOk={() => form.submit()}
                confirmLoading={sendMut.isPending}
                width={660}
                okText={
                    <span>
                        <SendOutlined /> Send to {recipientCount} {recipientCount === 1 ? 'user' : 'users'}
                    </span>
                }
                okButtonProps={{
                    style: { background: sendMode === 'maintenance' ? '#f97316' : '#6366f1' },
                    disabled: (sendMode === 'tiers'       && selectedTiers.length === 0)
                           || (sendMode === 'individual'  && selectedUserIds.length === 0),
                }}
            >
                {/* Recipient preview */}
                {sendModal && (
                    <Alert
                        style={{ marginBottom: 16 }}
                        showIcon
                        {...alertProps}
                    />
                )}

                <Form
                    form={form}
                    layout="vertical"
                    initialValues={{ type: 'EMAIL' }}
                    onValuesChange={(changed) => {
                        if (changed.type !== undefined) setNotifType(changed.type);
                    }}
                    onFinish={handleFinish}
                >
                    {/* Message type */}
                    <Form.Item label="Message Type" name="type" rules={[{ required: true }]}>
                        <Select>
                            <Select.Option value="EMAIL"><MailOutlined /> Email</Select.Option>
                            <Select.Option value="SMS"><MessageOutlined /> SMS</Select.Option>
                            <Select.Option value="PUSH"><BellOutlined /> Push Notification</Select.Option>
                        </Select>
                    </Form.Item>

                    {/* Audience mode selector */}
                    <Form.Item label="Audience">
                        <Segmented
                            block
                            value={sendMode}
                            onChange={(v) => handleModeChange(v as SendMode)}
                            options={[
                                {
                                    label: (
                                        <Space size={4}>
                                            <TeamOutlined />
                                            <span>All</span>
                                            <Badge count={totalUsers} overflowCount={9999}
                                                style={{ backgroundColor: '#6366f1', fontSize: 10 }} />
                                        </Space>
                                    ),
                                    value: 'broadcast',
                                },
                                {
                                    label: (
                                        <Space size={4}>
                                            <ToolOutlined />
                                            <span>Maintenance</span>
                                            <Badge count={activeSubUsers} overflowCount={9999}
                                                style={{ backgroundColor: '#f97316', fontSize: 10 }} />
                                        </Space>
                                    ),
                                    value: 'maintenance',
                                },
                                {
                                    label: (
                                        <Space size={4}>
                                            <CrownOutlined />
                                            <span>By Tier</span>
                                        </Space>
                                    ),
                                    value: 'tiers',
                                },
                                {
                                    label: (
                                        <Space size={4}>
                                            <UserOutlined />
                                            <span>Individuals</span>
                                        </Space>
                                    ),
                                    value: 'individual',
                                },
                            ]}
                        />
                    </Form.Item>

                    {/* Maintenance window date-range picker */}
                    {sendMode === 'maintenance' && (
                        <Form.Item
                            label="Maintenance Window (optional)"
                            style={{ marginTop: -8 }}
                            extra="Timestamps are embedded in the notification record for reference. Leave blank if not yet scheduled."
                        >
                            <RangePicker
                                showTime
                                style={{ width: '100%' }}
                                placeholder={['Start date & time', 'End date & time']}
                                value={maintWindow}
                                onChange={(vals) =>
                                    setMaintWindow(vals ? [vals[0], vals[1]] : [null, null])
                                }
                                format="D MMM YYYY HH:mm"
                            />
                        </Form.Item>
                    )}

                    {/* Tier picker */}
                    {sendMode === 'tiers' && (
                        <Form.Item
                            label="Select Subscription Tiers"
                            required
                            style={{ marginTop: -8 }}
                        >
                            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                                {TIERS.map(t => {
                                    const selected = selectedTiers.includes(t.value);
                                    const count    = tierUserCounts[t.value] ?? 0;
                                    return (
                                        <div
                                            key={t.value}
                                            onClick={() =>
                                                setSelectedTiers(prev =>
                                                    selected ? prev.filter(x => x !== t.value) : [...prev, t.value]
                                                )
                                            }
                                            style={{
                                                cursor: 'pointer',
                                                border: `2px solid ${selected ? t.color : '#e5e7eb'}`,
                                                borderRadius: 8,
                                                padding: '10px 16px',
                                                background: selected ? t.bg : '#fff',
                                                display: 'flex',
                                                flexDirection: 'column',
                                                alignItems: 'center',
                                                minWidth: 100,
                                                transition: 'all 0.15s',
                                                userSelect: 'none',
                                            }}
                                        >
                                            <span style={{ fontWeight: 700, color: t.color, fontSize: 14 }}>
                                                {t.label}
                                            </span>
                                            <span style={{ fontSize: 12, color: '#6b7280', marginTop: 2 }}>
                                                {count} employer{count !== 1 ? 's' : ''}
                                            </span>
                                        </div>
                                    );
                                })}
                            </div>
                            {selectedTiers.length === 0 && (
                                <div style={{ color: '#ef4444', fontSize: 12, marginTop: 6 }}>
                                    Select at least one tier
                                </div>
                            )}
                        </Form.Item>
                    )}

                    {/* Individual user picker */}
                    {sendMode === 'individual' && (
                        <Form.Item
                            label="Select Recipients"
                            required
                            style={{ marginTop: -8 }}
                        >
                            {usersLoading ? <Spin size="small" /> : (
                                <Select
                                    mode="multiple"
                                    placeholder="Search by name or email…"
                                    filterOption={(input, option: any) =>
                                        option?.label?.toLowerCase().includes(input.toLowerCase())
                                    }
                                    value={selectedUserIds}
                                    onChange={setSelectedUserIds}
                                    options={(usersData?.data || []).map((u: any) => ({
                                        value: u.id,
                                        label: `${u.firstName || ''} ${u.lastName || ''} (${u.email}) — ${u.tier ?? 'FREE'}`.trim(),
                                    }))}
                                    showSearch
                                    maxTagCount={4}
                                    optionRender={(option: any) => {
                                        const parts = option.label?.split('—');
                                        const tier  = parts?.[parts.length - 1]?.trim() ?? 'FREE';
                                        const tc    = TIERS.find(t => t.value === tier);
                                        return (
                                            <Space>
                                                <span>{parts?.[0]?.trim()}</span>
                                                <Tag color={tc?.color ?? 'default'} style={{ margin: 0, fontSize: 11 }}>
                                                    {tier}
                                                </Tag>
                                            </Space>
                                        );
                                    }}
                                />
                            )}
                        </Form.Item>
                    )}

                    {/* Subject (EMAIL / PUSH) */}
                    {(notifType === 'EMAIL' || notifType === 'PUSH') && (
                        <Form.Item
                            label="Subject / Title"
                            name="subject"
                            rules={[{ required: true, message: 'Subject is required' }]}
                        >
                            <Input placeholder="e.g. Important update about your account" />
                        </Form.Item>
                    )}

                    {/* Message body */}
                    <Form.Item
                        label="Message Body"
                        name="message"
                        rules={[{ required: true, message: 'Message body is required' }]}
                    >
                        <Input.TextArea rows={4} placeholder="Write your message here…" showCount maxLength={1000} />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
