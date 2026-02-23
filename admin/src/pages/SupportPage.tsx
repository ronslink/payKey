import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Table, Select, Input, Typography, Tag, Button, Drawer, message,
    List, Avatar, Space, Spin, Popconfirm, Tooltip, Badge, Card, Statistic, Row, Col,
} from 'antd';
import {
    SearchOutlined, UserOutlined, RobotOutlined, SendOutlined,
    CheckCircleOutlined, ClockCircleOutlined, SyncOutlined,
    ExclamationCircleOutlined, InboxOutlined, MessageOutlined,
} from '@ant-design/icons';
import { adminSupport } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

const priorityColors: Record<string, string> = {
    LOW: 'default', MEDIUM: 'orange', HIGH: 'red', URGENT: 'volcano',
};
const statusColors: Record<string, string> = {
    OPEN: 'red', IN_PROGRESS: 'blue', RESOLVED: 'green', CLOSED: 'default',
};
const statusIcons: Record<string, React.ReactNode> = {
    OPEN: <ExclamationCircleOutlined />,
    IN_PROGRESS: <SyncOutlined spin />,
    RESOLVED: <CheckCircleOutlined />,
    CLOSED: <InboxOutlined />,
};
const categoryColors: Record<string, string> = {
    BILLING: 'gold', PAYROLL: 'blue', TECHNICAL: 'purple', TAX: 'orange', GENERAL: 'default',
};

// ── Ticket row type ────────────────────────────────────────────────────────────
interface TicketRow {
    id: string;
    subject: string;
    status: string;
    priority: string;
    category: string;
    createdAt: string;
    user?: { firstName?: string; lastName?: string; email?: string };
    messages?: any[];
}

