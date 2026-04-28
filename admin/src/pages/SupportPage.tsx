import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Table, Select, Input, Typography, Tag, Button, Drawer, message,
    Avatar, Space, Spin, Card, Row, Col,
    Progress, Empty, Timeline, Alert
} from 'antd';
import {
    SearchOutlined, UserOutlined, SendOutlined,
    CheckCircleOutlined, ClockCircleOutlined, SyncOutlined,
    ExclamationCircleOutlined, InboxOutlined,
    DashboardOutlined, ThunderboltOutlined, AlertOutlined,
    FileTextOutlined, ArrowUpOutlined,
    CheckOutlined, MessageOutlined, InfoCircleOutlined
} from '@ant-design/icons';
import { adminSupport } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

// Enhanced color schemes
const priorityConfig: Record<string, { color: string; bg: string; icon: React.ReactNode }> = {
    LOW: { color: '#10b981', bg: '#d1fae5', icon: <InfoCircleOutlined /> },
    MEDIUM: { color: '#f59e0b', bg: '#fef3c7', icon: <ClockCircleOutlined /> },
    HIGH: { color: '#f97316', bg: '#ffedd5', icon: <AlertOutlined /> },
    URGENT: { color: '#ef4444', bg: '#fee2e2', icon: <ThunderboltOutlined /> },
};

const statusConfig: Record<string, { color: string; bg: string; icon: React.ReactNode; label: string }> = {
    OPEN: { color: '#ef4444', bg: '#fee2e2', icon: <ExclamationCircleOutlined />, label: 'Open' },
    IN_PROGRESS: { color: '#3b82f6', bg: '#dbeafe', icon: <SyncOutlined spin />, label: 'In Progress' },
    RESOLVED: { color: '#10b981', bg: '#d1fae5', icon: <CheckCircleOutlined />, label: 'Resolved' },
    CLOSED: { color: '#6b7280', bg: '#f3f4f6', icon: <InboxOutlined />, label: 'Closed' },
};

const categoryConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    BILLING: { color: '#f59e0b', icon: <FileTextOutlined />, label: 'Billing' },
    PAYROLL: { color: '#6366f1', icon: <DashboardOutlined />, label: 'Payroll' },
    TECHNICAL: { color: '#ec4899', icon: <ThunderboltOutlined />, label: 'Technical' },
    ACCOUNT: { color: '#06b6d4', icon: <UserOutlined />, label: 'Account' },
    GENERAL: { color: '#8b5cf6', icon: <MessageOutlined />, label: 'General' },
};

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

// Summary Card Component
function SummaryCard({ title, value, icon, color, subtitle, trend }: any) {
    return (
        <Card
            style={{
                borderRadius: 16,
                border: 'none',
                background: `linear-gradient(135deg, ${color}15 0%, ${color}08 100%)`,
                boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)',
            }}
            bodyStyle={{ padding: 20 }}
        >
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                    <Text style={{ fontSize: 13, color: '#64748b', fontWeight: 500 }}>{title}</Text>
                    <div style={{ marginTop: 8 }}>
                        <Text style={{ fontSize: 32, fontWeight: 700, color }}>{value}</Text>
                    </div>
                    {subtitle && (
                        <Text style={{ fontSize: 12, color: '#9ca3af' }}>{subtitle}</Text>
                    )}
                    {trend && (
                        <div style={{ marginTop: 4 }}>
                            <Tag color={trend > 0 ? 'success' : 'default'} style={{ fontSize: 11 }}>
                                <ArrowUpOutlined rotate={trend > 0 ? 0 : 180} /> {Math.abs(trend)}%
                            </Tag>
                        </div>
                    )}
                </div>
                <div style={{
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    background: color,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white',
                    fontSize: 24,
                }}>
                    {icon}
                </div>
            </div>
        </Card>
    );
}

// Ticket Status Badge
function StatusBadge({ status }: { status: string }) {
    const config = statusConfig[status] || statusConfig.OPEN;
    return (
        <Tag
            style={{
                background: config.bg,
                border: `1px solid ${config.color}`,
                color: config.color,
                fontWeight: 600,
                padding: '4px 12px',
                borderRadius: 20,
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                fontSize: 12,
            }}
        >
            {config.icon}
            {config.label}
        </Tag>
    );
}

// Priority Badge
function PriorityBadge({ priority }: { priority: string }) {
    const config = priorityConfig[priority] || priorityConfig.LOW;
    return (
        <Tag
            style={{
                background: config.bg,
                border: `1px solid ${config.color}`,
                color: config.color,
                fontWeight: 600,
                padding: '4px 10px',
                borderRadius: 20,
                display: 'flex',
                alignItems: 'center',
                gap: 4,
                fontSize: 12,
            }}
        >
            {config.icon}
            {priority}
        </Tag>
    );
}

