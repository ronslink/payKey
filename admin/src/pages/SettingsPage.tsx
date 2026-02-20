import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Typography, Button, Modal, Form, Input, message } from 'antd';
import { EditOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminSystemConfig } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title } = Typography;

export default function SettingsPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [editModal, setEditModal] = useState<{ open: boolean; record?: any }>({ open: false });
    const [form] = Form.useForm();

    const { data: configs, isLoading } = useQuery({ queryKey: ['admin-system-config'], queryFn: adminSystemConfig.list });

    const updateMut = useMutation({
        mutationFn: ({ key, data }: { key: string; data: any }) => adminSystemConfig.update(key, data),
        onSuccess: () => {
            message.success('Setting updated');
            setEditModal({ open: false });
            qc.invalidateQueries({ queryKey: ['admin-system-config'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    const columns = [
        { title: 'Configuration Key', dataIndex: 'key', key: 'key', render: (v: string) => <Typography.Text code>{v}</Typography.Text> },
        { title: 'Value', dataIndex: 'value', key: 'value', render: (v: string) => <div style={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{v}</div> },
        { title: 'Description', dataIndex: 'description', key: 'desc', render: (v: string) => <Typography.Text type="secondary">{v || '—'}</Typography.Text> },
        {
            title: '',
            key: 'edit',
            width: 80,
            render: (_: any, r: any) => canEdit ? (
                <Button icon={<EditOutlined />} size="small" onClick={() => {
                    setEditModal({ open: true, record: r });
                    form.setFieldsValue(r);
                }}>Edit</Button>
            ) : null,
        },
    ];

    return (
        <div>
            <Title level={3}>System Settings</Title>
            <p style={{ color: '#64748b', marginBottom: 24 }}>Manage global configuration values and feature flags for the platform.</p>

            <Table
                columns={columns}
                dataSource={configs || []}
                rowKey="key"
                loading={isLoading}
                pagination={false}
                style={{ background: '#fff', borderRadius: 12, marginBottom: 24 }}
            />

            <Modal
                title={`Edit Setting: ${editModal.record?.key}`}
                open={editModal.open}
                onCancel={() => setEditModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={updateMut.isPending}
            >
                <Form form={form} layout="vertical" onFinish={(v) => updateMut.mutate({ key: editModal.record?.key, data: v })}>
                    <Form.Item label="Value" name="value" rules={[{ required: true }]}>
                        <Input.TextArea rows={4} />
                    </Form.Item>
                    <Form.Item label="Description" name="description">
                        <Input />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
