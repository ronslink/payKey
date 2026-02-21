import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Card, Typography, Tag, Button, Modal, Form, Input, InputNumber, Switch, Space, message, Divider, Tabs, Row, Col, Select, DatePicker, Badge, Popconfirm, Progress, Tooltip, Statistic } from 'antd';
import { EditOutlined, PlusOutlined, DeleteOutlined, PlayCircleOutlined, PauseCircleOutlined, RiseOutlined, TeamOutlined, CrownOutlined, TrophyOutlined, StarOutlined, PercentageOutlined, GiftOutlined, NotificationOutlined, EyeOutlined, BarChartOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminPlans, adminPromotionalItems, adminCampaigns } from '../api/client';
import { useAuth } from '../contexts/AuthContext';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { TextArea } = Input;

const tierColors: Record<string, string> = { FREE: 'default', BASIC: 'blue', GOLD: 'gold', PLATINUM: 'purple' };
const tierBg: Record<string, string> = { FREE: '#f8fafc', BASIC: '#eff6ff', GOLD: '#fffbeb', PLATINUM: '#faf5ff' };
const tierFg: Record<string, string> = { FREE: '#64748b', BASIC: '#2563eb', GOLD: '#d97706', PLATINUM: '#7c3aed' };
const tierIcon: Record<string, React.ReactNode> = {
    FREE: <TeamOutlined />,
    BASIC: <StarOutlined />,
    GOLD: <TrophyOutlined />,
    PLATINUM: <CrownOutlined />,
};

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

    const overview = dashboard?.overview || {};
    const totalSubs = overview.totalSubscriptions || 0;
    const activeSubs = overview.activeSubscriptions || 0;
    const churnRate = overview.churnRate || 0;
    const activePercent = totalSubs > 0 ? Math.round((activeSubs / totalSubs) * 100) : 0;

    // Columns for Plans tab
    const planColumns = [
        {
            title: 'Tier',
            dataIndex: 'tier',
            key: 'tier',
            width: 100,
            render: (v: string) => (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ color: tierFg[v], fontSize: 16 }}>{tierIcon[v]}</span>
                    <Tag color={tierColors[v]} style={{ borderRadius: 12 }}>{v}</Tag>
                </div>
            ),
        },
        {
            title: 'Plan Name',
            dataIndex: 'name',
            key: 'name',
            render: (v: string, r: any) => (
                <div>
                    <span style={{ fontWeight: 600 }}>{v}</span>
                    {r.isPopular && <Tag color="orange" style={{ marginLeft: 8, borderRadius: 12 }}>⭐ Popular</Tag>}
                </div>
            ),
        },
        {
            title: 'Monthly Price',
            key: 'monthly',
            render: (_: any, r: any) => (
                <div>
                    <div style={{ fontWeight: 600 }}>
                        <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>USD</span>
                        ${Number(r.priceUSD).toFixed(2)}
                    </div>
                    <div style={{ fontSize: 12, color: '#64748b' }}>
                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 3 }}>KES</span>
                        {Number(r.priceKES).toLocaleString()}
                    </div>
                </div>
            ),
        },
        {
            title: 'Yearly Price',
            key: 'yearly',
            render: (_: any, r: any) => (
                <div>
                    <div style={{ fontWeight: 600 }}>
                        <span style={{ fontSize: 11, color: '#94a3b8', marginRight: 3 }}>USD</span>
                        ${Number(r.priceUSDYearly).toFixed(2)}
                    </div>
                    <div style={{ fontSize: 12, color: '#64748b' }}>
                        <span style={{ fontSize: 10, color: '#94a3b8', marginRight: 3 }}>KES</span>
                        {Number(r.priceKESYearly).toLocaleString()}
                    </div>
                </div>
            ),
        },
        {
            title: 'Worker Limit',
            dataIndex: 'workerLimit',
            key: 'limit',
            align: 'center' as const,
            width: 110,
            render: (v: number) => (
                <Tag icon={<TeamOutlined />} color="blue" style={{ borderRadius: 12 }}>{v} workers</Tag>
            ),
        },
        {
            title: '',
            key: 'edit',
            width: 80,
            render: (_: any, r: any) => canEdit ? (
                <Button
                    icon={<EditOutlined />}
                    size="small"
                    type="primary"
                    ghost
                    onClick={() => {
                        setEditModal({ open: true, plan: r });
                        form.setFieldsValue(r);
                    }}
                >
                    Edit
                </Button>
            ) : null,
        },
    ];

    // Columns for Promotional Items
    const promoColumns = [
        {
            title: 'Promotion',
            key: 'name',
            render: (_: any, r: any) => (
                <div>
                    <div style={{ fontWeight: 600 }}>{r.name}</div>
                    {r.description && <div style={{ fontSize: 12, color: '#94a3b8' }}>{r.description}</div>}
                </div>
            ),
        },
        { title: 'Type', dataIndex: 'type', key: 'type', width: 130, render: (v: string) => <Tag color={promoTypeColors[v]} style={{ borderRadius: 12 }}>{v.replace('_', ' ')}</Tag> },
        { title: 'Status', dataIndex: 'status', key: 'status', width: 90, render: (v: string) => <Tag color={promoStatusColors[v]} style={{ borderRadius: 12 }}>{v}</Tag> },
        {
            title: 'Value',
            key: 'discount',
            width: 120,
            render: (_: any, r: any) => {
                if (r.discountPercentage) return <span style={{ fontWeight: 600, color: '#10b981' }}>{r.discountPercentage}% off</span>;
                if (r.discountAmount) return <span style={{ fontWeight: 600, color: '#10b981' }}>${r.discountAmount} off</span>;
                if (r.freeTrialDays) return <span style={{ fontWeight: 600, color: '#2563eb' }}>{r.freeTrialDays}d trial</span>;
                return <span style={{ color: '#94a3b8' }}>—</span>;
            },
        },
        {
            title: 'Usage',
            key: 'usage',
            width: 140,
            render: (_: any, r: any) => {
                if (!r.maxUses) return <span style={{ color: '#64748b' }}>{r.currentUses} used (unlimited)</span>;
                const pct = Math.round((r.currentUses / r.maxUses) * 100);
                return (
                    <Tooltip title={`${r.currentUses} of ${r.maxUses} uses`}>
                        <div>
                            <div style={{ fontSize: 12, marginBottom: 2 }}>{r.currentUses} / {r.maxUses}</div>
                            <Progress
                                percent={pct}
                                size="small"
                                showInfo={false}
                                strokeColor={pct >= 90 ? '#ef4444' : pct >= 70 ? '#f59e0b' : '#10b981'}
                                style={{ marginBottom: 0 }}
                            />
                        </div>
                    </Tooltip>
                );
            },
        },
        {
            title: 'Valid Period',
            key: 'validPeriod',
            width: 160,
            render: (_: any, r: any) => {
                if (!r.validFrom && !r.validUntil) return <span style={{ color: '#94a3b8' }}>—</span>;
                const from = r.validFrom ? dayjs(r.validFrom).format('MMM D') : '—';
                const until = r.validUntil ? dayjs(r.validUntil).format('MMM D, YYYY') : '—';
                return <span style={{ fontSize: 13 }}>{from} → {until}</span>;
            },
        },
        {
            title: '',
            key: 'actions',
            width: 140,
            render: (_: any, r: any) => canEdit ? (
                <Space>
                    <Button icon={<EditOutlined />} size="small" onClick={() => {
                        setPromoModal({ open: true, item: r });
                        promoForm.setFieldsValue({ ...r, validFrom: r.validFrom ? dayjs(r.validFrom) : null, validUntil: r.validUntil ? dayjs(r.validUntil) : null });
                    }} />
                    <Popconfirm title="Delete this promotional item?" onConfirm={() => deletePromoMut.mutate(r.id)}>
                        <Button icon={<DeleteOutlined />} size="small" danger />
                    </Popconfirm>
                </Space>
            ) : null,
        },
    ];

    // Columns for Campaigns
    const campaignColumns = [
        {
            title: 'Campaign',
            key: 'name',
            render: (_: any, r: any) => (
                <div>
                    <div style={{ fontWeight: 600 }}>{r.name}</div>
                    {r.title && <div style={{ fontSize: 12, color: '#64748b' }}>{r.title}</div>}
                </div>
            ),
        },
        { title: 'Type', dataIndex: 'type', key: 'type', width: 150, render: (v: string) => <Tag color={campaignTypeColors[v]} style={{ borderRadius: 12 }}>{v.replace(/_/g, ' ')}</Tag> },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            width: 110,
            render: (v: string) => (
                <Badge
                    status={v === 'ACTIVE' ? 'success' : v === 'SCHEDULED' ? 'processing' : v === 'PAUSED' ? 'warning' : v === 'CANCELLED' ? 'error' : v === 'COMPLETED' ? 'default' : 'default'}
                    text={<Tag color={campaignStatusColors[v]} style={{ borderRadius: 12 }}>{v}</Tag>}
                />
            ),
        },
        {
            title: 'Schedule',
            key: 'schedule',
            width: 180,
            render: (_: any, r: any) => {
                if (!r.scheduledFrom && !r.scheduledUntil) return <span style={{ color: '#94a3b8' }}>—</span>;
                const from = r.scheduledFrom ? dayjs(r.scheduledFrom).format('MMM D') : '—';
                const until = r.scheduledUntil ? dayjs(r.scheduledUntil).format('MMM D, YYYY') : '—';
                return <span style={{ fontSize: 13 }}>{from} → {until}</span>;
            },
        },
        {
            title: 'Performance',
            key: 'performance',
            render: (_: any, r: any) => {
                const ctr = r.impressions > 0 ? ((r.clicks / r.impressions) * 100).toFixed(1) : '0';
                const cvr = r.clicks > 0 ? ((r.conversions / r.clicks) * 100).toFixed(1) : '0';
                return (
                    <div style={{ fontSize: 12 }}>
                        <Space size={12}>
                            <Tooltip title="Impressions">
                                <span><EyeOutlined style={{ color: '#94a3b8', marginRight: 3 }} />{r.impressions}</span>
                            </Tooltip>
                            <Tooltip title={`Click-through rate: ${ctr}%`}>
                                <span style={{ color: '#6366f1' }}><BarChartOutlined style={{ marginRight: 3 }} />{r.clicks} <span style={{ color: '#94a3b8' }}>({ctr}%)</span></span>
                            </Tooltip>
                            <Tooltip title={`Conversion rate: ${cvr}%`}>
                                <span style={{ color: '#10b981' }}>✓ {r.conversions} <span style={{ color: '#94a3b8' }}>({cvr}%)</span></span>
                            </Tooltip>
                        </Space>
                    </div>
                );
            },
        },
        {
            title: '',
            key: 'actions',
            width: 160,
            render: (_: any, r: any) => canEdit ? (
                <Space size={4}>
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
                    }} />
                    <Popconfirm title="Delete this campaign?" onConfirm={() => deleteCampaignMut.mutate(r.id)}>
                        <Button icon={<DeleteOutlined />} size="small" danger />
                    </Popconfirm>
                </Space>
            ) : null,
        },
    ];

    return (
        <div>
            {/* Page header */}
            <div style={{ marginBottom: 20 }}>
                <Title level={3} style={{ margin: 0 }}>Subscription Management</Title>
                <span style={{ color: '#64748b', fontSize: 14 }}>Manage subscription plans, promotional items, and marketing campaigns</span>
            </div>

            {/* Dashboard KPI Row */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                {/* Total Subscriptions */}
                <Col xs={24} sm={12} md={6}>
                    <Card
                        size="small"
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8', height: '100%' }}
                        bodyStyle={{ padding: '18px 20px' }}
                    >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                            <div>
                                <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6 }}>Total Subscriptions</div>
                                <div style={{ fontSize: 30, fontWeight: 700, lineHeight: 1 }}>{totalSubs}</div>
                            </div>
                            <div style={{ width: 42, height: 42, borderRadius: 11, background: '#eef2ff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, color: '#6366f1' }}>
                                <TeamOutlined />
                            </div>
                        </div>
                    </Card>
                </Col>

                {/* Active Subscriptions with progress */}
                <Col xs={24} sm={12} md={6}>
                    <Card
                        size="small"
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8', height: '100%' }}
                        bodyStyle={{ padding: '18px 20px' }}
                    >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                            <div>
                                <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6 }}>Active Subscriptions</div>
                                <div style={{ fontSize: 30, fontWeight: 700, color: '#10b981', lineHeight: 1 }}>{activeSubs}</div>
                            </div>
                            <div style={{ width: 42, height: 42, borderRadius: 11, background: '#ecfdf5', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, color: '#10b981' }}>
                                <RiseOutlined />
                            </div>
                        </div>
                        <Progress percent={activePercent} size="small" strokeColor="#10b981" showInfo={false} style={{ marginBottom: 0 }} />
                        <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 3 }}>{activePercent}% of total</div>
                    </Card>
                </Col>

                {/* New this month */}
                <Col xs={24} sm={12} md={6}>
                    <Card
                        size="small"
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8', height: '100%' }}
                        bodyStyle={{ padding: '18px 20px' }}
                    >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                            <div>
                                <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6 }}>New (30 Days)</div>
                                <div style={{ fontSize: 30, fontWeight: 700, color: '#2563eb', lineHeight: 1 }}>{overview.newSubscriptions30Days || 0}</div>
                                <div style={{ fontSize: 12, color: '#94a3b8', marginTop: 4 }}>
                                    <span style={{ color: '#7c3aed' }}>{overview.newSubscriptions7Days || 0}</span> this week
                                </div>
                            </div>
                            <div style={{ width: 42, height: 42, borderRadius: 11, background: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, color: '#2563eb' }}>
                                <PlusOutlined />
                            </div>
                        </div>
                    </Card>
                </Col>

                {/* Churn Rate */}
                <Col xs={24} sm={12} md={6}>
                    <Card
                        size="small"
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8', height: '100%' }}
                        bodyStyle={{ padding: '18px 20px' }}
                    >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                            <div>
                                <div style={{ fontSize: 12, color: '#64748b', marginBottom: 6 }}>Churn Rate (30d)</div>
                                <div style={{ fontSize: 30, fontWeight: 700, lineHeight: 1, color: churnRate > 5 ? '#ef4444' : '#10b981' }}>
                                    {Number(churnRate).toFixed(1)}%
                                </div>
                            </div>
                            <div style={{ width: 42, height: 42, borderRadius: 11, background: churnRate > 5 ? '#fef2f2' : '#ecfdf5', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, color: churnRate > 5 ? '#ef4444' : '#10b981' }}>
                                <PercentageOutlined />
                            </div>
                        </div>
                        <div style={{ fontSize: 11, color: '#94a3b8' }}>
                            {churnRate > 5
                                ? '⚠️ Above healthy threshold (5%)'
                                : '✓ Within healthy range'}
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Billing breakdown */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                {/* Billing Period */}
                <Col xs={24} md={12}>
                    <Card
                        size="small"
                        title={<span style={{ fontWeight: 600 }}>Billing Period Split</span>}
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8' }}
                        bodyStyle={{ padding: '14px 20px' }}
                    >
                        <Row gutter={16}>
                            {[
                                { label: 'Monthly', key: 'monthly', color: '#6366f1', bg: '#eef2ff' },
                                { label: 'Yearly', key: 'yearly', color: '#10b981', bg: '#ecfdf5' },
                            ].map(({ label, key, color, bg }) => {
                                const count = dashboard?.billingPeriodBreakdown?.find((b: any) => b.period === key)?.count || 0;
                                const total = (dashboard?.billingPeriodBreakdown || []).reduce((s: number, b: any) => s + Number(b.count), 0);
                                const pct = total > 0 ? Math.round((count / total) * 100) : 0;
                                return (
                                    <Col span={12} key={key}>
                                        <div style={{ background: bg, borderRadius: 10, padding: '12px 14px', textAlign: 'center' }}>
                                            <div style={{ fontSize: 22, fontWeight: 700, color }}>{count}</div>
                                            <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>{label} billing</div>
                                            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 4 }}>{pct}% of subscribers</div>
                                        </div>
                                    </Col>
                                );
                            })}
                        </Row>
                    </Card>
                </Col>

                {/* MRR by Tier */}
                <Col xs={24} md={12}>
                    <Card
                        size="small"
                        title={<span style={{ fontWeight: 600 }}>MRR by Tier</span>}
                        loading={dashboardLoading}
                        style={{ borderRadius: 12, border: '1px solid #e8e8e8' }}
                        bodyStyle={{ padding: '14px 20px' }}
                    >
                        {(dashboard?.mrrByTier || []).length === 0 ? (
                            <div style={{ color: '#94a3b8', textAlign: 'center', padding: '12px 0' }}>No MRR data yet</div>
                        ) : (
                            (dashboard?.mrrByTier || []).map((mrr: any) => (
                                <div key={mrr.tier} style={{ display: 'flex', alignItems: 'center', marginBottom: 8, gap: 8 }}>
                                    <span style={{ color: tierFg[mrr.tier], fontSize: 16, width: 20 }}>{tierIcon[mrr.tier]}</span>
                                    <Tag color={tierColors[mrr.tier]} style={{ borderRadius: 10, minWidth: 72, textAlign: 'center' }}>{mrr.tier}</Tag>
                                    <div style={{ flex: 1 }}>
                                        <Progress
                                            percent={dashboard.mrrByTier.reduce((max: number, t: any) => Math.max(max, t.mrr), 0) > 0
                                                ? Math.round((mrr.mrr / Math.max(...dashboard.mrrByTier.map((t: any) => t.mrr))) * 100)
                                                : 0}
                                            size="small"
                                            showInfo={false}
                                            strokeColor={tierFg[mrr.tier]}
                                            style={{ marginBottom: 0 }}
                                        />
                                    </div>
                                    <div style={{ textAlign: 'right', minWidth: 100 }}>
                                        <span style={{ fontWeight: 700 }}>${Number(mrr.mrr).toLocaleString()}</span>
                                        <span style={{ fontSize: 11, color: '#94a3b8', marginLeft: 4 }}>{mrr.subscribers} subs</span>
                                    </div>
                                </div>
                            ))
                        )}
                    </Card>
                </Col>
            </Row>

            {/* Tabs */}
            <Tabs
                defaultActiveKey="plans"
                size="large"
                items={[
                    {
                        key: 'plans',
                        label: (
                            <span>
                                <CrownOutlined style={{ marginRight: 6 }} />
                                Subscription Plans
                            </span>
                        ),
                        children: (
                            <div>
                                <div style={{ marginBottom: 16 }}>
                                    <div style={{ fontWeight: 600, fontSize: 15, color: '#1e293b' }}>Subscription Plans</div>
                                    <div style={{ fontSize: 13, color: '#64748b' }}>Configure pricing and limits for each subscription tier</div>
                                </div>
                                <Table
                                    columns={planColumns}
                                    dataSource={plans || []}
                                    rowKey="id"
                                    loading={plansLoading}
                                    pagination={false}
                                    style={{ background: '#fff', borderRadius: 12 }}
                                />
                            </div>
                        ),
                    },
                    {
                        key: 'stats',
                        label: (
                            <span>
                                <BarChartOutlined style={{ marginRight: 6 }} />
                                Statistics
                            </span>
                        ),
                        children: (
                            <div>
                                <div style={{ marginBottom: 16 }}>
                                    <div style={{ fontWeight: 600, fontSize: 15, color: '#1e293b' }}>Subscription Statistics by Tier</div>
                                    <div style={{ fontSize: 13, color: '#64748b' }}>Active subscribers, usage patterns, and revenue by plan tier</div>
                                </div>

                                {/* Tier stat cards */}
                                <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                                    {(stats || []).map((s: any) => (
                                        <Col xs={24} sm={12} md={6} key={s.tier}>
                                            <Card
                                                size="small"
                                                loading={statsLoading}
                                                style={{ borderRadius: 12, border: `1px solid ${tierFg[s.tier]}30`, background: tierBg[s.tier] }}
                                                bodyStyle={{ padding: '16px 18px' }}
                                            >
                                                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                                                    <span style={{ fontSize: 18, color: tierFg[s.tier] }}>{tierIcon[s.tier]}</span>
                                                    <Tag color={tierColors[s.tier]} style={{ borderRadius: 10 }}>{s.tier}</Tag>
                                                </div>
                                                <div style={{ fontSize: 26, fontWeight: 700, color: tierFg[s.tier], marginBottom: 4 }}>
                                                    {s.subscriber_count}
                                                    <span style={{ fontSize: 13, fontWeight: 400, color: '#94a3b8', marginLeft: 4 }}>subscribers</span>
                                                </div>
                                                <div style={{ fontSize: 13, color: '#64748b' }}>
                                                    Avg {Number(s.avg_workers).toFixed(1)} workers/employer
                                                </div>
                                                <Divider style={{ margin: '10px 0' }} />
                                                <div style={{ fontSize: 12, color: '#64748b' }}>
                                                    MRR:{' '}
                                                    <span style={{ fontWeight: 700, color: tierFg[s.tier] }}>
                                                        {s.currency || 'USD'} {Number(s.total_mrr).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
                                                    </span>
                                                </div>
                                            </Card>
                                        </Col>
                                    ))}
                                    {(stats || []).length === 0 && !statsLoading && (
                                        <Col span={24}>
                                            <div style={{ textAlign: 'center', color: '#94a3b8', padding: 40 }}>No statistics available yet</div>
                                        </Col>
                                    )}
                                </Row>
                            </div>
                        ),
                    },
                    {
                        key: 'promos',
                        label: (
                            <span>
                                <GiftOutlined style={{ marginRight: 6 }} />
                                Promotions
                                {(promoItems || []).filter((p: any) => p.status === 'ACTIVE').length > 0 && (
                                    <Badge count={(promoItems || []).filter((p: any) => p.status === 'ACTIVE').length} style={{ marginLeft: 8 }} />
                                )}
                            </span>
                        ),
                        children: (
                            <div>
                                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <div style={{ fontWeight: 600, fontSize: 15, color: '#1e293b' }}>Promotional Items</div>
                                        <div style={{ fontSize: 13, color: '#64748b' }}>Create discounts, free trials, and feature unlocks</div>
                                    </div>
                                    {canEdit && (
                                        <Button type="primary" icon={<PlusOutlined />} onClick={() => {
                                            setPromoModal({ open: true });
                                            promoForm.resetFields();
                                        }}>
                                            Create Promo
                                        </Button>
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
                            </div>
                        ),
                    },
                    {
                        key: 'campaigns',
                        label: (
                            <span>
                                <NotificationOutlined style={{ marginRight: 6 }} />
                                Campaigns
                                {(campaigns || []).filter((c: any) => c.status === 'ACTIVE').length > 0 && (
                                    <Badge count={(campaigns || []).filter((c: any) => c.status === 'ACTIVE').length} color="green" style={{ marginLeft: 8 }} />
                                )}
                            </span>
                        ),
                        children: (
                            <div>
                                <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <div>
                                        <div style={{ fontWeight: 600, fontSize: 15, color: '#1e293b' }}>Marketing Campaigns</div>
                                        <div style={{ fontSize: 13, color: '#64748b' }}>Banners, popups, email, and in-app notification campaigns</div>
                                    </div>
                                    {canEdit && (
                                        <Button type="primary" icon={<PlusOutlined />} onClick={() => {
                                            setCampaignModal({ open: true });
                                            campaignForm.resetFields();
                                        }}>
                                            Create Campaign
                                        </Button>
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
                            </div>
                        ),
                    },
                ]}
            />

            {/* Edit Plan Modal */}
            <Modal
                title={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ color: tierFg[editModal.plan?.tier] }}>{tierIcon[editModal.plan?.tier]}</span>
                        <span>Edit {editModal.plan?.name}</span>
                        <Tag color={tierColors[editModal.plan?.tier]} style={{ borderRadius: 10 }}>{editModal.plan?.tier}</Tag>
                    </div>
                }
                open={editModal.open}
                onCancel={() => setEditModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={updateMut.isPending}
                width={520}
            >
                <Form form={form} layout="vertical" onFinish={(v) => updateMut.mutate({ id: editModal.plan?.id, data: v })}>
                    <Form.Item label="Plan Name" name="name" rules={[{ required: true }]}>
                        <Input />
                    </Form.Item>
                    <Divider orientation="left" style={{ fontSize: 13, color: '#64748b' }}>Monthly Pricing</Divider>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Monthly (USD)" name="priceUSD">
                                <InputNumber min={0} prefix="$" style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Monthly (KES)" name="priceKES">
                                <InputNumber min={0} style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Divider orientation="left" style={{ fontSize: 13, color: '#64748b' }}>Yearly Pricing</Divider>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Yearly (USD)" name="priceUSDYearly">
                                <InputNumber min={0} prefix="$" style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Yearly (KES)" name="priceKESYearly">
                                <InputNumber min={0} style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Divider style={{ margin: '4px 0 16px' }} />
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Worker Limit" name="workerLimit">
                                <InputNumber min={1} style={{ width: '100%' }} addonAfter="workers" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Mark as Popular" name="isPopular" valuePropName="checked">
                                <Switch checkedChildren="⭐ Popular" unCheckedChildren="Normal" />
                            </Form.Item>
                        </Col>
                    </Row>
                </Form>
            </Modal>

            {/* Promotional Item Modal */}
            <Modal
                title={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <GiftOutlined style={{ color: '#10b981' }} />
                        <span>{promoModal.item ? 'Edit Promotional Item' : 'Create Promotional Item'}</span>
                    </div>
                }
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
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Type" name="type" rules={[{ required: true }]}>
                                <Select>
                                    <Select.Option value="DISCOUNT">Discount</Select.Option>
                                    <Select.Option value="FREE_TRIAL">Free Trial</Select.Option>
                                    <Select.Option value="FEATURE_UNLOCK">Feature Unlock</Select.Option>
                                    <Select.Option value="CREDIT">Account Credit</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Status" name="status" rules={[{ required: true }]}>
                                <Select>
                                    <Select.Option value="DRAFT">Draft</Select.Option>
                                    <Select.Option value="ACTIVE">Active</Select.Option>
                                    <Select.Option value="PAUSED">Paused</Select.Option>
                                    <Select.Option value="EXPIRED">Expired</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>
                    <Form.Item noStyle shouldUpdate={(prev, curr) => prev.type !== curr.type}>
                        {({ getFieldValue }) => {
                            const type = getFieldValue('type');
                            return (
                                <>
                                    {type === 'DISCOUNT' && (
                                        <Row gutter={12}>
                                            <Col span={12}>
                                                <Form.Item label="Discount %" name="discountPercentage">
                                                    <InputNumber min={0} max={100} style={{ width: '100%' }} addonAfter="%" />
                                                </Form.Item>
                                            </Col>
                                            <Col span={12}>
                                                <Form.Item label="or Fixed Amount ($)" name="discountAmount">
                                                    <InputNumber min={0} style={{ width: '100%' }} prefix="$" />
                                                </Form.Item>
                                            </Col>
                                        </Row>
                                    )}
                                    {type === 'FREE_TRIAL' && (
                                        <Form.Item label="Trial Days" name="freeTrialDays">
                                            <InputNumber min={1} style={{ width: 150 }} addonAfter="days" />
                                        </Form.Item>
                                    )}
                                    {type === 'CREDIT' && (
                                        <Form.Item label="Credit Amount ($)" name="discountAmount">
                                            <InputNumber min={0} style={{ width: 150 }} prefix="$" />
                                        </Form.Item>
                                    )}
                                </>
                            );
                        }}
                    </Form.Item>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Max Uses" name="maxUses">
                                <InputNumber min={1} style={{ width: '100%' }} placeholder="Unlimited if empty" />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Valid From" name="validFrom">
                                <DatePicker showTime style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Valid Until" name="validUntil">
                                <DatePicker showTime style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Form.Item label="Applicable Tiers" name="applicableTiers">
                        <Select mode="multiple" placeholder="Leave empty for all tiers">
                            {['FREE', 'BASIC', 'GOLD', 'PLATINUM'].map(t => (
                                <Select.Option key={t} value={t}>
                                    <Tag color={tierColors[t]} style={{ margin: 0 }}>{t}</Tag>
                                </Select.Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item label="Terms & Conditions" name="termsAndConditions">
                        <TextArea rows={3} placeholder="Terms and conditions for this promotion" />
                    </Form.Item>
                </Form>
            </Modal>

            {/* Campaign Modal */}
            <Modal
                title={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <NotificationOutlined style={{ color: '#6366f1' }} />
                        <span>{campaignModal.campaign ? 'Edit Campaign' : 'Create Campaign'}</span>
                    </div>
                }
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
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Type" name="type" rules={[{ required: true }]}>
                                <Select>
                                    <Select.Option value="BANNER">Banner</Select.Option>
                                    <Select.Option value="POPUP">Popup</Select.Option>
                                    <Select.Option value="EMAIL">Email</Select.Option>
                                    <Select.Option value="IN_APP_NOTIFICATION">In-App Notification</Select.Option>
                                    <Select.Option value="SIDEBAR">Sidebar</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Status" name="status" rules={[{ required: true }]}>
                                <Select>
                                    <Select.Option value="DRAFT">Draft</Select.Option>
                                    <Select.Option value="SCHEDULED">Scheduled</Select.Option>
                                    <Select.Option value="ACTIVE">Active</Select.Option>
                                    <Select.Option value="PAUSED">Paused</Select.Option>
                                    <Select.Option value="COMPLETED">Completed</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>
                    <Form.Item label="Title" name="title" rules={[{ required: true }]}>
                        <Input placeholder="Campaign headline" />
                    </Form.Item>
                    <Form.Item label="Message" name="message" rules={[{ required: true }]}>
                        <TextArea rows={3} placeholder="Campaign message content" />
                    </Form.Item>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Call to Action" name="callToAction">
                                <Input placeholder="e.g., Upgrade Now" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="CTA URL" name="callToActionUrl">
                                <Input placeholder="https://..." />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Form.Item label="Image URL" name="imageUrl">
                        <Input placeholder="https://..." />
                    </Form.Item>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Scheduled From" name="scheduledFrom">
                                <DatePicker showTime style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Scheduled Until" name="scheduledUntil">
                                <DatePicker showTime style={{ width: '100%' }} />
                            </Form.Item>
                        </Col>
                    </Row>
                    <Row gutter={12}>
                        <Col span={12}>
                            <Form.Item label="Priority" name="priority">
                                <InputNumber min={1} max={100} style={{ width: '100%' }} placeholder="1–100" />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item label="Target Tiers" name={['targetAudience', 'tiers']}>
                                <Select mode="multiple" placeholder="All tiers">
                                    {['FREE', 'BASIC', 'GOLD', 'PLATINUM'].map(t => (
                                        <Select.Option key={t} value={t}>
                                            <Tag color={tierColors[t]} style={{ margin: 0 }}>{t}</Tag>
                                        </Select.Option>
                                    ))}
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>
                    <Form.Item label="Linked Promotional Item" name="promotionalItemId">
                        <Select allowClear placeholder="Select a promotional item (optional)">
                            {promoItems?.map((item: any) => (
                                <Select.Option key={item.id} value={item.id}>
                                    <Space>
                                        <Tag color={promoTypeColors[item.type]} style={{ borderRadius: 10 }}>{item.type}</Tag>
                                        {item.name}
                                    </Space>
                                </Select.Option>
                            ))}
                        </Select>
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
