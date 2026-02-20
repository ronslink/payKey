import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Card, Typography, Tag, Button, Modal, Form, Input, InputNumber, Switch, Space, message, Divider } from 'antd';
import { EditOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminPlans } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title } = Typography;

const tierColors: Record<string, string> = { FREE: 'default', BASIC: 'blue', GOLD: 'gold', PLATINUM: 'purple' };

export default function SubscriptionPlansPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';
    const qc = useQueryClient();
    const [form] = Form.useForm();
    const [editModal, setEditModal] = useState<{ open: boolean; plan?: any }>({ open: false });

    // Queries
    const { data: stats, isLoading: statsLoading } = useQuery({ queryKey: ['admin-plan-stats'], queryFn: adminPlans.stats });
    const { data: plans, isLoading: plansLoading } = useQuery({ queryKey: ['admin-plans'], queryFn: adminPlans.list });

    // Mutations
    const updateMut = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => adminPlans.update(id, data),
        onSuccess: () => {
            message.success('Plan updated');
            setEditModal({ open: false });
            qc.invalidateQueries({ queryKey: ['admin-plans'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    // Columns for Stats
    const statColumns = [
        { title: 'Tier', dataIndex: 'tier', key: 'tier', render: (v: string) => <Tag color={tierColors[v]}>{v}</Tag> },
        { title: 'Active Subscribers', dataIndex: 'subscriber_count', key: 'subscriber_count', render: (v: number) => <strong>{v}</strong> },
        { title: 'Avg Workers / Subscriber', dataIndex: 'avg_workers', key: 'avg_workers', render: (v: number) => Number(v).toFixed(1) },
        { title: 'Total MRR', dataIndex: 'total_mrr', key: 'total_mrr', render: (v: number, r: any) => `${r.currency || 'USD'} ${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` },
    ];

    // Columns for Plans
    const planColumns = [
        { title: 'Tier', dataIndex: 'tier', key: 'tier', render: (v: string) => <Tag color={tierColors[v]}>{v}</Tag> },
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Monthly (USD)', dataIndex: 'priceUSD', key: 'usd', render: (v: number) => `$${Number(v).toFixed(2)}` },
        { title: 'Monthly (KES)', dataIndex: 'priceKES', key: 'kes', render: (v: number) => `KES ${Number(v).toLocaleString()}` },
        { title: 'Yearly (USD)', dataIndex: 'priceUSDYearly', key: 'yusd', render: (v: number) => `$${Number(v).toFixed(2)}` },
        { title: 'Yearly (KES)', dataIndex: 'priceKESYearly', key: 'ykes', render: (v: number) => `KES ${Number(v).toLocaleString()}` },
        { title: 'Worker Limit', dataIndex: 'workerLimit', key: 'limit', align: 'center' as const },
        { title: 'Popular', dataIndex: 'isPopular', key: 'popular', render: (v: boolean) => v ? <Tag color="orange">⭐ Popular</Tag> : '—' },
        {
            title: '',
            key: 'edit',
            render: (_: any, r: any) => canEdit ? (
                <Button icon={<EditOutlined />} size="small" onClick={() => {
                    setEditModal({ open: true, plan: r });
                    form.setFieldsValue(r);
                }}>Edit</Button>
            ) : null,
        },
    ];

    return (
        <div>
            <Title level={3}>Subscriptions Overview (Beta)</Title>
            <Typography.Paragraph type="secondary">
                Aggregated revenue and usage statistics across active subscriptions.
            </Typography.Paragraph>

            <div style={{ display: 'flex', gap: 12, marginBottom: 24, flexWrap: 'wrap' }}>
                {(stats || []).map((stat: any) => (
                    <Card key={stat.tier} size="small" style={{ minWidth: 160, textAlign: 'center', borderRadius: 10 }}>
                        <Tag color={tierColors[stat.tier]}>{stat.tier}</Tag>
                        <div style={{ fontSize: 24, fontWeight: 700, marginTop: 4 }}>{stat.subscriber_count}</div>
                        <div style={{ fontSize: 11, color: '#94a3b8' }}>active subscribers</div>
                        <div style={{ fontSize: 14, fontWeight: 500, marginTop: 8 }}>
                            {stat.currency || 'USD'} {Number(stat.total_mrr).toLocaleString(undefined, { minimumFractionDigits: 2 })} MRR
                        </div>
                    </Card>
                ))}
            </div>

            <Table
                columns={statColumns}
                dataSource={stats || []}
                rowKey="tier"
                loading={statsLoading}
                pagination={false}
                style={{ background: '#fff', borderRadius: 12, marginBottom: 24 }}
            />

            <Divider />

            <Title level={3}>Manage Subscription Pricing & Limits</Title>
            <Table
                columns={planColumns}
                dataSource={plans || []}
                rowKey="id"
                loading={plansLoading}
                pagination={false}
                style={{ background: '#fff', borderRadius: 12, marginBottom: 24 }}
            />

            <Modal
                title={`Edit Plan: ${editModal.plan?.name}`}
                open={editModal.open}
                onCancel={() => setEditModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={updateMut.isPending}
            >
                <Form form={form} layout="vertical" onFinish={(v) => updateMut.mutate({ id: editModal.plan?.id, data: v })}>
                    <Form.Item label="Name" name="name" rules={[{ required: true }]}>
                        <Input />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Monthly (USD)" name="priceUSD">
                            <InputNumber min={0} prefix="$" style={{ width: 130 }} />
                        </Form.Item>
                        <Form.Item label="Monthly (KES)" name="priceKES">
                            <InputNumber min={0} style={{ width: 130 }} />
                        </Form.Item>
                    </Space>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Yearly (USD)" name="priceUSDYearly">
                            <InputNumber min={0} prefix="$" style={{ width: 130 }} />
                        </Form.Item>
                        <Form.Item label="Yearly (KES)" name="priceKESYearly">
                            <InputNumber min={0} style={{ width: 130 }} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Worker Limit" name="workerLimit">
                        <InputNumber min={1} />
                    </Form.Item>
                    <Form.Item label="Mark as Popular" name="isPopular" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Modal>

        </div>
    );
}