// Category Badge
function CategoryBadge({ category }: { category: string }) {
    const config = categoryConfig[category] || categoryConfig.GENERAL;
    return (
        <Tag
            style={{
                background: `${config.color}15`,
                border: `1px solid ${config.color}40`,
                color: config.color,
                fontWeight: 500,
                padding: '4px 10px',
                borderRadius: 20,
                fontSize: 12,
            }}
        >
            {config.label}
        </Tag>
    );
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

    // Calculate metrics
    const tickets: TicketRow[] = data?.data || [];
    const totalCount = data?.total || 0;
    const openCount = tickets.filter((t) => t.status === 'OPEN').length;
    const urgentCount = tickets.filter((t) => t.priority === 'URGENT' && t.status === 'OPEN').length;
    const inProgCount = tickets.filter((t) => t.status === 'IN_PROGRESS').length;
    const resolvedToday = tickets.filter((t) => t.status === 'RESOLVED').length;

    // Resolution rate
    const resolutionRate = totalCount > 0 ? Math.round((resolvedToday / totalCount) * 100) : 0;

    const columns = [
        {
            title: 'Ticket',
            dataIndex: 'subject',
            key: 'subject',
            width: 280,
            render: (v: string, r: TicketRow) => (
                <div>
                    <Text strong style={{ fontSize: 14, color: '#1f2937' }}>{v}</Text>
                    <div style={{ marginTop: 4 }}>
                        <CategoryBadge category={r.category} />
                    </div>
                </div>
            ),
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            width: 140,
            render: (v: string) => <StatusBadge status={v} />,
        },
        {
            title: 'Priority',
            dataIndex: 'priority',
            key: 'priority',
            width: 120,
            render: (v: string) => <PriorityBadge priority={v} />,
        },
        {
            title: 'User',
            dataIndex: 'user',
            key: 'user',
            width: 200,
            render: (u?: { firstName?: string; lastName?: string; email?: string }) => (
                <Space>
                    <Avatar style={{ background: '#6366f1' }} icon={<UserOutlined />} />
                    <div>
                        <Text style={{ fontSize: 13, fontWeight: 500 }}>
                            {u?.firstName || u?.lastName ? `${u.firstName || ''} ${u.lastName || ''}`.trim() : 'Unknown'}
                        </Text>
                        <div style={{ fontSize: 11, color: '#9ca3af' }}>{u?.email || 'No email'}</div>
                    </div>
                </Space>
            ),
        },
        {
            title: 'Created',
            dataIndex: 'createdAt',
            key: 'createdAt',
            width: 150,
            render: (v: string) => (
                <Text style={{ fontSize: 13, color: '#6b7280' }}>
                    {new Date(v).toLocaleDateString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                </Text>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 100,
            render: (_: any, r: TicketRow) => (
                <Button
                    type="primary"
                    ghost
                    size="small"
                    onClick={() => setDrawer({ open: true, ticketId: r.id })}
                    style={{ borderRadius: 6 }}
                >
                    View
                </Button>
            ),
        },
    ];

    return (
        <div style={{ padding: 24, background: '#f8fafc', minHeight: '100vh' }}>
            {/* Header */}
            <div style={{ marginBottom: 24 }}>
                <Title level={3} style={{ margin: 0, color: '#1f2937' }}>Support Center</Title>
                <Text style={{ color: '#6b7280' }}>Manage customer tickets and inquiries</Text>
            </div>

            {/* Summary Dashboard */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <SummaryCard
                        title="Total Tickets"
                        value={totalCount}
                        icon={<InboxOutlined />}
                        color="#6366f1"
                        subtitle="All time"
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <SummaryCard
                        title="Open Tickets"
                        value={openCount}
                        icon={<ExclamationCircleOutlined />}
                        color="#ef4444"
                        subtitle="Awaiting response"
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <SummaryCard
                        title="In Progress"
                        value={inProgCount}
                        icon={<SyncOutlined spin />}
                        color="#3b82f6"
                        subtitle="Being handled"
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <SummaryCard
                        title="Urgent"
                        value={urgentCount}
                        icon={<ThunderboltOutlined />}
                        color="#f59e0b"
                        subtitle="Requires immediate attention"
                    />
                </Col>
            </Row>

            {/* Resolution Progress */}
            <Card
                style={{ marginBottom: 24, borderRadius: 16, border: 'none' }}
                bodyStyle={{ padding: 20 }}
            >
                <div style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
                    <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                            <Text strong style={{ fontSize: 14 }}>Resolution Progress</Text>
                            <Text style={{ color: '#10b981', fontWeight: 600 }}>{resolutionRate}%</Text>
                        </div>
                        <Progress
                            percent={resolutionRate}
                            strokeColor={{ from: '#10b981', to: '#34d399' }}
                            strokeWidth={10}
                            showInfo={false}
                            trailColor="#e5e7eb"
                        />
                        <Text style={{ fontSize: 12, color: '#9ca3af' }}>
                            {resolvedToday} of {totalCount} tickets resolved
                        </Text>
                    </div>
                    {urgentCount > 0 && (
                        <Alert
                            message={`${urgentCount} urgent ticket${urgentCount > 1 ? 's' : ''} require immediate attention`}
                            type="warning"
                            showIcon
                            style={{ borderRadius: 8 }}
                        />
                    )}
                </div>
            </Card>

            {/* Filters */}
            <Card
                style={{ marginBottom: 24, borderRadius: 16, border: 'none' }}
                bodyStyle={{ padding: 20 }}
            >
                <Space wrap size="middle">
                    <Input
                        placeholder="Search tickets..."
                        prefix={<SearchOutlined />}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        onPressEnter={() => setPage(1)}
                        style={{ width: 260, borderRadius: 8 }}
                        allowClear
                    />
                    <Select
                        placeholder="Status"
                        allowClear
                        style={{ width: 140, borderRadius: 8 }}
                        onChange={(v) => { setStatus(v); setPage(1); }}
                        value={status}
                        options={[
                            { value: 'OPEN', label: 'Open' },
                            { value: 'IN_PROGRESS', label: 'In Progress' },
                            { value: 'RESOLVED', label: 'Resolved' },
                            { value: 'CLOSED', label: 'Closed' },
                        ]}
                    />
                    <Select
                        placeholder="Priority"
                        allowClear
                        style={{ width: 140, borderRadius: 8 }}
                        onChange={(v) => { setPriority(v); setPage(1); }}
                        value={priority}
                        options={[
                            { value: 'URGENT', label: 'Urgent' },
                            { value: 'HIGH', label: 'High' },
                            { value: 'MEDIUM', label: 'Medium' },
                            { value: 'LOW', label: 'Low' },
                        ]}
                    />
                    <Select
                        placeholder="Category"
                        allowClear
                        style={{ width: 140, borderRadius: 8 }}
                        onChange={(v) => { setCategory(v); setPage(1); }}
                        value={category}
                        options={[
                            { value: 'BILLING', label: 'Billing' },
                            { value: 'PAYROLL', label: 'Payroll' },
                            { value: 'TECHNICAL', label: 'Technical' },
                            { value: 'ACCOUNT', label: 'Account' },
                            { value: 'GENERAL', label: 'General' },
                        ]}
                    />
                    <Button type="primary" onClick={() => { setSearch(''); setStatus(undefined); setPriority(undefined); setCategory(undefined); setPage(1); }} style={{ borderRadius: 8 }}>
                        Clear Filters
                    </Button>
                </Space>
            </Card>

            {/* Tickets Table */}
            <Card style={{ borderRadius: 16, border: 'none' }} bodyStyle={{ padding: 0 }}>
                <Table
                    columns={columns}
                    dataSource={tickets}
                    rowKey="id"
                    loading={isLoading}
                    pagination={{
                        current: page,
                        pageSize: 10,
                        total: totalCount,
                        onChange: setPage,
                        showSizeChanger: false,
                        showTotal: (t) => `Total ${t} tickets`,
                    }}
                    scroll={{ x: 'max-content' }}
                    style={{ borderRadius: 16 }}
                    rowClassName={(record) => record.priority === 'URGENT' ? 'urgent-row' : ''}
                />
            </Card>

            <style>{`
                .urgent-row {
                    background: linear-gradient(90deg, #fef2f2 0%, #fff5f5 100%);
                }
                .urgent-row:hover td {
                    background: #fee2e2 !important;
                }
            `}</style>

            {/* Ticket Detail Drawer */}
            <Drawer
                title={null}
                placement="right"
                width={600}
                onClose={() => setDrawer({ open: false })}
                open={drawer.open}
                bodyStyle={{ padding: 0, background: '#f8fafc' }}
                headerStyle={{ display: 'none' }}
            >
                {ticketLoading ? (
                    <div style={{ padding: 40, textAlign: 'center' }}>
                        <Spin size="large" />
                    </div>
                ) : !ticket ? (
                    <Empty description="Ticket not found" style={{ marginTop: 100 }} />
                ) : (
                    <div>
                        {/* Drawer Header */}
                        <div style={{ padding: 24, background: 'white', borderBottom: '1px solid #e5e7eb' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
                                <div>
                                    <Text style={{ fontSize: 12, color: '#9ca3af' }}>Ticket #{ticket.id?.slice(0, 8)}</Text>
                                    <Title level={4} style={{ margin: '8px 0 0 0', color: '#1f2937' }}>{ticket.subject}</Title>
                                </div>
                                <Button icon={<CheckOutlined />} onClick={() => setDrawer({ open: false })} />
                            </div>
                            <Space wrap size="small">
                                <StatusBadge status={ticket.status} />
                                <PriorityBadge priority={ticket.priority} />
                                <CategoryBadge category={ticket.category} />
                            </Space>
                        </div>

                        {/* User Info */}
                        <div style={{ padding: 16, background: '#f3f4f6' }}>
                            <Card style={{ borderRadius: 12 }} bodyStyle={{ padding: 16 }}>
                                <Space>
                                    <Avatar size={48} style={{ background: '#6366f1' }} icon={<UserOutlined />} />
                                    <div>
                                        <Text strong style={{ fontSize: 16 }}>
                                            {ticket.user?.firstName || ticket.user?.lastName
                                                ? `${ticket.user.firstName || ''} ${ticket.user.lastName || ''}`.trim()
                                                : 'Unknown User'}
                                        </Text>
                                        <div style={{ fontSize: 13, color: '#6b7280' }}>{ticket.user?.email}</div>
                                    </div>
                                </Space>
                            </Card>
                        </div>

                        {/* Messages */}
                        <div style={{ padding: 24, maxHeight: 'calc(100vh - 400px)', overflowY: 'auto' }}>
                            <Timeline
                                items={(ticket.messages || []).map((m: any) => ({
                                    dot: m.senderRole === 'ADMIN' ? (
                                        <Avatar size="small" style={{ background: '#10b981' }} icon={<CheckCircleOutlined />} />
                                    ) : (
                                        <Avatar size="small" style={{ background: '#6366f1' }} icon={<UserOutlined />} />
                                    ),
                                    children: (
                                        <Card
                                            size="small"
                                            style={{
                                                borderRadius: 12,
                                                background: m.senderRole === 'ADMIN' ? '#ecfdf5' : 'white',
                                                border: m.senderRole === 'ADMIN' ? '1px solid #10b98130' : '1px solid #e5e7eb',
                                                marginBottom: 16,
                                            }}
                                        >
                                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                                                <Text strong style={{ color: m.senderRole === 'ADMIN' ? '#10b981' : '#6366f1' }}>
                                                    {m.senderRole === 'ADMIN' ? 'Support Team' : 'Customer'}
                                                </Text>
                                                <Text style={{ fontSize: 12, color: '#9ca3af' }}>
                                                    {new Date(m.createdAt).toLocaleString()}
                                                </Text>
                                            </div>
                                            <Text style={{ whiteSpace: 'pre-wrap', fontSize: 14 }}>{m.message}</Text>
                                        </Card>
                                    ),
                                }))}
                            />
                        </div>

                        {/* Reply Section */}
                        {canEdit && ticket.status !== 'CLOSED' && (
                            <div style={{ padding: 24, background: 'white', borderTop: '1px solid #e5e7eb' }}>
                                <div style={{ display: 'flex', gap: 12 }}>
                                    <Input.TextArea
                                        value={replyText}
                                        onChange={(e) => setReplyText(e.target.value)}
                                        placeholder="Type your reply..."
                                        rows={3}
                                        style={{ borderRadius: 12 }}
                                    />
                                    <Button
                                        type="primary"
                                        icon={<SendOutlined />}
                                        loading={replyMut.isPending}
                                        onClick={() => replyText.trim() && replyMut.mutate(replyText)}
                                        disabled={!replyText.trim()}
                                        style={{ borderRadius: 12, height: 'auto' }}
                                    >
                                        Send
                                    </Button>
                                </div>
                                <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
                                    <Select
                                        value={ticket.status}
                                        onChange={(v) => updateMut.mutate({ id: ticket.id, data: { status: v } })}
                                        style={{ width: 140 }}
                                        options={[
                                            { value: 'OPEN', label: 'Open' },
                                            { value: 'IN_PROGRESS', label: 'In Progress' },
                                            { value: 'RESOLVED', label: 'Resolved' },
                                            { value: 'CLOSED', label: 'Closed' },
                                        ]}
                                        size="small"
                                    />
                                    <Select
                                        value={ticket.priority}
                                        onChange={(v) => updateMut.mutate({ id: ticket.id, data: { priority: v } })}
                                        style={{ width: 120 }}
                                        options={[
                                            { value: 'URGENT', label: 'Urgent' },
                                            { value: 'HIGH', label: 'High' },
                                            { value: 'MEDIUM', label: 'Medium' },
                                            { value: 'LOW', label: 'Low' },
                                        ]}
                                        size="small"
                                    />
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </Drawer>
        </div>
    );
}
