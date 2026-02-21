import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Select, Input, Typography, Tag, Button, Drawer, message, List, Avatar, Space, Spin, Popconfirm, Tooltip, Badge } from 'antd';
import { SearchOutlined, UserOutlined, RobotOutlined, SendOutlined, CheckCircleOutlined } from '@ant-design/icons';
import { adminSupport } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

const priorityColors: Record<string, string> = { LOW: 'default', MEDIUM: 'orange', HIGH: 'red', URGENT: 'volcano' };
const statusColors: Record<string, string> = { OPEN: 'red', IN_PROGRESS: 'blue', RESOLVED: 'green', CLOSED: 'default' };
const categoryColors: Record<string, string> = { BILLING: 'gold', PAYROLL: 'blue', TECHNICAL: 'purple', TAX: 'orange', GENERAL: 'default' };

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

    // Count open/urgent tickets for badge
    const openCount = data?.total || 0;

    const columns = [
        {
            title: 'Subject',
            dataIndex: 'subject',
            key: 'subject',
            render: (v: string, r: any) => (
                <div>
                    <strong style={{ cursor: 'pointer', color: '#6366f1' }} onClick={() => setDrawer({ open: true, ticketId: r.id })}>{v}</strong>
                    {r.priority === 'URGENT' && <Badge dot style={{ marginLeft: 6 }} />}
                </div>
            ),
        },
        {
            title: 'User',
            key: 'user',
            render: (_: any, r: any) => {
                const name = r.user ? `${r.user.firstName || ''} ${r.user.lastName || ''}`.trim() : 'Unknown';
                const email = r.user?.email || 'No email';
                return (
                    <span>
                        {name || email}
                        <br />
                        <small style={{ color: '#94a3b8' }}>{email}</small>
                    </span>
                );
            },
        },
        {
            title: 'Category',
            dataIndex: 'category',
            key: 'cat',
            width: 100,
            render: (v: string) => <Tag color={categoryColors[v] || 'default'}>{v}</Tag>,
        },
        {
            title: 'Priority',
            dataIndex: 'priority',
            key: 'priority',
            width: 90,
            render: (v: string) => <Tag color={priorityColors[v]}>{v}</Tag>,
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            width: 110,
            render: (v: string) => <Tag color={statusColors[v]}>{v?.replace('_', ' ')}</Tag>,
        },
        {
            title: 'Created',
            dataIndex: 'createdAt',
            key: 'created',
            width: 100,
            render: (v: string) => new Date(v).toLocaleDateString(),
        },
        {
            title: '',
            key: 'open',
            width: 70,
            render: (_: any, r: any) => (
                <Button size="small" onClick={() => setDrawer({ open: true, ticketId: r.id })}>Open</Button>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                <Title level={3} style={{ margin: 0 }}>
                    Support Tickets
                    {openCount > 0 && !status && (
                        <Tag color="red" style={{ marginLeft: 12, fontSize: 13 }}>{openCount} total</Tag>
                    )}
                </Title>
                <Space wrap>
                    <Input.Search
                        placeholder="Search subject..."
                        prefix={<SearchOutlined />}
                        style={{ width: 200 }}
                        allowClear
                        onSearch={(v) => { setSearch(v); setPage(1); }}
                        onChange={(e) => !e.target.value && setSearch('')}
                    />
                    <Select placeholder="Status" allowClear style={{ width: 130 }} onChange={(v) => { setStatus(v); setPage(1); }}>
                        {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map(s =>
                            <Select.Option key={s} value={s}>
                                <Tag color={statusColors[s]} style={{ margin: 0 }}>{s.replace('_', ' ')}</Tag>
                            </Select.Option>
                        )}
                    </Select>
                    <Select placeholder="Priority" allowClear style={{ width: 120 }} onChange={(v) => { setPriority(v); setPage(1); }}>
                        {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map(p =>
                            <Select.Option key={p} value={p}>
                                <Tag color={priorityColors[p]} style={{ margin: 0 }}>{p}</Tag>
                            </Select.Option>
                        )}
                    </Select>
                    <Select placeholder="Category" allowClear style={{ width: 130 }} onChange={(v) => { setCategory(v); setPage(1); }}>
                        {['BILLING', 'PAYROLL', 'TECHNICAL', 'TAX', 'GENERAL'].map(c =>
                            <Select.Option key={c} value={c}>
                                <Tag color={categoryColors[c]} style={{ margin: 0 }}>{c}</Tag>
                            </Select.Option>
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
                    showTotal: (t) => `${t} tickets`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
                rowClassName={(r) => r.priority === 'URGENT' && r.status === 'OPEN' ? 'ant-table-row-warning' : ''}
            />

            <Drawer
                title={
                    ticket ? (
                        <Space>
                            <span>{ticket.subject}</span>
                            <Tag color={statusColors[ticket.status]}>{ticket.status?.replace('_', ' ')}</Tag>
                            <Tag color={priorityColors[ticket.priority]}>{ticket.priority}</Tag>
                        </Space>
                    ) : 'Loading...'
                }
                open={drawer.open}
                onClose={() => { setDrawer({ open: false }); setReplyText(''); }}
                width={620}
                extra={
                    ticket && canEdit && (
                        <Space>
                            <Tooltip title="Change status">
                                <Select
                                    value={ticket.status}
                                    key={`status-${ticket.status}`}
                                    style={{ width: 140 }}
                                    onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { status: v } })}
                                >
                                    {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map(s =>
                                        <Select.Option key={s} value={s}>{s.replace('_', ' ')}</Select.Option>
                                    )}
                                </Select>
                            </Tooltip>
                            <Tooltip title="Change priority">
                                <Select
                                    value={ticket.priority}
                                    key={`priority-${ticket.priority}`}
                                    style={{ width: 110 }}
                                    onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { priority: v } })}
                                >
                                    {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map(p =>
                                        <Select.Option key={p} value={p}>{p}</Select.Option>
                                    )}
                                </Select>
                            </Tooltip>
                            {ticket.status !== 'CLOSED' && (
                                <Popconfirm
                                    title="Close this ticket?"
                                    description="This marks it as resolved and closed."
                                    onConfirm={() => updateMut.mutate({ id: drawer.ticketId!, data: { status: 'CLOSED' } })}
                                    okText="Close Ticket"
                                    cancelText="Cancel"
                                >
                                    <Button size="small" icon={<CheckCircleOutlined />}>Close</Button>
                                </Popconfirm>
                            )}
                        </Space>
                    )
                }
            >
                {ticketLoading ? (
                    <Spin style={{ display: 'block', marginTop: 60, textAlign: 'center' }} />
                ) : ticket ? (
                    <>
                        {/* Ticket Info */}
                        <div style={{ marginBottom: 16, padding: 12, background: '#f8fafc', borderRadius: 8, fontSize: 13 }}>
                            <Space wrap>
                                <span><Text strong>Category: </Text><Tag color={categoryColors[ticket.category]}>{ticket.category}</Tag></span>
                                <span><Text strong>User: </Text>{ticket.user ? `${ticket.user.firstName || ''} ${ticket.user.lastName || ''}`.trim() || ticket.user.email : 'Unknown'} ({ticket.user?.email || 'N/A'})</span>
                                <span><Text strong>Opened: </Text>{new Date(ticket.createdAt).toLocaleString()}</span>
                            </Space>
                            <div style={{ marginTop: 8, padding: '8px 0', borderTop: '1px solid #e2e8f0' }}>
                                <Text type="secondary">{ticket.description}</Text>
                            </div>
                        </div>

                        {/* Message Thread */}
                        <List
                            dataSource={ticket.messages || []}
                            locale={{ emptyText: <Text type="secondary">No messages yet</Text> }}
                            renderItem={(msg: any) => (
                                <List.Item style={{ padding: '6px 0', border: 'none' }}>
                                    <div style={{
                                        width: '100%',
                                        display: 'flex',
                                        flexDirection: msg.senderRole === 'ADMIN' ? 'row-reverse' : 'row',
                                        gap: 8,
                                        alignItems: 'flex-start',
                                    }}>
                                        <Avatar
                                            icon={msg.senderRole === 'ADMIN' ? <RobotOutlined /> : <UserOutlined />}
                                            style={{ background: msg.senderRole === 'ADMIN' ? '#6366f1' : '#06b6d4', flexShrink: 0 }}
                                            size="small"
                                        />
                                        <div style={{
                                            maxWidth: '82%',
                                            padding: '8px 12px',
                                            borderRadius: 12,
                                            background: msg.senderRole === 'ADMIN' ? '#eef2ff' : '#f1f5f9',
                                            textAlign: msg.senderRole === 'ADMIN' ? 'right' : 'left',
                                        }}>
                                            <div style={{ fontSize: 14 }}>{msg.message}</div>
                                            <small style={{ color: '#94a3b8' }}>
                                                {msg.senderRole === 'ADMIN' ? 'Admin · ' : ''}
                                                {new Date(msg.createdAt).toLocaleString()}
                                            </small>
                                        </div>
                                    </div>
                                </List.Item>
                            )}
                        />

                        {/* Reply Box */}
                        {canEdit && ticket.status !== 'CLOSED' && (
                            <div style={{ marginTop: 16, display: 'flex', gap: 8, alignItems: 'flex-end' }}>
                                <Input.TextArea
                                    rows={3}
                                    placeholder="Reply as admin... (Enter to send, Shift+Enter for new line)"
                                    value={replyText}
                                    onChange={(e) => setReplyText(e.target.value)}
                                    onPressEnter={(e) => {
                                        if (!e.shiftKey && replyText.trim()) {
                                            e.preventDefault();
                                            replyMut.mutate(replyText.trim());
                                        }
                                    }}
                                    style={{ flex: 1 }}
                                />
                                <Button
                                    type="primary"
                                    icon={<SendOutlined />}
                                    loading={replyMut.isPending}
                                    disabled={!replyText.trim()}
                                    onClick={() => replyMut.mutate(replyText.trim())}
                                    style={{ background: '#6366f1' }}
                                >
                                    Send
                                </Button>
                            </div>
                        )}
                        {ticket.status === 'CLOSED' && (
                            <div style={{ marginTop: 16, textAlign: 'center', color: '#94a3b8' }}>
                                <CheckCircleOutlined /> This ticket is closed
                            </div>
                        )}
                    </>
                ) : null}
            </Drawer>
        </div>
    );
}
