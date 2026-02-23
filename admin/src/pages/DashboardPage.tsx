import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
    Row, Col, Card, Statistic, Typography, Spin, Alert, Table, Tag, Button, Tooltip, Select,
    Badge, Avatar, Space
} from 'antd';
import {
    TeamOutlined, UserOutlined, DollarOutlined, CustomerServiceOutlined, ReloadOutlined,
    UserAddOutlined, ArrowUpOutlined, ArrowDownOutlined,
    WalletOutlined, CreditCardOutlined, CalendarOutlined, ShopOutlined,
    ExclamationCircleOutlined,
    BarChartOutlined, PieChartOutlined, LineChartOutlined
} from '@ant-design/icons';
import {
    BarChart, Bar, PieChart, Pie, Cell, Area, AreaChart,
    XAxis, YAxis, CartesianGrid, Tooltip as RechartTooltip, Legend, ResponsiveContainer,
} from 'recharts';
import { adminAnalytics, adminPlans, adminSupport } from '../api/client';

const { Title, Text } = Typography;

const PIE_COLORS = ['#6366f1', '#8b5cf6', '#06b6d4', '#10b981', '#f59e0b', '#ef4444'];

const tierColor: Record<string, string> = {
    FREE: '#6b7280', BASIC: '#3b82f6', GOLD: '#f59e0b', PLATINUM: '#8b5cf6', ENTERPRISE: '#ec4899'
};

const tierGradient: Record<string, [string, string]> = {
    FREE: ['#f3f4f6', '#e5e7eb'],
    BASIC: ['#dbeafe', '#bfdbfe'],
    GOLD: ['#fef3c7', '#fde68a'],
    PLATINUM: ['#ede9fe', '#ddd6fe'],
    ENTERPRISE: ['#fce7f3', '#fbcfe8'],
};

// Enhanced Stat Card with trend
function StatCard({ title, value, prefix, suffix, color, trend, trendValue, icon, onClick }: any) {
    const isPositive = trend === 'up';
    return (
        <Card
            style={{
                borderRadius: 16,
                border: 'none',
                background: `linear-gradient(135deg, ${color}08 0%, ${color}15 100%)`,
                boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06)',
                cursor: onClick ? 'pointer' : 'default',
                transition: 'transform 0.2s, box-shadow 0.2s',
            }}
            onClick={onClick}
            hoverable={!!onClick}
            bodyStyle={{ padding: 24 }}
        >
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div style={{ flex: 1 }}>
                    <Text style={{ fontSize: 13, color: '#6b7280', fontWeight: 500, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                        {title}
                    </Text>
                    <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 8 }}>
                        <Text style={{ fontSize: 32, fontWeight: 700, color: '#1f2937' }}>
                            {prefix}{value}{suffix}
                        </Text>
                    </div>
                    {trend && (
                        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 4 }}>
                            <Tag
                                color={isPositive ? 'success' : 'error'}
                                style={{ fontSize: 11, fontWeight: 600, borderRadius: 4 }}
                            >
                                {isPositive ? <ArrowUpOutlined /> : <ArrowDownOutlined />}
                                {trendValue}%
                            </Tag>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>vs last month</Text>
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
                    boxShadow: `0 4px 12px ${color}40`,
                }}>
                    {icon}
                </div>
            </div>
        </Card>
    );
}