export default function SupportPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [search, setSearch] = useState('');
    const [status, setStatus] = useState<string>();
    const [priority, setPriority] = useState<string>();
    const [category, setCategory] = useState<string>();
    const [page, setPage] = useState(1);
    const [drawer, setDrawer] = useState<{ open: boolean; ticketId?: string }>({ open: false });
    const [replyText, setReplyText] = useState('');

    const { data, isLoading } = useQuery({
        queryKey: ['admin-support', search, status, priority, category, page],
        queryFn: () => adminSupport.list({ search: search || undefined, status, priority, category, page }),
    });

    const { data: ticket, isLoading: ticketLoading } = useQuery({
        queryKey: ['admin-ticket', drawer.ticketId],
        queryFn: () => adminSupport.detail(drawer.ticketId!),
        enabled: !!drawer.ticketId && drawer.open,
        refetchInterval: drawer.open ? 15000 : false,
    });

    const updateMut = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => adminSupport.update(id, data),
        onSuccess: () => {
            message.success('Ticket updated');
            qc.invalidateQueries({ queryKey: ['admin-support'] });
            qc.invalidateQueries({ queryKey: ['admin-ticket', drawer.ticketId] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    const replyMut = useMutation({
        mutationFn: (msg: string) => adminSupport.reply(drawer.ticketId!, msg),
        onSuccess: () => {
            setReplyText('');
            qc.invalidateQueries({ queryKey: ['admin-ticket', drawer.ticketId] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Reply failed'),
    });

    // ── Summary counts ─────────────────────────────────────────────────────────
    const tickets: TicketRow[] = data?.data || [];
    const totalCount  = data?.total || 0;
    const openCount   = tickets.filter((t) => t.status === 'OPEN').length;
    const urgentCount = tickets.filter((t) => t.priority === 'URGENT' && t.status === 'OPEN').length;
    const inProgCount = tickets.filter((t) => t.status === 'IN_PROGRESS').length;

    // ── Table columns ──────────────────────────────────────────────────────────
    const columns = [
        {
            title: 'Subject',
            dataIndex: 'subject',
            key: 'subject',
            render: (v: string, r: TicketRow) => (
                <div>
                    <button
                        style={{
                            background: 'none', border: 'none', padding: 0, cursor: 'pointer',
                            color: '#6366f1', fontWeight: 600, fontSize: 14, textAlign: 'left',
                        }}
                        onClick={() => setDrawer({ open: true, ticketId: r.id })}
                    >
                        {v}
                    </button>
                    {r.priority === 'URGENT' && (
                        <Badge dot style={{ marginLeft: 6 }} color="red" />
                    )}
                    {(r.messages?.length ?? 0) > 0 && (
                        <Text type="secondary" style={{ fontSize: 11, marginLeft: 8 }}>
                            <MessageOutlined style={{ marginRight: 3 }} />
                            {r.messages?.length}
                        </Text>
                    )}
                </div>
            ),
        },
        {
            title: 'User',
            key: 'user',
            render: (_: any, r: TicketRow) => {
                const name = r.user
                    ? `${r.user.firstName || ''} ${r.user.lastName || ''}`.trim()
                    : '';
                const email = r.user?.email || '—';
                return (
                    <div style={{ lineHeight: 1.4 }}>
                        <div style={{ fontWeight: 500, color: '#0f172a' }}>{name || email}</div>
                        {name && <div style={{ fontSize: 11, color: '#94a3b8' }}>{email}</div>}
                    </div>
                );
            },
        },
        {
            title: 'Category',
            dataIndex: 'category',
            key: 'cat',
            width: 110,
            render: (v: string) => (
                <Tag color={categoryColors[v] || 'default'} style={{ borderRadius: 6 }}>{v}</Tag>
            ),
        },
        {
            title: 'Priority',
            dataIndex: 'priority',
            key: 'priority',
            width: 95,
            render: (v: string) => (
                <Tag color={priorityColors[v]} style={{ borderRadius: 6, fontWeight: 600 }}>{v}</Tag>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            width: 130,
            render: (v: string) => (
                <Tag
                    icon={statusIcons[v]}
                    color={statusColors[v]}
                    style={{ borderRadius: 6, fontWeight: 600 }}
                >
                    {v?.replace('_', ' ')}
                </Tag>
            ),
        },
        {
            title: 'Opened',
            dataIndex: 'createdAt',
            key: 'created',
            width: 110,
            render: (v: string) => (
                <Text type="secondary" style={{ fontSize: 12 }}>
                    {new Date(v).toLocaleDateString()}
                </Text>
            ),
        },
        {
            title: '',
            key: 'action',
            width: 80,
            render: (_: any, r: TicketRow) => (
                <Button
                    size="small"
                    type="primary"
                    ghost
                    style={{ borderColor: '#6366f1', color: '#6366f1', borderRadius: 6 }}
                    onClick={() => setDrawer({ open: true, ticketId: r.id })}
                >
                    Open
                </Button>
            ),
        },
    ];

    return (
        <div>
            {/* ── Page header ─────────────────────────────────────────────── */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20, flexWrap: 'wrap', gap: 8 }}>
                <Title level={3} style={{ margin: 0, color: '#0f172a' }}>
                    Support Tickets
                </Title>
                <Space wrap>
                    <Input.Search
                        placeholder="Search subject..."
                        prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
                        style={{ width: 200 }}
                        allowClear
                        onSearch={(v) => { setSearch(v); setPage(1); }}
                        onChange={(e) => !e.target.value && setSearch('')}
                    />
                    <Select
                        placeholder="Status"
                        allowClear
                        style={{ width: 140 }}
                        onChange={(v) => { setStatus(v); setPage(1); }}
                    >
                        {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map((s) => (
                            <Select.Option key={s} value={s}>
                                <Tag icon={statusIcons[s]} color={statusColors[s]} style={{ margin: 0, borderRadius: 6 }}>
                                    {s.replace('_', ' ')}
                                </Tag>
                            </Select.Option>
                        ))}
                    </Select>
                    <Select
                        placeholder="Priority"
                        allowClear
                        style={{ width: 120 }}
                        onChange={(v) => { setPriority(v); setPage(1); }}
                    >
                        {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((p) => (
                            <Select.Option key={p} value={p}>
                                <Tag color={priorityColors[p]} style={{ margin: 0, borderRadius: 6 }}>{p}</Tag>
                            </Select.Option>
                        ))}
                    </Select>
                    <Select
                        placeholder="Category"
                        allowClear
                        style={{ width: 130 }}
                        onChange={(v) => { setCategory(v); setPage(1); }}
                    >
                        {['BILLING', 'PAYROLL', 'TECHNICAL', 'TAX', 'GENERAL'].map((c) => (
                            <Select.Option key={c} value={c}>
                                <Tag color={categoryColors[c]} style={{ margin: 0, borderRadius: 6 }}>{c}</Tag>
                            </Select.Option>
                        ))}
                    </Select>
                </Space>
            </div>

            {/* ── Summary stat cards ──────────────────────────────────────── */}
            {!status && (
                <Row gutter={16} style={{ marginBottom: 20 }}>
                    <Col xs={12} sm={6}>
                        <Card size="small" style={{ borderRadius: 12, borderColor: '#fee2e2' }}>
                            <Statistic
                                title={<span style={{ fontSize: 12, color: '#94a3b8' }}>Open</span>}
                                value={openCount}
                                prefix={<ExclamationCircleOutlined style={{ color: '#ef4444' }} />}
                                valueStyle={{ color: '#ef4444', fontSize: 22, fontWeight: 700 }}
                            />
                        </Card>
                    </Col>
                    <Col xs={12} sm={6}>
                        <Card size="small" style={{ borderRadius: 12, borderColor: '#dbeafe' }}>
                            <Statistic
                                title={<span style={{ fontSize: 12, color: '#94a3b8' }}>In Progress</span>}
                                value={inProgCount}
                                prefix={<SyncOutlined style={{ color: '#3b82f6' }} />}
                                valueStyle={{ color: '#3b82f6', fontSize: 22, fontWeight: 700 }}
                            />
                        </Card>
                    </Col>
                    <Col xs={12} sm={6}>
                        <Card size="small" style={{ borderRadius: 12, borderColor: '#fde68a' }}>
                            <Statistic
                                title={<span style={{ fontSize: 12, color: '#94a3b8' }}>Urgent</span>}
                                value={urgentCount}
                                prefix={<ExclamationCircleOutlined style={{ color: '#f59e0b' }} />}
                                valueStyle={{ color: '#f59e0b', fontSize: 22, fontWeight: 700 }}
                            />
                        </Card>
                    </Col>
                    <Col xs={12} sm={6}>
                        <Card size="small" style={{ borderRadius: 12 }}>
                            <Statistic
                                title={<span style={{ fontSize: 12, color: '#94a3b8' }}>Total</span>}
                                value={totalCount}
                                prefix={<ClockCircleOutlined style={{ color: '#6366f1' }} />}
                                valueStyle={{ color: '#6366f1', fontSize: 22, fontWeight: 700 }}
                            />
                        </Card>
                    </Col>
                </Row>
            )}

            {/* ── Tickets table ────────────────────────────────────────────── */}
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
                    showTotal: (t) => `${t} tickets`,
                    showSizeChanger: false,
                }}
                style={{ background: '#fff', borderRadius: 14 }}
                rowClassName={(r: TicketRow) =>
                    r.priority === 'URGENT' && r.status === 'OPEN' ? 'ant-table-row-warning' : ''
                }
            />

            {/* ── Ticket detail drawer ─────────────────────────────────────── */}
            <Drawer
                title={
                    ticket ? (
                        <Space align="center">
                            <span style={{ fontWeight: 700, color: '#0f172a', fontSize: 15 }}>
                                {ticket.subject}
                            </span>
                            <Tag
                                icon={statusIcons[ticket.status]}
                                color={statusColors[ticket.status]}
                                style={{ borderRadius: 6, fontWeight: 600 }}
                            >
                                {ticket.status?.replace('_', ' ')}
                            </Tag>
                            <Tag color={priorityColors[ticket.priority]} style={{ borderRadius: 6 }}>
                                {ticket.priority}
                            </Tag>
                        </Space>
                    ) : 'Loading...'
                }
                open={drawer.open}
                onClose={() => { setDrawer({ open: false }); setReplyText(''); }}
                width={640}
                styles={{
                    header: { borderBottom: '1px solid #f1f5f9', paddingBottom: 12 },
                    body: { padding: '16px 20px', background: '#f8fafc' },
                }}
                extra={
                    ticket && canEdit ? (
                        <Space>
                            <Tooltip title="Change status">
                                <Select
                                    value={ticket.status}
                                    key={`status-${ticket.status}`}
                                    style={{ width: 148 }}
                                    size="small"
                                    onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { status: v } })}
                                >
                                    {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map((s) => (
                                        <Select.Option key={s} value={s}>
                                            {s.replace('_', ' ')}
                                        </Select.Option>
                                    ))}
                                </Select>
                            </Tooltip>
                            <Tooltip title="Change priority">
                                <Select
                                    value={ticket.priority}
                                    key={`priority-${ticket.priority}`}
                                    style={{ width: 110 }}
                                    size="small"
                                    onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { priority: v } })}
                                >
                                    {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((p) => (
                                        <Select.Option key={p} value={p}>{p}</Select.Option>
                                    ))}
                                </Select>
                            </Tooltip>
                            {ticket.status !== 'CLOSED' && (
                                <Popconfirm
                                    title="Close this ticket?"
                                    description="This marks it as resolved and closed."
                                    onConfirm={() =>
                                        updateMut.mutate({ id: drawer.ticketId!, data: { status: 'CLOSED' } })
                                    }
                                    okText="Close Ticket"
                                    cancelText="Cancel"
                                >
                                    <Button
                                        size="small"
                                        icon={<CheckCircleOutlined />}
                                        style={{ borderRadius: 6 }}
                                    >
                                        Close
                                    </Button>
                                </Popconfirm>
                            )}
                        </Space>
                    ) : null
                }
            >
                {ticketLoading ? (
                    <div style={{ display: 'flex', justifyContent: 'center', marginTop: 60 }}>
                        <Spin size="large" />
                    </div>
                ) : ticket ? (
                    <>
                        {/* Ticket meta card */}
                        <Card
                            size="small"
                            style={{ marginBottom: 16, borderRadius: 12, background: '#fff' }}
                            bodyStyle={{ padding: '12px 16px' }}
                        >
                            <Row gutter={[12, 8]}>
                                <Col span={12}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>USER</Text>
                                    <div style={{ fontWeight: 600, fontSize: 13, marginTop: 2 }}>
                                        {ticket.user
                                            ? `${ticket.user.firstName || ''} ${ticket.user.lastName || ''}`.trim() ||
                                              ticket.user.email
                                            : 'Unknown'}
                                    </div>
                                    <div style={{ fontSize: 12, color: '#94a3b8' }}>
                                        {ticket.user?.email || '—'}
                                    </div>
                                </Col>
                                <Col span={12}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>CATEGORY</Text>
                                    <div style={{ marginTop: 4 }}>
                                        <Tag
                                            color={categoryColors[ticket.category]}
                                            style={{ borderRadius: 6 }}
                                        >
                                            {ticket.category}
                                        </Tag>
                                    </div>
                                </Col>
                                <Col span={24}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>DESCRIPTION</Text>
                                    <div
                                        style={{
                                            marginTop: 4, fontSize: 13, color: '#374151',
                                            lineHeight: 1.5,
                                            padding: '8px 10px',
                                            background: '#f8fafc',
                                            borderRadius: 8,
                                            border: '1px solid #e2e8f0',
                                        }}
                                    >
                                        {ticket.description}
                                    </div>
                                </Col>
                                <Col span={24}>
                                    <Text type="secondary" style={{ fontSize: 11 }}>
                                        Opened: {new Date(ticket.createdAt).toLocaleString()}
                                    </Text>
                                </Col>
                            </Row>
                        </Card>

                        {/* Message thread */}
                        <Card
                            size="small"
                            style={{ borderRadius: 12, background: '#fff', marginBottom: 16 }}
                            bodyStyle={{ padding: '8px 12px', minHeight: 120, maxHeight: 420, overflowY: 'auto' }}
                            title={
                                <Text style={{ fontSize: 13, fontWeight: 600, color: '#374151' }}>
                                    <MessageOutlined style={{ marginRight: 6, color: '#6366f1' }} />
                                    Conversation ({ticket.messages?.length || 0})
                                </Text>
                            }
                        >
                            <List
                                dataSource={ticket.messages || []}
                                locale={{ emptyText: <Text type="secondary">No messages yet</Text> }}
                                renderItem={(msg: any) => (
                                    <List.Item style={{ padding: '8px 0', border: 'none' }}>
                                        <div
                                            style={{
                                                width: '100%',
                                                display: 'flex',
                                                flexDirection: msg.senderRole === 'ADMIN' ? 'row-reverse' : 'row',
                                                gap: 8,
                                                alignItems: 'flex-end',
                                            }}
                                        >
                                            <Avatar
                                                icon={msg.senderRole === 'ADMIN' ? <RobotOutlined /> : <UserOutlined />}
                                                style={{
                                                    background: msg.senderRole === 'ADMIN'
                                                        ? 'linear-gradient(135deg, #6366f1, #8b5cf6)'
                                                        : '#06b6d4',
                                                    flexShrink: 0,
                                                }}
                                                size={28}
                                            />
                                            <div
                                                style={{
                                                    maxWidth: '78%',
                                                    display: 'flex',
                                                    flexDirection: 'column',
                                                    alignItems: msg.senderRole === 'ADMIN' ? 'flex-end' : 'flex-start',
                                                }}
                                            >
                                                {msg.senderRole === 'ADMIN' && (
                                                    <Text style={{ fontSize: 10, color: '#94a3b8', marginBottom: 3 }}>
                                                        Support Team
                                                    </Text>
                                                )}
                                                <div
                                                    style={{
                                                        padding: '9px 14px',
                                                        borderRadius: msg.senderRole === 'ADMIN'
                                                            ? '16px 4px 16px 16px'
                                                            : '4px 16px 16px 16px',
                                                        background: msg.senderRole === 'ADMIN' ? '#eef2ff' : '#f1f5f9',
                                                        fontSize: 13,
                                                        color: '#0f172a',
                                                        boxShadow: '0 1px 4px rgba(0,0,0,0.04)',
                                                    }}
                                                >
                                                    {msg.message}
                                                </div>
                                                <Text
                                                    type="secondary"
                                                    style={{ fontSize: 10, marginTop: 3 }}
                                                >
                                                    {new Date(msg.createdAt).toLocaleTimeString([], {
                                                        hour: '2-digit', minute: '2-digit',
                                                    })}
                                                    {' · '}
                                                    {new Date(msg.createdAt).toLocaleDateString()}
                                                </Text>
                                            </div>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Card>

                        {/* Reply box */}
                        {canEdit && ticket.status !== 'CLOSED' ? (
                            <Card
                                size="small"
                                style={{ borderRadius: 12 }}
                                bodyStyle={{ padding: 12 }}
                            >
                                <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
                                    <Avatar
                                        icon={<RobotOutlined />}
                                        style={{ background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', flexShrink: 0 }}
                                        size={28}
                                    />
                                    <Input.TextArea
                                        rows={3}
                                        placeholder="Reply as admin… (Enter to send, Shift+Enter for newline)"
                                        value={replyText}
                                        onChange={(e) => setReplyText(e.target.value)}
                                        onPressEnter={(e) => {
                                            if (!e.shiftKey && replyText.trim()) {
                                                e.preventDefault();
                                                replyMut.mutate(replyText.trim());
                                            }
                                        }}
                                        style={{ flex: 1, borderRadius: 10, resize: 'none', fontSize: 13 }}
                                    />
                                    <Button
                                        type="primary"
                                        icon={<SendOutlined />}
                                        loading={replyMut.isPending}
                                        disabled={!replyText.trim()}
                                        onClick={() => replyMut.mutate(replyText.trim())}
                                        style={{
                                            background: '#6366f1', borderColor: '#6366f1',
                                            borderRadius: 10, height: 40,
                                        }}
                                    >
                                        Send
                                    </Button>
                                </div>
                            </Card>
                        ) : ticket.status === 'CLOSED' ? (
                            <div
                                style={{
                                    textAlign: 'center', padding: '12px 16px',
                                    background: '#f8fafc', borderRadius: 10,
                                    border: '1px solid #e2e8f0', color: '#94a3b8',
                                    fontSize: 13,
                                }}
                            >
                                <CheckCircleOutlined style={{ marginRight: 6 }} />
                                This ticket is closed
                            </div>
                        ) : null}
                    </>
                ) : null}
            </Drawer>
        </div>
    );
}
