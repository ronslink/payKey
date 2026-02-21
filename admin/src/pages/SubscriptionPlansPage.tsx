import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Card, Typography, Tag, Button, Modal, Form, Input, InputNumber, Switch, Space, message, Divider, Tabs, Statistic, Row, Col, Select, DatePicker, Badge, Popconfirm } from 'antd';
import { EditOutlined, PlusOutlined, DeleteOutlined, PlayCircleOutlined, PauseCircleOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminPlans, adminPromotionalItems, adminCampaigns } from '../api/client';
import { useAuth } from '../contexts/AuthContext';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { TextArea } = Input;

const tierColors: Record<string, string> = { FREE: 'default', BASIC: 'blue', GOLD: 'gold', PLATINUM: 'purple' };

const promoTypeColors: Record<string, string> = {
    DISCOUNT: 'green',
    FREE_TRIAL: 'blue',
    FEATURE_UNLOCK: 'purple',
    CREDIT: 'orange',
};

const promoStatusColors: Record<string, string> = {
    DRAFT: 'default',
    ACTIVE: 'green',
    PAUSED: 'orange',
    EXPIRED: 'red',
};

const campaignTypeColors: Record<string, string> = {
    BANNER: 'blue',
    POPUP: 'purple',
    EMAIL: 'green',
    IN_APP_NOTIFICATION: 'orange',
    SIDEBAR: 'cyan',
};

const campaignStatusColors: Record<string, string> = {
    DRAFT: 'default',
    SCHEDULED: 'blue',
    ACTIVE: 'green',
    PAUSED: 'orange',
    COMPLETED: 'cyan',
    CANCELLED: 'red',
};

