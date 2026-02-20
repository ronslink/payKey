import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Select, Input, Typography, Tag, Button, Drawer, message, List, Avatar, Space, Spin } from 'antd';
import { SearchOutlined, UserOutlined, RobotOutlined, SendOutlined } from '@ant-design/icons';
import { adminSupport } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

const priorityColors: Record<string, string> = { LOW: 'default', MEDIUM: 'orange', HIGH: 'red', URGENT: 'volcano' };
const statusColors: Record<string, string> = { OPEN: 'red', IN_PROGRESS: 'blue', RESOLVED: 'green', CLOSED: 'default' };

export default function SupportPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [search, setSearch] = useState('');
    const [status, setStatus] = useState<string>();
    const [priority, setPriority] = useState<string>();
    const [page, setPage] = useState(1);
    const [drawer, setDrawer] = useState<{ open: boolean; ticketId?: string }>({ open: false });
    const [replyText, setReplyText] = useState('');

    const { data, isLoading } = useQuery({
        queryKey: ['admin-support', search, status, priority, page],
        queryFn: () => adminSupport.list({ search: search || undefined, status, priority, page }),
    });

    const { data: ticket, isLoading: ticketLoading } = useQuery({
        queryKey: ['admin-ticket', drawer.ticketId],
        queryFn: () => adminSupport.detail(drawer.ticketId!),
        enabled: !!drawer.ticketId && drawer.open,
    });

    const updateMut = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => adminSupport.update(id, data),
        onSuccess: () => { message.success('Updated'); qc.invalidateQueries({ queryKey: ['admin-support'] }); qc.invalidateQueries({ queryKey: ['admin-ticket', drawer.ticketId] }); },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    const replyMut = useMutation({
        mutationFn: (message: string) => adminSupport.reply(drawer.ticketId!, message),
        onSuccess: () => { setReplyText(''); qc.invalidateQueries({ queryKey: ['admin-ticket', drawer.ticketId] }); },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Reply failed'),
    });

    const columns = [
        { title: 'Subject', dataIndex: 'subject', key: 'subject', render: (v: string) => <strong>{v}</strong> },
        { title: 'User', dataIndex: 'userName', key: 'user', render: (v: string, r: any) => <span>{v}<br /><small style={{ color: '#94a3b8' }}>{r.userEmail}</small></span> },
        { title: 'Category', dataIndex: 'category', key: 'cat', render: (v: string) => <Tag>{v}</Tag> },
        { title: 'Priority', dataIndex: 'priority', key: 'priority', render: (v: string) => <Tag color={priorityColors[v]}>{v}</Tag> },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={statusColors[v]}>{v}</Tag> },
        { title: 'Created', dataIndex: 'createdAt', key: 'created', render: (v: string) => new Date(v).toLocaleDateString() },
        {
            title: '',
            key: 'open',
            render: (_: any, r: any) => (
                <Button size="small" onClick={() => setDrawer({ open: true, ticketId: r.id })}>Open</Button>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                <Title level={3} style={{ margin: 0 }}>Support Tickets</Title>
                <div style={{ display: 'flex', gap: 8 }}>
                    <Input.Search
                        placeholder="Search..."
                        prefix={<SearchOutlined />}
                        style={{ width: 200 }}
                        allowClear
                        onSearch={setSearch}
                        onChange={(e) => !e.target.value && setSearch('')}
                    />
                    <Select placeholder="Status" allowClear style={{ width: 130 }} onChange={setStatus}>
                        {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
                    </Select>
                    <Select placeholder="Priority" allowClear style={{ width: 120 }} onChange={setPriority}>
                        {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map(p => <Select.Option key={p} value={p}>{p}</Select.Option>)}
                    </Select>
                </div>
            </div>

            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey="id"
                loading={isLoading}
                pagination={{ total: data?.total, pageSize: 20, current: page, onChange: setPage }}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            <Drawer
                title={ticket ? ticket.subject : 'Loading...'}
                open={drawer.open}
                onClose={() => setDrawer({ open: false })}
                width={600}
                extra={
                    ticket && canEdit && (
                        <Space>
                            <Select
                                defaultValue={ticket.status}
                                key={ticket.status}
                                style={{ width: 130 }}
                                onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { status: v } })}
                            >
                                {['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
                            </Select>
                            <Select
                                defaultValue={ticket.priority}
                                key={ticket.priority}
                                style={{ width: 110 }}
                                onChange={(v) => updateMut.mutate({ id: drawer.ticketId!, data: { priority: v } })}
                            >
                                {['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map(p => <Select.Option key={p} value={p}>{p}</Select.Option>)}
                            </Select>
                        </Space>
                    )
                }
            >
                {ticketLoading ? (
                    <Spin style={{ display: 'block', marginTop: 60, textAlign: 'center' }} />
                ) : ticket ? (
                    <>
                        <div style={{ marginBottom: 16, padding: 12, background: '#f8fafc', borderRadius: 8 }}>
                            <Text strong>Category: </Text><Tag>{ticket.category}</Tag>
                            <Text strong style={{ marginLeft: 12 }}>User: </Text><Text>{ticket.userName} ({ticket.userEmail})</Text>
                            <div style={{ marginTop: 8 }}>
                                <Text type="secondary">{ticket.description}</Text>
                            </div>
                        </div>

                        <List
                            dataSource={ticket.messages || []}
                            renderItem={(msg: any) => (
                                <List.Item style={{ padding: '8px 0', border: 'none' }}>
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
                                        />
                                        <div style={{
                                            maxWidth: '80%',
                                            padding: '8px 12px',
                                            borderRadius: 12,
                                            background: msg.senderRole === 'ADMIN' ? '#eef2ff' : '#f1f5f9',
                                            textAlign: msg.senderRole === 'ADMIN' ? 'right' : 'left',
                                        }}>
                                            <div>{msg.message}</div>
                                            <small style={{ color: '#94a3b8' }}>{new Date(msg.createdAt).toLocaleTimeString()}</small>
                                        </div>
                                    </div>
                                </List.Item>
                            )}
                        />

                        {canEdit && (
                            <div style={{ marginTop: 16, display: 'flex', gap: 8 }}>
                                <Input.TextArea
                                    rows={2}
                                    placeholder="Reply as admin..."
                                    value={replyText}
                                    onChange={(e) => setReplyText(e.target.value)}
                                    onPressEnter={(e) => {
                                        if (!e.shiftKey && replyText.trim()) {
                                            e.preventDefault();
                                            replyMut.mutate(replyText.trim());
                                        }
                                    }}
                                />
                                <Button
                                    type="primary"
                                    icon={<SendOutlined />}
                                    loading={replyMut.isPending}
                                    disabled={!replyText.trim()}
                                    onClick={() => replyMut.mutate(replyText.trim())}
                                    style={{ background: '#6366f1', alignSelf: 'flex-end' }}
                                >
                                    Send
                                </Button>
                            </div>
                        )}
                    </>
                ) : null}
            </Drawer>
        </div>
    );
}
