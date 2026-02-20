import { useQuery } from '@tanstack/react-query';
import { Row, Col, Card, Statistic, Typography, Spin, Alert } from 'antd';
import {
    TeamOutlined,
    UserOutlined,
    DollarOutlined,
    CustomerServiceOutlined,
} from '@ant-design/icons';
import {
    LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts';
import { adminAnalytics } from '../api/client';

const { Title } = Typography;

const PIE_COLORS = ['#6366f1', '#8b5cf6', '#06b6d4', '#10b981'];

function StatCard({ title, value, prefix, suffix, color }: any) {
    return (
        <Card style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)' }}>
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
    const { data, isLoading, error } = useQuery({
        queryKey: ['admin-dashboard'],
        queryFn: adminAnalytics.dashboard,
    });

    if (isLoading) return <Spin size="large" style={{ display: 'block', marginTop: 100, textAlign: 'center' }} />;
    if (error) return <Alert type="error" title="Failed to load dashboard data" />;

    const { summary, charts } = data;

    return (
        <div>
            {error && <Alert title={error} type="error" style={{ marginBottom: 16 }} />}
            <Title level={3} style={{ marginBottom: 24 }}>Dashboard</Title>

            {/* Summary cards */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Total Employers" value={summary.totalUsers} prefix={<UserOutlined />} color="#6366f1" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Active Workers" value={summary.activeWorkers} prefix={<TeamOutlined />} color="#06b6d4" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Monthly Revenue" value={(summary.monthlyRevenue || 0).toFixed(0)} prefix={<DollarOutlined />} suffix="KES" color="#10b981" />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard title="Open Support Tickets" value={summary.openSupportTickets} prefix={<CustomerServiceOutlined />} color="#f59e0b" />
                </Col>
            </Row>

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
                                <Tooltip formatter={(v: any) => [`KES ${Number(v).toLocaleString()}`, 'Revenue']} />
                                <Line type="monotone" dataKey="revenue" stroke="#6366f1" strokeWidth={2} dot={{ r: 3 }} />
                            </LineChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
                <Col xs={24} lg={8}>
                    <Card title="Active Subscriptions by Tier" style={{ borderRadius: 12, border: 'none', boxShadow: '0 1px 3px rgba(0,0,0,.08)', height: '100%' }}>
                        <ResponsiveContainer width="100%" height={260}>
                            <PieChart>
                                <Pie
                                    data={charts.subscriptionBreakdown}
                                    dataKey="count"
                                    nameKey="tier"
                                    cx="50%"
                                    cy="50%"
                                    outerRadius={90}
                                >
                                    {charts.subscriptionBreakdown.map((_: any, i: number) => (
                                        <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
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
                                <Tooltip />
                                <Legend />
                                <Bar dataKey="volume" name="Volume (KES)" fill="#06b6d4" radius={[4, 4, 0, 0]} />
                                <Bar dataKey="payrolls" name="Payrolls Run" fill="#6366f1" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