export default function SubscriptionPlansPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';
    const qc = useQueryClient();
    const [form] = Form.useForm();
    const [promoForm] = Form.useForm();
    const [campaignForm] = Form.useForm();
    const [editModal, setEditModal] = useState<{ open: boolean; plan?: any }>({ open: false });
    const [promoModal, setPromoModal] = useState<{ open: boolean; item?: any }>({ open: false });
    const [campaignModal, setCampaignModal] = useState<{ open: boolean; campaign?: any }>({ open: false });

    // Queries
    const { data: dashboard, isLoading: dashboardLoading } = useQuery({
        queryKey: ['admin-subscription-dashboard'],
        queryFn: adminPlans.dashboard,
    });
    const { data: stats, isLoading: statsLoading } = useQuery({
        queryKey: ['admin-plan-stats'],
        queryFn: adminPlans.stats,
    });
    const { data: plans, isLoading: plansLoading } = useQuery({
        queryKey: ['admin-plans'],
        queryFn: adminPlans.list,
    });
    const { data: promoItems, isLoading: promoLoading } = useQuery({
        queryKey: ['admin-promo-items'],
        queryFn: adminPromotionalItems.list,
    });
    const { data: campaigns, isLoading: campaignsLoading } = useQuery({
        queryKey: ['admin-campaigns'],
        queryFn: adminCampaigns.list,
    });

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

    const createPromoMut = useMutation({
        mutationFn: (data: any) => adminPromotionalItems.create(data),
        onSuccess: () => {
            message.success('Promotional item created');
            setPromoModal({ open: false });
            promoForm.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-promo-items'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Creation failed'),
    });

    const updatePromoMut = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => adminPromotionalItems.update(id, data),
        onSuccess: () => {
            message.success('Promotional item updated');
            setPromoModal({ open: false });
            qc.invalidateQueries({ queryKey: ['admin-promo-items'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    const deletePromoMut = useMutation({
        mutationFn: (id: string) => adminPromotionalItems.delete(id),
        onSuccess: () => {
            message.success('Promotional item deleted');
            qc.invalidateQueries({ queryKey: ['admin-promo-items'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Delete failed'),
    });

    const createCampaignMut = useMutation({
        mutationFn: (data: any) => adminCampaigns.create(data),
        onSuccess: () => {
            message.success('Campaign created');
            setCampaignModal({ open: false });
            campaignForm.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-campaigns'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Creation failed'),
    });

    const updateCampaignMut = useMutation({
        mutationFn: ({ id, data }: { id: string; data: any }) => adminCampaigns.update(id, data),
        onSuccess: () => {
            message.success('Campaign updated');
            setCampaignModal({ open: false });
            qc.invalidateQueries({ queryKey: ['admin-campaigns'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Update failed'),
    });

    const updateCampaignStatusMut = useMutation({
        mutationFn: ({ id, status }: { id: string; status: string }) => adminCampaigns.updateStatus(id, status),
        onSuccess: () => {
            message.success('Campaign status updated');
            qc.invalidateQueries({ queryKey: ['admin-campaigns'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Status update failed'),
    });

    const deleteCampaignMut = useMutation({
        mutationFn: (id: string) => adminCampaigns.delete(id),
        onSuccess: () => {
            message.success('Campaign deleted');
            qc.invalidateQueries({ queryKey: ['admin-campaigns'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Delete failed'),
    });

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

    // Columns for Promotional Items
    const promoColumns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Type', dataIndex: 'type', key: 'type', render: (v: string) => <Tag color={promoTypeColors[v]}>{v}</Tag> },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={promoStatusColors[v]}>{v}</Tag> },
        {
            title: 'Discount',
            key: 'discount',
            render: (_: any, r: any) => {
                if (r.discountPercentage) return `${r.discountPercentage}%`;
                if (r.discountAmount) return `$${r.discountAmount}`;
                if (r.freeTrialDays) return `${r.freeTrialDays} days trial`;
                return '—';
            },
        },
        {
            title: 'Usage',
            key: 'usage',
            render: (_: any, r: any) => `${r.currentUses}${r.maxUses ? ` / ${r.maxUses}` : ''}`,
        },
        {
            title: 'Valid Period',
            key: 'validPeriod',
            render: (_: any, r: any) => {
                if (!r.validFrom && !r.validUntil) return '—';
                const from = r.validFrom ? dayjs(r.validFrom).format('MMM D') : '—';
                const until = r.validUntil ? dayjs(r.validUntil).format('MMM D') : '—';
                return `${from} - ${until}`;
            },
        },
        {
            title: '',
            key: 'actions',
            render: (_: any, r: any) => canEdit ? (
                <Space>
                    <Button icon={<EditOutlined />} size="small" onClick={() => {
                        setPromoModal({ open: true, item: r });
                        promoForm.setFieldsValue({ ...r, validFrom: r.validFrom ? dayjs(r.validFrom) : null, validUntil: r.validUntil ? dayjs(r.validUntil) : null });
                    }}>Edit</Button>
                    <Popconfirm title="Delete this promotional item?" onConfirm={() => deletePromoMut.mutate(r.id)}>
                        <Button icon={<DeleteOutlined />} size="small" danger>Delete</Button>
                    </Popconfirm>
                </Space>
            ) : null,
        },
    ];

    // Columns for Campaigns
    const campaignColumns = [
        { title: 'Name', dataIndex: 'name', key: 'name' },
        { title: 'Type', dataIndex: 'type', key: 'type', render: (v: string) => <Tag color={campaignTypeColors[v]}>{v}</Tag> },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Badge status={campaignStatusColors[v] as any} text={v} /> },
        { title: 'Title', dataIndex: 'title', key: 'title', ellipsis: true },
        {
            title: 'Schedule',
            key: 'schedule',
            render: (_: any, r: any) => {
                if (!r.scheduledFrom && !r.scheduledUntil) return '—';
                const from = r.scheduledFrom ? dayjs(r.scheduledFrom).format('MMM D, HH:mm') : '—';
                const until = r.scheduledUntil ? dayjs(r.scheduledUntil).format('MMM D, HH:mm') : '—';
                return `${from} - ${until}`;
            },
        },
        {
            title: 'Performance',
            key: 'performance',
            render: (_: any, r: any) => (
                <Space size="small">
                    <Text type="secondary">👁 {r.impressions}</Text>
                    <Text type="secondary">👆 {r.clicks}</Text>
                    <Text type="secondary">✓ {r.conversions}</Text>
                </Space>
            ),
        },
        {
            title: '',
            key: 'actions',
            render: (_: any, r: any) => canEdit ? (
                <Space>
                    {r.status === 'DRAFT' && (
                        <Button icon={<PlayCircleOutlined />} size="small" type="primary" onClick={() => updateCampaignStatusMut.mutate({ id: r.id, status: 'ACTIVE' })}>Activate</Button>
                    )}
                    {r.status === 'ACTIVE' && (
                        <Button icon={<PauseCircleOutlined />} size="small" onClick={() => updateCampaignStatusMut.mutate({ id: r.id, status: 'PAUSED' })}>Pause</Button>
                    )}
                    {r.status === 'PAUSED' && (
                        <Button icon={<PlayCircleOutlined />} size="small" type="primary" onClick={() => updateCampaignStatusMut.mutate({ id: r.id, status: 'ACTIVE' })}>Resume</Button>
                    )}
                    <Button icon={<EditOutlined />} size="small" onClick={() => {
                        setCampaignModal({ open: true, campaign: r });
                        campaignForm.setFieldsValue({
                            ...r,
                            scheduledFrom: r.scheduledFrom ? dayjs(r.scheduledFrom) : null,
                            scheduledUntil: r.scheduledUntil ? dayjs(r.scheduledUntil) : null,
                        });
                    }}>Edit</Button>
                    <Popconfirm title="Delete this campaign?" onConfirm={() => deleteCampaignMut.mutate(r.id)}>
                        <Button icon={<DeleteOutlined />} size="small" danger>Delete</Button>
                    </Popconfirm>
                </Space>
            ) : null,
        },
    ];

    return (
        <div>
            <Title level={3}>Subscription Management</Title>
            <Typography.Paragraph type="secondary">
                Manage subscription plans, promotional items, and marketing campaigns.
            </Typography.Paragraph>

            {/* Dashboard Overview */}
            <Card title="Subscription Dashboard" loading={dashboardLoading} style={{ marginBottom: 24 }}>
                <Row gutter={16}>
                    <Col span={6}>
                        <Statistic title="Total Subscriptions" value={dashboard?.overview?.totalSubscriptions || 0} />
                    </Col>
                    <Col span={6}>
                        <Statistic title="Active Subscriptions" value={dashboard?.overview?.activeSubscriptions || 0} valueStyle={{ color: '#3f8600' }} />
                    </Col>
                    <Col span={6}>
                        <Statistic title="New (30 Days)" value={dashboard?.overview?.newSubscriptions30Days || 0} valueStyle={{ color: '#1890ff' }} />
                    </Col>
                    <Col span={6}>
                        <Statistic title="New (7 Days)" value={dashboard?.overview?.newSubscriptions7Days || 0} valueStyle={{ color: '#722ed1' }} />
                    </Col>
                </Row>
                <Divider />
                <Row gutter={16}>
                    <Col span={8}>
                        <Statistic title="Churn Rate (30d)" value={dashboard?.overview?.churnRate || 0} suffix="%" valueStyle={{ color: dashboard?.overview?.churnRate > 5 ? '#cf1322' : '#3f8600' }} />
                    </Col>
                    <Col span={8}>
                        <Statistic title="Monthly Billing" value={dashboard?.billingPeriodBreakdown?.find((b: any) => b.period === 'monthly')?.count || 0} />
                    </Col>
                    <Col span={8}>
                        <Statistic title="Yearly Billing" value={dashboard?.billingPeriodBreakdown?.find((b: any) => b.period === 'yearly')?.count || 0} />
                    </Col>
                </Row>
            </Card>

            <Tabs
                defaultActiveKey="plans"
                items={[
                    {
                        key: 'plans',
                        label: 'Subscription Plans',
                        children: (
                            <>
                                <Title level={4}>Manage Subscription Pricing & Limits</Title>
                                <Table
                                    columns={planColumns}
                                    dataSource={plans || []}
                                    rowKey="id"
                                    loading={plansLoading}
                                    pagination={false}
                                    style={{ background: '#fff', borderRadius: 12 }}
                                />
                            </>
                        ),
                    },
                    {
                        key: 'stats',
                        label: 'Statistics',
                        children: (
                            <>
                                <Title level={4}>Subscription Statistics by Tier</Title>
                                <Table
                                    columns={[
                                        { title: 'Tier', dataIndex: 'tier', key: 'tier', render: (v: string) => <Tag color={tierColors[v]}>{v}</Tag> },
                                        { title: 'Active Subscribers', dataIndex: 'subscriber_count', key: 'subscriber_count', render: (v: number) => <strong>{v}</strong> },
                                        { title: 'Avg Workers / Subscriber', dataIndex: 'avg_workers', key: 'avg_workers', render: (v: number) => Number(v).toFixed(1) },
                                        { title: 'Total MRR', dataIndex: 'total_mrr', key: 'total_mrr', render: (v: number, r: any) => `${r.currency || 'USD'} ${Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` },
                                    ]}
                                    dataSource={stats || []}
                                    rowKey="tier"
                                    loading={statsLoading}
                                    pagination={false}
                                    style={{ background: '#fff', borderRadius: 12 }}
                                />
                                <Divider />
                                <Title level={4}>MRR by Tier</Title>
                                <Row gutter={16}>
                                    {dashboard?.mrrByTier?.map((mrr: any) => (
                                        <Col span={6} key={mrr.tier}>
                                            <Card size="small">
                                                <Tag color={tierColors[mrr.tier]}>{mrr.tier}</Tag>
                                                <div style={{ fontSize: 20, fontWeight: 700, marginTop: 8 }}>
                                                    ${mrr.mrr.toLocaleString()}
                                                </div>
                                                <div style={{ fontSize: 12, color: '#94a3b8' }}>
                                                    {mrr.subscribers} subscribers
                                                </div>
                                            </Card>
                                        </Col>
                                    ))}
                                </Row>
                            </>
                        ),
                    },
                    {
                        key: 'promos',
                        label: 'Promotional Items',
                        children: (
                            <>
                                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <Title level={4} style={{ margin: 0 }}>Promotional Items</Title>
                                    {canEdit && (
                                        <Button type="primary" icon={<PlusOutlined />} onClick={() => {
                                            setPromoModal({ open: true });
                                            promoForm.resetFields();
                                        }}>Create Promo</Button>
                                    )}
                                </div>
                                <Table
                                    columns={promoColumns}
                                    dataSource={promoItems || []}
                                    rowKey="id"
                                    loading={promoLoading}
                                    pagination={{ pageSize: 10 }}
                                    style={{ background: '#fff', borderRadius: 12 }}
                                />
                            </>
                        ),
                    },
                    {
                        key: 'campaigns',
                        label: 'Campaigns',
                        children: (
                            <>
                                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <Title level={4} style={{ margin: 0 }}>Marketing Campaigns</Title>
                                    {canEdit && (
                                        <Button type="primary" icon={<PlusOutlined />} onClick={() => {
                                            setCampaignModal({ open: true });
                                            campaignForm.resetFields();
                                        }}>Create Campaign</Button>
                                    )}
                                </div>
                                <Table
                                    columns={campaignColumns}
                                    dataSource={campaigns || []}
                                    rowKey="id"
                                    loading={campaignsLoading}
                                    pagination={{ pageSize: 10 }}
                                    style={{ background: '#fff', borderRadius: 12 }}
                                />
                            </>
                        ),
                    },
                ]}
            />

            {/* Edit Plan Modal */}
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

            {/* Promotional Item Modal */}
            <Modal
                title={promoModal.item ? 'Edit Promotional Item' : 'Create Promotional Item'}
                open={promoModal.open}
                onCancel={() => setPromoModal({ open: false })}
                onOk={() => promoForm.submit()}
                confirmLoading={createPromoMut.isPending || updatePromoMut.isPending}
                width={600}
            >
                <Form form={promoForm} layout="vertical" onFinish={(v) => {
                    const data = {
                        ...v,
                        validFrom: v.validFrom ? v.validFrom.toISOString() : null,
                        validUntil: v.validUntil ? v.validUntil.toISOString() : null,
                    };
                    if (promoModal.item) {
                        updatePromoMut.mutate({ id: promoModal.item.id, data });
                    } else {
                        createPromoMut.mutate(data);
                    }
                }}>
                    <Form.Item label="Name" name="name" rules={[{ required: true }]}>
                        <Input placeholder="e.g., Summer Sale 2024" />
                    </Form.Item>
                    <Form.Item label="Description" name="description">
                        <TextArea rows={2} placeholder="Describe the promotion" />
                    </Form.Item>
                    <Form.Item label="Type" name="type" rules={[{ required: true }]}>
                        <Select>
                            <Select.Option value="DISCOUNT">Discount</Select.Option>
                            <Select.Option value="FREE_TRIAL">Free Trial</Select.Option>
                            <Select.Option value="FEATURE_UNLOCK">Feature Unlock</Select.Option>
                            <Select.Option value="CREDIT">Account Credit</Select.Option>
                        </Select>
                    </Form.Item>
                    <Form.Item label="Status" name="status" rules={[{ required: true }]}>
                        <Select>
                            <Select.Option value="DRAFT">Draft</Select.Option>
                            <Select.Option value="ACTIVE">Active</Select.Option>
                            <Select.Option value="PAUSED">Paused</Select.Option>
                            <Select.Option value="EXPIRED">Expired</Select.Option>
                        </Select>
                    </Form.Item>
                    <Form.Item noStyle shouldUpdate={(prev, curr) => prev.type !== curr.type}>
                        {({ getFieldValue }) => {
                            const type = getFieldValue('type');
                            return (
                                <>
                                    {type === 'DISCOUNT' && (
                                        <Space style={{ width: '100%' }}>
                                            <Form.Item label="Discount %" name="discountPercentage">
                                                <InputNumber min={0} max={100} style={{ width: 150 }} />
                                            </Form.Item>
                                            <Form.Item label="or Fixed Amount ($)" name="discountAmount">
                                                <InputNumber min={0} style={{ width: 150 }} />
                                            </Form.Item>
                                        </Space>
                                    )}
                                    {type === 'FREE_TRIAL' && (
                                        <Form.Item label="Trial Days" name="freeTrialDays">
                                            <InputNumber min={1} style={{ width: 150 }} />
                                        </Form.Item>
                                    )}
                                    {type === 'CREDIT' && (
                                        <Form.Item label="Credit Amount ($)" name="discountAmount">
                                            <InputNumber min={0} style={{ width: 150 }} />
                                        </Form.Item>
                                    )}
                                </>
                            );
                        }}
                    </Form.Item>
                    <Form.Item label="Max Uses (optional)" name="maxUses">
                        <InputNumber min={1} style={{ width: 150 }} />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Valid From" name="validFrom">
                            <DatePicker showTime style={{ width: 180 }} />
                        </Form.Item>
                        <Form.Item label="Valid Until" name="validUntil">
                            <DatePicker showTime style={{ width: 180 }} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Applicable Tiers" name="applicableTiers">
                        <Select mode="multiple" placeholder="Select tiers (leave empty for all)">
                            <Select.Option value="FREE">FREE</Select.Option>
                            <Select.Option value="BASIC">BASIC</Select.Option>
                            <Select.Option value="GOLD">GOLD</Select.Option>
                            <Select.Option value="PLATINUM">PLATINUM</Select.Option>
                        </Select>
                    </Form.Item>
                    <Form.Item label="Terms & Conditions" name="termsAndConditions">
                        <TextArea rows={3} placeholder="Terms and conditions for this promotion" />
                    </Form.Item>
                </Form>
            </Modal>

            {/* Campaign Modal */}
            <Modal
                title={campaignModal.campaign ? 'Edit Campaign' : 'Create Campaign'}
                open={campaignModal.open}
                onCancel={() => setCampaignModal({ open: false })}
                onOk={() => campaignForm.submit()}
                confirmLoading={createCampaignMut.isPending || updateCampaignMut.isPending}
                width={700}
            >
                <Form form={campaignForm} layout="vertical" onFinish={(v) => {
                    const data = {
                        ...v,
                        scheduledFrom: v.scheduledFrom ? v.scheduledFrom.toISOString() : null,
                        scheduledUntil: v.scheduledUntil ? v.scheduledUntil.toISOString() : null,
                    };
                    if (campaignModal.campaign) {
                        updateCampaignMut.mutate({ id: campaignModal.campaign.id, data });
                    } else {
                        createCampaignMut.mutate(data);
                    }
                }}>
                    <Form.Item label="Campaign Name" name="name" rules={[{ required: true }]}>
                        <Input placeholder="e.g., Summer 2024 Upgrade Campaign" />
                    </Form.Item>
                    <Form.Item label="Description" name="description">
                        <TextArea rows={2} placeholder="Campaign description" />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Type" name="type" rules={[{ required: true }]}>
                            <Select style={{ width: 180 }}>
                                <Select.Option value="BANNER">Banner</Select.Option>
                                <Select.Option value="POPUP">Popup</Select.Option>
                                <Select.Option value="EMAIL">Email</Select.Option>
                                <Select.Option value="IN_APP_NOTIFICATION">In-App Notification</Select.Option>
                                <Select.Option value="SIDEBAR">Sidebar</Select.Option>
                            </Select>
                        </Form.Item>
                        <Form.Item label="Status" name="status" rules={[{ required: true }]}>
                            <Select style={{ width: 150 }}>
                                <Select.Option value="DRAFT">Draft</Select.Option>
                                <Select.Option value="SCHEDULED">Scheduled</Select.Option>
                                <Select.Option value="ACTIVE">Active</Select.Option>
                                <Select.Option value="PAUSED">Paused</Select.Option>
                                <Select.Option value="COMPLETED">Completed</Select.Option>
                            </Select>
                        </Form.Item>
                    </Space>
                    <Form.Item label="Title" name="title" rules={[{ required: true }]}>
                        <Input placeholder="Campaign headline" />
                    </Form.Item>
                    <Form.Item label="Message" name="message" rules={[{ required: true }]}>
                        <TextArea rows={3} placeholder="Campaign message content" />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Call to Action" name="callToAction">
                            <Input placeholder="e.g., Upgrade Now" />
                        </Form.Item>
                        <Form.Item label="CTA URL" name="callToActionUrl">
                            <Input placeholder="https://..." />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Image URL" name="imageUrl">
                        <Input placeholder="https://..." />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Scheduled From" name="scheduledFrom">
                            <DatePicker showTime style={{ width: 200 }} />
                        </Form.Item>
                        <Form.Item label="Scheduled Until" name="scheduledUntil">
                            <DatePicker showTime style={{ width: 200 }} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Priority" name="priority">
                        <InputNumber min={1} max={100} style={{ width: 150 }} />
                    </Form.Item>
                    <Form.Item label="Target Tiers" name={['targetAudience', 'tiers']}>
                        <Select mode="multiple" placeholder="Select target tiers">
                            <Select.Option value="FREE">FREE</Select.Option>
                            <Select.Option value="BASIC">BASIC</Select.Option>
                            <Select.Option value="GOLD">GOLD</Select.Option>
                            <Select.Option value="PLATINUM">PLATINUM</Select.Option>
                        </Select>
                    </Form.Item>
                    <Form.Item label="Linked Promotional Item" name="promotionalItemId">
                        <Select allowClear placeholder="Select a promotional item (optional)">
                            {promoItems?.map((item: any) => (
                                <Select.Option key={item.id} value={item.id}>{item.name}</Select.Option>
                            ))}
                        </Select>
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
