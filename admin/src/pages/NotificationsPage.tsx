import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Typography, Button, Modal, Form, Input, Select, Tag, Switch, Space, message, Spin } from 'antd';
import { SendOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminNotifications, adminUsers } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title } = Typography;

export default function NotificationsPage() {
    const { user } = useAuth();
    const canSend = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [sendModal, setSendModal] = useState(false);
    const [isBroadcast, setIsBroadcast] = useState(true);
    const [notifType, setNotifType] = useState('EMAIL');
    const [form] = Form.useForm();
    const [page, setPage] = useState(1);
    const [typeFilter, setTypeFilter] = useState<string>();

    const { data, isLoading } = useQuery({
        queryKey: ['admin-notifications', page, typeFilter],
        queryFn: () => adminNotifications.list({ page, typeFilter }),
    });

    const { data: usersData, isLoading: usersLoading } = useQuery({
        queryKey: ['admin-users-all'],
        queryFn: () => adminUsers.list({ limit: 1000 }), // for selecting users
    });

    const sendMut = useMutation({
        mutationFn: (vals: any) => adminNotifications.send(vals),
        onSuccess: (res) => {
            message.success(res.message);
            setSendModal(false);
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-notifications'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Send failed'),
    });

    const columns = [
        {
            title: 'Type',
            dataIndex: 'type',
            key: 'type',
            render: (v: string) => <Tag color={v === 'EMAIL' ? 'blue' : v === 'SMS' ? 'orange' : 'purple'}>{v}</Tag>
        },
        {
            title: 'Recipient',
            key: 'recipient',
            render: (_: any, r: any) => r.recipient || r.user?.email || '—'
        },
        { title: 'Subject', dataIndex: 'subject', key: 'subject' },
        { title: 'Message', dataIndex: 'message', key: 'msg', render: (v: string) => <div style={{ maxWidth: 300, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{v}</div> },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={v === 'SENT' ? 'green' : v === 'FAILED' ? 'red' : 'default'}>{v}</Tag> },
        { title: 'Sent At', dataIndex: 'sentAt', key: 'sentAt', render: (v: string) => v ? new Date(v).toLocaleString() : '—' },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                <Title level={3} style={{ margin: 0 }}>Notifications History</Title>
                {canSend && (
                    <Button
                        type="primary"
                        icon={<SendOutlined />}
                        style={{ background: '#6366f1' }}
                        onClick={() => setSendModal(true)}
                    >
                        Compose
                    </Button>
                )}
            </div>

            <div style={{ marginBottom: 16 }}>
                <Select placeholder="Filter by Type" allowClear style={{ width: 150 }} onChange={setTypeFilter}>
                    {['EMAIL', 'SMS', 'PUSH'].map(t => <Select.Option key={t} value={t}>{t}</Select.Option>)}
                </Select>
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
                title="Compose Notification"
                open={sendModal}
                onCancel={() => setSendModal(false)}
                onOk={() => form.submit()}
                confirmLoading={sendMut.isPending}
                width={600}
            >
                <Form
                    form={form}
                    layout="vertical"
                    initialValues={{ broadcast: true, type: 'EMAIL' }}
                    onValuesChange={(changed) => {
                        if (changed.broadcast !== undefined) setIsBroadcast(changed.broadcast);
                        if (changed.type !== undefined) setNotifType(changed.type);
                    }}
                    onFinish={(v) => sendMut.mutate(v)}
                >
                    <Form.Item label="Message Type" name="type" rules={[{ required: true }]}>
                        <Select>
                            <Select.Option value="EMAIL">Email</Select.Option>
                            <Select.Option value="SMS">SMS</Select.Option>
                            <Select.Option value="PUSH">Push</Select.Option>
                        </Select>
                    </Form.Item>

                    <Form.Item label="Broadcast to All Users" name="broadcast" valuePropName="checked">
                        <Switch />
                    </Form.Item>

                    {!isBroadcast && (
                        <Form.Item label="Select Recipients (Employers)" name="userIds" rules={[{ required: true, message: 'Please select at least one' }]}>
                            {usersLoading ? <Spin size="small" /> : (
                                <Select mode="multiple" placeholder="Select users" filterOption={(input, option: any) => option.children.toLowerCase().includes(input.toLowerCase())}>
                                    {(usersData?.data || []).map((u: any) => (
                                        <Select.Option key={u.id} value={u.id}>{u.firstName} {u.lastName} ({u.email})</Select.Option>
                                    ))}
                                </Select>
                            )}
                        </Form.Item>
                    )}

                    {(notifType === 'EMAIL' || notifType === 'PUSH') && (
                        <Form.Item label="Subject / Title" name="subject" rules={[{ required: true }]}>
                            <Input />
                        </Form.Item>
                    )}

                    <Form.Item label="Message Body" name="message" rules={[{ required: true }]}>
                        <Input.TextArea rows={4} />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