export default function DashboardPage() {
    const [currency, setCurrency] = useState('USD');
    const { data, isLoading, error, refetch, dataUpdatedAt } = useQuery({
        queryKey: ['admin-dashboard', currency],
        queryFn: () => adminAnalytics.dashboard(currency),
        refetchInterval: 60000,
    });
    const { data: tierStats, isLoading: tierStatsLoading } = useQuery({
        queryKey: ['admin-tier-stats'],
        queryFn: adminPlans.stats,
        refetchInterval: 60000,
    });
    const { data: supportData } = useQuery({
        queryKey: ['admin-support-summary'],
        queryFn: () => adminSupport.list({ status: 'OPEN', page: 1 }),
        refetchInterval: 30000,
    });

    if (isLoading) return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
            <Spin size="large" />
        </div>
    );
    if (error) return <Alert type="error" message="Failed to load dashboard data" style={{ margin: 24 }} />;

    const { summary, charts } = data;
    const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : '—';

    // Calculate support metrics
    const openTickets = supportData?.data?.length || 0;
    const urgentTickets = supportData?.data?.filter((t: any) => t.priority === 'URGENT').length || 0;

    // Prepare chart data
    const revenueChartData = charts?.revenueByMonth?.map((r: any) => ({
        month: r.month,
        revenue: r.revenue,
        revenueOriginal: r.revenueOriginal,
    })) || [];

    const tierDistributionData = charts?.subscriptionBreakdown?.map((t: any) => ({
        name: t.tier,
        value: t.count,
    })) || [];

    const payrollChartData = charts?.payrollByMonth?.map((p: any) => ({
        month: p.month,
        volume: p.volume,
        payrolls: p.payrolls,
    })) || [];

    const tierColumns = [
        {
            title: 'Tier',
            dataIndex: 'tier',
            key: 'tier',
            render: (v: string) => (
                <Tag
                    style={{
                        background: tierGradient[v]?.[0] || '#f3f4f6',
                        border: `1px solid ${tierColor[v] || '#6b7280'}40`,
                        color: tierColor[v] || '#6b7280',
                        fontWeight: 600,
                        padding: '4px 12px',
                        borderRadius: 20,
                    }}
                >
                    {v}
                </Tag>
            ),
        },
        { title: 'Subscribers', dataIndex: 'subscriber_count', key: 'subscribers', align: 'right' as const },
        {
            title: 'MRR',
            dataIndex: 'total_mrr',
            key: 'mrr',
            align: 'right' as const,
            render: (v: any, r: any) => <strong style={{ color: '#10b981' }}>{r.currency} {Number(v).toLocaleString()}</strong>,
        },
        {
            title: 'Avg Workers',
            dataIndex: 'avg_workers',
            key: 'avg_workers',
            align: 'right' as const,
            render: (v: any) => Number(v).toFixed(1),
        },
    ];

    return (
        <div style={{ padding: 24, background: '#f8fafc', minHeight: '100vh' }}>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <div>
                    <Title level={3} style={{ margin: 0, color: '#1f2937' }}>Dashboard Overview</Title>
                    <Text style={{ color: '#6b7280' }}>Real-time insights into your business performance</Text>
                </div>
                <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                    <Select
                        value={currency}
                        onChange={setCurrency}
                        style={{ width: 100 }}
                        options={[
                            { value: 'USD', label: 'USD' },
                            { value: 'KES', label: 'KES' },
                            { value: 'EUR', label: 'EUR' },
                        ]}
                    />
                    <Tooltip title="Refresh now">
                        <Button icon={<ReloadOutlined />} onClick={() => refetch()} style={{ borderRadius: 8 }}>
                            Refresh
                        </Button>
                    </Tooltip>
                </div>
            </div>

            {/* Key Metrics */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Total Revenue"
                        value={(summary.totalRevenue || 0).toLocaleString()}
                        prefix={currency === 'USD' ? '$' : currency === 'EUR' ? '€' : ''}
                        suffix={currency === 'KES' ? ' KES' : ''}
                        color="#6366f1"
                        trend="up"
                        trendValue={12}
                        icon={<DollarOutlined />}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Monthly Revenue"
                        value={(summary.monthlyRevenue || 0).toLocaleString()}
                        prefix={currency === 'USD' ? '$' : currency === 'EUR' ? '€' : ''}
                        suffix={currency === 'KES' ? ' KES' : ''}
                        color="#10b981"
                        trend="up"
                        trendValue={8}
                        icon={<TrendingUpOutlined />}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Active Users"
                        value={summary.activeUsers30d || 0}
                        color="#f59e0b"
                        trend="up"
                        trendValue={15}
                        icon={<UserOutlined />}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Open Tickets"
                        value={openTickets}
                        color="#ef4444"
                        icon={<CustomerServiceOutlined />}
                    />
                </Col>
            </Row>

            {/* Secondary Stats */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={4}>
                    <Card style={{ borderRadius: 12, textAlign: 'center' }} bodyStyle={{ padding: 16 }}>
                        <Avatar size={40} style={{ background: '#dbeafe', color: '#3b82f6', marginBottom: 8 }} icon={<TeamOutlined />} />
                        <div>
                            <Text strong style={{ fontSize: 20, display: 'block' }}>{summary.totalUsers || 0}</Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>Total Users</Text>
                        </div>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={4}>
                    <Card style={{ borderRadius: 12, textAlign: 'center' }} bodyStyle={{ padding: 16 }}>
                        <Avatar size={40} style={{ background: '#d1fae5', color: '#10b981', marginBottom: 8 }} icon={<UserAddOutlined />} />
                        <div>
                            <Text strong style={{ fontSize: 20, display: 'block' }}>{summary.newUsers7d || 0}</Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>New (7d)</Text>
                        </div>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={4}>
                    <Card style={{ borderRadius: 12, textAlign: 'center' }} bodyStyle={{ padding: 16 }}>
                        <Avatar size={40} style={{ background: '#fef3c7', color: '#f59e0b', marginBottom: 8 }} icon={<ShopOutlined />} />
                        <div>
                            <Text strong style={{ fontSize: 20, display: 'block' }}>{summary.totalWorkers || 0}</Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>Workers</Text>
                        </div>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={4}>
                    <Card style={{ borderRadius: 12, textAlign: 'center' }} bodyStyle={{ padding: 16 }}>
                        <Avatar size={40} style={{ background: '#ede9fe', color: '#8b5cf6', marginBottom: 8 }} icon={<WalletOutlined />} />
                        <div>
                            <Text strong style={{ fontSize: 20, display: 'block' }}>{summary.payrollsProcessed || 0}</Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>Payrolls</Text>
                        </div>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={4}>
                    <Card style={{ borderRadius: 12, textAlign: 'center' }} bodyStyle={{ padding: 16 }}>
                        <Avatar size={40} style={{ background: '#fce7f3', color: '#ec4899', marginBottom: 8 }} icon={<CreditCardOutlined />} />
                        <div>
                            <Text strong style={{ fontSize: 20, display: 'block' }}>
                                {((summary.totalPayrollVolume || 0) / 1000).toFixed(0)}K
                            </Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>Payroll Vol</Text>
                        </div>
                    </Card>
                </Col>
                <Col xs={24} sm={12} lg={4}>
                    <Card
                        style={{
                            borderRadius: 12,
                            textAlign: 'center',
                            background: urgentTickets > 0 ? '#fef2f2' : '#f0fdf4',
                        }}
                        bodyStyle={{ padding: 16 }}
                    >
                        <Badge count={urgentTickets} overflowCount={99}>
                            <Avatar
                                size={40}
                                style={{
                                    background: urgentTickets > 0 ? '#fee2e2' : '#d1fae5',
                                    color: urgentTickets > 0 ? '#ef4444' : '#10b981',
                                }}
                                icon={<ExclamationCircleOutlined />}
                            />
                        </Badge>
                        <div style={{ marginTop: 8 }}>
                            <Text strong style={{ fontSize: 20, display: 'block', color: urgentTickets > 0 ? '#ef4444' : '#10b981' }}>
                                {urgentTickets}
                            </Text>
                            <Text style={{ fontSize: 12, color: '#9ca3af' }}>Urgent</Text>
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Charts Section */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                {/* Revenue Chart */}
                <Col xs={24} lg={16}>
                    <Card
                        title={
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <LineChartOutlined style={{ color: '#6366f1' }} />
                                <span>Revenue Trend (12 Months)</span>
                            </div>
                        }
                        style={{ borderRadius: 16, border: 'none' }}
                        bodyStyle={{ padding: 20 }}
                    >
                        <ResponsiveContainer width="100%" height={300}>
                            <AreaChart data={revenueChartData}>
                                <defs>
                                    <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="0%" stopColor="#6366f1" stopOpacity={0.3} />
                                        <stop offset="100%" stopColor="#6366f1" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                                <XAxis dataKey="month" tick={{ fontSize: 11 }} stroke="#9ca3af" />
                                <YAxis tick={{ fontSize: 11 }} stroke="#9ca3af" />
                                <RechartTooltip
                                    formatter={(v: any) => [`${currency} ${Number(v).toLocaleString()}`, 'Revenue']}
                                    contentStyle={{ borderRadius: 8 }}
                                />
                                <Area
                                    type="monotone"
                                    dataKey="revenue"
                                    stroke="#6366f1"
                                    strokeWidth={3}
                                    fill="url(#revenueGradient)"
                                />
                            </AreaChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>

                {/* Tier Distribution */}
                <Col xs={24} lg={8}>
                    <Card
                        title={
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <PieChartOutlined style={{ color: '#8b5cf6' }} />
                                <span>Subscription Tiers</span>
                            </div>
                        }
                        style={{ borderRadius: 16, border: 'none' }}
                        bodyStyle={{ padding: 20 }}
                    >
                        <ResponsiveContainer width="100%" height={250}>
                            <PieChart>
                                <Pie
                                    data={tierDistributionData}
                                    dataKey="value"
                                    nameKey="name"
                                    cx="50%"
                                    cy="50%"
                                    outerRadius={80}
                                    innerRadius={50}
                                    paddingAngle={3}
                                >
                                    {tierDistributionData.map((_entry: any, index: number) => (
                                        <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                                    ))}
                                </Pie>
                                <RechartTooltip />
                                <Legend verticalAlign="bottom" height={36} />
                            </PieChart>
                        </ResponsiveContainer>
                        <div style={{ marginTop: 16 }}>
                            {tierDistributionData.map((tier: any, idx: number) => (
                                <div key={tier.name} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                                    <Space>
                                        <div style={{ width: 12, height: 12, borderRadius: 3, background: PIE_COLORS[idx % PIE_COLORS.length] }} />
                                        <Text style={{ fontSize: 13 }}>{tier.name}</Text>
                                    </Space>
                                    <Text strong style={{ fontSize: 13 }}>{tier.value}</Text>
                                </div>
                            ))}
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Bottom Section */}
            <Row gutter={[16, 16]}>
                {/* Tier Stats Table */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <BarChartOutlined style={{ color: '#10b981' }} />
                                <span>Tier Performance</span>
                            </div>
                        }
                        style={{ borderRadius: 16, border: 'none' }}
                        bodyStyle={{ padding: 0 }}
                    >
                        <Table
                            columns={tierColumns}
                            dataSource={tierStats || []}
                            rowKey="tier"
                            loading={tierStatsLoading}
                            pagination={false}
                            size="small"
                        />
                    </Card>
                </Col>

                {/* Payroll Volume */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                <CalendarOutlined style={{ color: '#f59e0b' }} />
                                <span>Payroll Volume (12 Months)</span>
                            </div>
                        }
                        style={{ borderRadius: 16, border: 'none' }}
                        bodyStyle={{ padding: 20 }}
                    >
                        <ResponsiveContainer width="100%" height={250}>
                            <BarChart data={payrollChartData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" />
                                <XAxis dataKey="month" tick={{ fontSize: 11 }} stroke="#9ca3af" />
                                <YAxis tick={{ fontSize: 11 }} stroke="#9ca3af" />
                                <RechartTooltip
                                    formatter={(v: any) => [`${Number(v).toLocaleString()}`, 'Volume']}
                                    contentStyle={{ borderRadius: 8 }}
                                />
                                <Bar dataKey="volume" fill="#f59e0b" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>

            {/* Footer */}
            <div style={{ marginTop: 24, textAlign: 'center' }}>
                <Text style={{ fontSize: 12, color: '#9ca3af' }}>
                    Auto-refreshes every 60s · Last updated: {lastUpdated}
                </Text>
            </div>
        </div>
    );
}
