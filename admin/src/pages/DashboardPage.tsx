import { useQuery } from '@tanstack/react-query';
import { Row, Col, Card, Statistic, Typography, Spin, Alert, Table, Tag, Button, Tooltip } from 'antd';
import {
    TeamOutlined, UserOutlined, DollarOutlined, CustomerServiceOutlined, ReloadOutlined,
} from '@ant-design/icons';
import {
    LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip as RechartTooltip, Legend, ResponsiveContainer,
} from 'recharts';
import { adminAnalytics, adminPlans } from '../api/client';

const { Title, Text } = Typography;

const PIE_COLORS = ['#6366f1', '#8b5cf6', '#06b6d4', '#10b981'];

const tierColor: Record<string, string> = {
    FREE: 'default', BASIC: 'blue', GOLD: 'gold', PLATINUM: 'purple',
};

function StatCard({ title, value, prefix, suffix, color, onClick }: any) {
    return (
        <Card
            style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)', cursor: onClick ? 'pointer' : undefined }}
            onClick={onClick}
            hoverable={!!onClick}
        >
            <Statistic
                title={<span style={{ fontSize: 13, color: '#64748b', fontWeight: 500 }}>{title}</span>}
                value={value}
                prefix={prefix}
                suffix={suffix}
                valueStyle={{ color, fontSize: 28, fontWeight: 700 }}
            />
        </Card>
    );
}

export default function DashboardPage() {
    const { data, isLoading, error, refetch, dataUpdatedAt } = useQuery({
        queryKey: ['admin-dashboard'],
        queryFn: adminAnalytics.dashboard,
        refetchInterval: 60000,
    });
    const { data: tierStats, isLoading: tierStatsLoading, refetch: refetchTier } = useQuery({
        queryKey: ['admin-tier-stats'],
        queryFn: adminPlans.stats,
        refetchInterval: 60000,
    });

    if (isLoading) return <Spin size="large" style={{ display: 'block', marginTop: 100, textAlign: 'center' }} />;
    if (error) return <Alert type="error" message="Failed to load dashboard data" />;

    const { summary, charts } = data;
    const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : '—';

    const tierColumns = [
        { title: 'Tier', dataIndex: 'tier', key: 'tier', render: (v: string) => <Tag color={tierColor[v] || 'default'}>{v}</Tag> },
        { title: 'Subscribers', dataIndex: 'subscriber_count', key: 'subscribers', align: 'right' as const },
        {
            title: 'MRR',
            dataIndex: 'total_mrr',
            key: 'mrr',
            align: 'right' as const,
            render: (v: any, r: any) => <strong>{r.currency} {Number(v).toLocaleString()}</strong>,
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
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <div>
                    <Title level={3} style={{ margin: 0 }}>Dashboard</Title>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        Auto-refreshes every 60s · Last updated: {lastUpdated}
                    </Text>
                </div>
                <Tooltip title="Refresh now">
                    <Button
                        icon={<ReloadOutlined />}
                        onClick={() => { refetch(); refetchTier(); }}
                        loading={isLoading}
                    >
                        Refresh
                    </Button>
                </Tooltip>
            </div>

            {/* Primary stats */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard title="Total Employers" value={summary.totalUsers} prefix={<UserOutlined />} color="#6366f1" />
                </Col>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard title="Active Workers" value={summary.activeWorkers} prefix={<TeamOutlined />} color="#06b6d4" />
                </Col>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard title="Portal Connections" value={summary.totalPortalLinks || 0} color="#10b981" />
                </Col>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard title="Pending Invites" value={summary.pendingPortalInvites || 0} color="#f59e0b" />
                </Col>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard title="Monthly Revenue" value={(summary.monthlyRevenue || 0).toFixed(0)} prefix={<DollarOutlined />} suffix="KES" color="#10b981" />
                </Col>
                <Col xs={24} sm={12} lg={8} xl={4}>
                    <StatCard
                        title="Open Tickets"
                        value={summary.openSupportTickets}
                        prefix={<CustomerServiceOutlined />}
                        color={summary.openSupportTickets > 0 ? '#ef4444' : '#94a3b8'}
                    />
                </Col>
            </Row>

            {/* Secondary stats */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="All-Time Revenue" value={(summary.totalRevenue || 0).toFixed(0)} suffix="KES" color="#374151" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Payrolls Run" value={summary.payrollsProcessed} color="#374151" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Total Payroll Volume" value={(summary.totalPayrollVolume || 0).toFixed(0)} suffix="KES" color="#374151" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Active Users (30d)" value={summary.activeUsers30d} color="#374151" />
                </Col>
            </Row>

            {/* Charts */}
            <Row gutter={[16, 16]}>
                <Col xs={24} lg={16}>
                    <Card title="Subscription Revenue (Last 12 Months)" style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)' }}>
                        <ResponsiveContainer width="100%" height={260}>
                            <LineChart data={charts.revenueByMonth}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                                <YAxis tick={{ fontSize: 11 }} />
                                <RechartTooltip formatter={(v: any) => [`KES ${Number(v).toLocaleString()}`, 'Revenue']} />
                                <Line type="monotone" dataKey="revenue" stroke="#6366f1" strokeWidth={2} dot={{ r: 3 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card
                        title="Active Subscriptions by Tier"
                        style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)', height: '100%' }}
                    >
                        <ResponsiveContainer width="100%" height={260}>
                            <PieChart>
                                <Pie
                                    data={charts.subscriptionBreakdown}
                                    dataKey="count"
                                    nameKey="tier"
                                    cx="50%"
                                    cy="50%"
                                    outerRadius={90}
                                    label={({ tier, count }) => `${tier}: ${count}`}
                                >
                                    {charts.subscriptionBreakdown.map((_: any, i: number) => (
                                        <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                                    ))}
                                </Pie>
                                <RechartTooltip />
                            </PieChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
                <Col xs={24}>
                    <Card title="Payroll Volume (Last 12 Months)" style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)' }}>
                        <ResponsiveContainer width="100%" height={220}>
                            <BarChart data={charts.payrollByMonth}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                                <YAxis tick={{ fontSize: 11 }} />
                                <RechartTooltip />
                                <Legend />
                                <Bar dataKey="volume" name="Volume (KES)" fill="#06b6d4" radius={[4, 4, 0, 0]} />
                                <Bar dataKey="payrolls" name="Payrolls Run" fill="#6366f1" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>

            {/* Tier Stats Table */}
            <Row gutter={[16, 16]} style={{ marginTop: 24, marginBottom: 24 }}>
                <Col xs={24}>
                    <Card title="Subscription Tier Statistics" style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)' }}>
                        <Table
                            columns={tierColumns}
                            dataSource={tierStats || []}
                            rowKey="tier"
                            loading={tierStatsLoading}
                            pagination={false}
                            size="small"
                            locale={{ emptyText: 'No active subscriptions' }}
                        />
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
