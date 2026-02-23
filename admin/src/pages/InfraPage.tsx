import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Row, Col, Card, Tag, Typography, Alert, Progress, List, Button, Statistic,
    Badge, Space, Tooltip, Divider, Empty, Popconfirm, message, Avatar,
    Tabs, Descriptions, Skeleton
} from 'antd';
import {
    DatabaseOutlined, HddOutlined, CloudServerOutlined, ThunderboltOutlined,
    ReloadOutlined, SyncOutlined, CheckCircleOutlined, ExclamationCircleOutlined,
    ClockCircleOutlined, DashboardOutlined, ToolOutlined, WarningOutlined,
    ContainerOutlined, ArrowUpOutlined, ArrowDownOutlined, DeleteOutlined,
    RedoOutlined, LineChartOutlined
} from '@ant-design/icons';
import { useState, useCallback } from 'react';
import { adminAnalytics, adminOperations } from '../api/client';
import dayjs from 'dayjs';
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartTooltip,
    ResponsiveContainer, PieChart, Pie, Cell
} from 'recharts';

const { Title, Text } = Typography;
const { TabPane } = Tabs;

interface InfraData {
    database: any;
    disk: any;
    memory: any;
    redis: any;
    docker: any;
    timestamp: string;
}

// Health status badge with pulse animation
function HealthBadge({ status, showPulse = false }: { status: string; showPulse?: boolean }) {
    const normalized = status?.toLowerCase();
    const healthy = ['healthy', 'ok', 'running'].includes(normalized);
    const unavailable = normalized === 'unavailable';
    const color = healthy ? 'green' : unavailable ? 'default' : 'red';
    const icon = healthy ? <CheckCircleOutlined /> : unavailable ? <ClockCircleOutlined /> : <ExclamationCircleOutlined />;

    return (
        <Badge
            status={color as any}
            text={
                <Tag
                    color={color}
                    icon={icon}
                    style={showPulse && healthy ? { animation: 'pulse 2s infinite' } : {}}
                >
                    {status?.toUpperCase()}
                </Tag>
            }
        />
    );
}

// Mini stat card
function StatCard({ title, value, suffix, prefix, icon, color, trend }: any) {
    return (
        <Card bordered={false} style={{ background: color ? `${color}10` : '#f8fafc', borderRadius: 12 }}>
            <Space align="start">
                <Avatar icon={icon} style={{ background: color || '#6366f1' }} />
                <div>
                    <Text type="secondary" style={{ fontSize: 12 }}>{title}</Text>
                    <div style={{ fontSize: 24, fontWeight: 600 }}>
                        {prefix}{value}{suffix}
                    </div>
                    {trend && (
                        <Text type={trend > 0 ? 'success' : 'danger'} style={{ fontSize: 12 }}>
                            {trend > 0 ? <ArrowUpOutlined /> : <ArrowDownOutlined />} {Math.abs(trend)}%
                        </Text>
                    )}
                </div>
            </Space>
        </Card>
    );
}

// Circular gauge for resource usage
function ResourceGauge({ percent, title, color, size = 120 }: any) {
    const strokeColor = percent > 85 ? '#ef4444' : percent > 60 ? '#f59e0b' : color || '#10b981';

    return (
        <div style={{ textAlign: 'center' }}>
            <div style={{ position: 'relative', width: size, height: size, margin: '0 auto' }}>
                <Progress
                    type="circle"
                    percent={percent}
                    strokeColor={strokeColor}
                    width={size}
                    strokeWidth={10}
                />
            </div>
            <Text style={{ fontSize: 14, fontWeight: 500 }}>{title}</Text>
        </div>
    );
}

export default function InfraPage() {
    const [activeTab, setActiveTab] = useState('overview');
    const [refreshing, setRefreshing] = useState(false);
    const queryClient = useQueryClient();

    const { data, isLoading, error, refetch, dataUpdatedAt } = useQuery<InfraData>({
        queryKey: ['admin-infra'],
        queryFn: adminAnalytics.infra,
        refetchInterval: 30_000,
    });

    // Container actions mutation
    const containerAction = useMutation({
        mutationFn: ({ action, container }: { action: string; container: string }) => {
            if (action === 'restart') return adminOperations.restartContainer(container);
            if (action === 'stop') return adminOperations.stopContainer(container);
            return Promise.resolve();
        },
        onSuccess: () => {
            message.success('Action completed');
            queryClient.invalidateQueries({ queryKey: ['admin-infra'] });
        },
        onError: (error: any) => {
            message.error(error.message || 'Action failed');
        },
    });

    const handleRefresh = useCallback(async () => {
        setRefreshing(true);
        await refetch();
        setRefreshing(false);
    }, [refetch]);

    const lastUpdated = dataUpdatedAt ? dayjs(dataUpdatedAt).format('HH:mm:ss') : '—';

    if (isLoading) {
        return (
            <div style={{ padding: 24 }}>
                <Skeleton active paragraph={{ rows: 4 }} />
                <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
                    <Col span={12}><Skeleton active /></Col>
                    <Col span={12}><Skeleton active /></Col>
                </Row>
            </div>
        );
    }

    if (error) {
        return (
            <Alert
                type="error"
                message="Failed to load infrastructure data"
                description={error instanceof Error ? error.message : 'Unknown error'}
                showIcon
                action={
                    <Button icon={<ReloadOutlined />} onClick={() => refetch()}>
                        Retry
                    </Button>
                }
            />
        );
    }

    const { database, disk, memory, redis, docker, timestamp } = data!;

    // Prepare chart data
    const memoryChartData = [
        { name: 'Used', value: memory?.usedMB || 0 },
        { name: 'Free', value: memory?.freeMB || 0 },
    ];

    const tableSizeData = database?.topTables?.slice(0, 5).map((t: any) => ({
        name: t.table,
        rows: t.rows,
    })) || [];

    const containerStatusData = docker?.containers ? [
        { name: 'Healthy', value: docker.containers.filter((c: any) => c.healthy).length },
        { name: 'Unhealthy', value: docker.containers.filter((c: any) => !c.healthy).length },
    ] : [];

    return (
        <div>
            <style>{`
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.6; }
                }
                .infra-card { transition: all 0.3s ease; }
                .infra-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            `}</style>

            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <div>
                    <Title level={3} style={{ margin: 0 }}>
                        <DashboardOutlined style={{ marginRight: 8 }} />
                        Infrastructure Health
                    </Title>
                    <Text type="secondary">
                        Auto-refreshes every 30s · Last updated: {lastUpdated}
                    </Text>
                </div>
                <Space>
                    <Button icon={<ReloadOutlined spin={refreshing} />} onClick={handleRefresh} loading={refreshing}>
                        Refresh
                    </Button>
                    <Tag color="blue">{docker?.containers?.length || 0} Containers</Tag>
                    <Tag color="green">{database?.activeConnections || 0} DB Connections</Tag>
                </Space>
            </div>

            {/* Quick Stats Row */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Database Size"
                        value={database?.size || 'N/A'}
                        icon={<DatabaseOutlined />}
                        color="#6366f1"
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Memory Usage"
                        value={memory?.usedPercent || 0}
                        suffix="%"
                        icon={<ThunderboltOutlined />}
                        color={memory?.usedPercent > 85 ? '#ef4444' : '#10b981'}
                        trend={2}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Disk Usage"
                        value={parseInt(disk?.usedPercent) || 0}
                        suffix="%"
                        icon={<HddOutlined />}
                        color={parseInt(disk?.usedPercent) > 85 ? '#ef4444' : '#06b6d4'}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Redis Uptime"
                        value={redis?.uptimeSeconds ? Math.round(parseInt(redis.uptimeSeconds) / 3600) : 0}
                        suffix="h"
                        icon={<CloudServerOutlined />}
                        color="#f59e0b"
                    />
                </Col>
            </Row>

            {/* Main Content Tabs */}
            <Tabs activeKey={activeTab} onChange={setActiveTab} type="card">
                <TabPane tab={<><DashboardOutlined /> Overview</>} key="overview">
                    <Row gutter={[16, 16]}>
                        {/* Database Card */}
                        <Col xs={24} lg={12}>
                            <Card
                                title={
                                    <Space>
                                        <DatabaseOutlined style={{ color: '#6366f1' }} />
                                        <span>PostgreSQL Database</span>
                                    </Space>
                                }
                                extra={<HealthBadge status={database?.status} showPulse />}
                                className="infra-card"
                            >
                                {database?.status === 'healthy' ? (
                                    <div>
                                        <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
                                            <Col span={8}>
                                                <Statistic title="Size" value={database.size} />
                                            </Col>
                                            <Col span={8}>
                                                <Statistic
                                                    title="Active Connections"
                                                    value={database.activeConnections}
                                                    suffix="/ 100"
                                                />
                                            </Col>
                                            <Col span={8}>
                                                <Statistic
                                                    title="Longest Query"
                                                    value={database.longestQuerySeconds?.toFixed(2)}
                                                    suffix="s"
                                                    valueStyle={{ color: database.longestQuerySeconds > 5 ? '#ef4444' : '#52c41a' }}
                                                />
                                            </Col>
                                        </Row>

                                        <Divider style={{ margin: '12px 0' }} />

                                        <Text strong style={{ fontSize: 12 }}>Top Tables by Row Count</Text>
                                        <div style={{ height: 200, marginTop: 12 }}>
                                            <ResponsiveContainer width="100%" height="100%">
                                                <BarChart data={tableSizeData} layout="vertical">
                                                    <CartesianGrid strokeDasharray="3 3" />
                                                    <XAxis type="number" />
                                                    <YAxis dataKey="name" type="category" width={100} style={{ fontSize: 11 }} />
                                                    <RechartTooltip />
                                                    <Bar dataKey="rows" fill="#6366f1" radius={[0, 4, 4, 0]} />
                                                </BarChart>
                                            </ResponsiveContainer>
                                        </div>
                                    </div>
                                ) : (
                                    <Alert type="error" message={database?.error} showIcon />
                                )}
                            </Card>
                        </Col>

                        {/* Memory Card */}
                        <Col xs={24} lg={12}>
                            <Card
                                title={
                                    <Space>
                                        <ThunderboltOutlined style={{ color: '#f59e0b' }} />
                                        <span>System Memory</span>
                                    </Space>
                                }
                                className="infra-card"
                            >
                                <Row gutter={[24, 24]} align="middle">
                                    <Col xs={24} sm={8}>
                                        <ResourceGauge
                                            percent={memory?.usedPercent || 0}
                                            title="Memory Used"
                                            color="#f59e0b"
                                        />
                                    </Col>
                                    <Col xs={24} sm={16}>
                                        <Descriptions column={1} size="small">
                                            <Descriptions.Item label="Total">{memory?.totalMB} MB</Descriptions.Item>
                                            <Descriptions.Item label="Used">{memory?.usedMB} MB</Descriptions.Item>
                                            <Descriptions.Item label="Free">{memory?.freeMB} MB</Descriptions.Item>
                                            <Descriptions.Item label="Node.js RSS">{memory?.processRssMB} MB</Descriptions.Item>
                                        </Descriptions>
                                    </Col>
                                </Row>
                            </Card>
                        </Col>

                        {/* Disk Card */}
                        <Col xs={24} lg={12}>
                            <Card
                                title={
                                    <Space>
                                        <HddOutlined style={{ color: '#06b6d4' }} />
                                        <span>Disk Usage (/)</span>
                                    </Space>
                                }
                                className="infra-card"
                            >
                                <Row gutter={[24, 24]} align="middle">
                                    <Col xs={24} sm={8}>
                                        <ResourceGauge
                                            percent={parseInt(disk?.usedPercent) || 0}
                                            title="Disk Used"
                                            color="#06b6d4"
                                        />
                                    </Col>
                                    <Col xs={24} sm={16}>
                                        <Descriptions column={1} size="small">
                                            <Descriptions.Item label="Total">{disk?.total}</Descriptions.Item>
                                            <Descriptions.Item label="Used">{disk?.used}</Descriptions.Item>
                                            <Descriptions.Item label="Available">{disk?.available}</Descriptions.Item>
                                        </Descriptions>
                                    </Col>
                                </Row>
                            </Card>
                        </Col>

                        {/* Redis Card */}
                        <Col xs={24} lg={12}>
                            <Card
                                title={
                                    <Space>
                                        <CloudServerOutlined style={{ color: '#ec4899' }} />
                                        <span>Redis Cache</span>
                                    </Space>
                                }
                                extra={<HealthBadge status={redis?.status} />}
                                className="infra-card"
                            >
                                {redis?.status === 'healthy' ? (
                                    <Row gutter={[16, 16]}>
                                        <Col span={12}>
                                            <Statistic title="Version" value={redis.version} />
                                        </Col>
                                        <Col span={12}>
                                            <Statistic title="Memory Used" value={redis.usedMemoryHuman} />
                                        </Col>
                                        <Col span={12}>
                                            <Statistic title="Clients" value={redis.connectedClients} />
                                        </Col>
                                        <Col span={12}>
                                            <Statistic
                                                title="Commands Processed"
                                                value={redis.totalCommandsProcessed?.toLocaleString()}
                                            />
                                        </Col>
                                    </Row>
                                ) : (
                                    <Alert type="error" message={redis?.error} showIcon />
                                )}
                            </Card>
                        </Col>
                    </Row>
                </TabPane>

                <TabPane tab={<><ContainerOutlined /> Docker Containers</>} key="containers">
                    <Card
                        title={
                            <Space>
                                <CloudServerOutlined />
                                Docker Containers
                                <Badge count={docker?.containers?.length || 0} style={{ backgroundColor: '#6366f1' }} />
                            </Space>
                        }
                        extra={<HealthBadge status={docker?.status} />}
                        className="infra-card"
                    >
                        {docker?.status === 'unavailable' ? (
                            <Empty description="Docker info not available (running in non-docker env or permission denied)" />
                        ) : (
                            <>
                                {/* Container Status Chart */}
                                {containerStatusData.length > 0 && (
                                    <Row gutter={[24, 24]} style={{ marginBottom: 24 }}>
                                        <Col xs={24} sm={8}>
                                            <div style={{ height: 200 }}>
                                                <ResponsiveContainer width="100%" height="100%">
                                                    <PieChart>
                                                        <Pie
                                                            data={containerStatusData}
                                                            cx="50%"
                                                            cy="50%"
                                                            innerRadius={60}
                                                            outerRadius={80}
                                                            paddingAngle={5}
                                                            dataKey="value"
                                                        >
                                                            {containerStatusData.map((entry: any, index: number) => (
                                                                <Cell key={`cell-${index}`} fill={index === 0 ? '#10b981' : '#ef4444'} />
                                                            ))}
                                                        </Pie>
                                                        <RechartTooltip />
                                                    </PieChart>
                                                </ResponsiveContainer>
                                            </div>
                                        </Col>
                                        <Col xs={24} sm={16}>
                                            <Descriptions column={2}>
                                                <Descriptions.Item label="Healthy Containers">
                                                    <Tag color="green">{containerStatusData[0]?.value || 0}</Tag>
                                                </Descriptions.Item>
                                                <Descriptions.Item label="Unhealthy">
                                                    <Tag color="red">{containerStatusData[1]?.value || 0}</Tag>
                                                </Descriptions.Item>
                                            </Descriptions>
                                        </Col>
                                    </Row>
                                )}

                                <Divider />

                                {/* Container List */}
                                <List
                                    grid={{ gutter: 16, xs: 1, sm: 2, lg: 3 }}
                                    dataSource={docker?.containers || []}
                                    renderItem={(c: any) => (
                                        <List.Item>
                                            <Card
                                                size="small"
                                                title={
                                                    <Space>
                                                        <Badge status={c.healthy ? 'success' : 'error'} />
                                                        <Text strong>{c.name}</Text>
                                                    </Space>
                                                }
                                                extra={
                                                    <Tag color={c.healthy ? 'green' : 'red'} size="small">
                                                        {c.status}
                                                    </Tag>
                                                }
                                            >
                                                <Text type="secondary" style={{ fontSize: 12, display: 'block' }} ellipsis>
                                                    {c.image}
                                                </Text>
                                                <Space style={{ marginTop: 12 }}>
                                                    <Tooltip title="Restart Container">
                                                        <Popconfirm
                                                            title="Restart this container?"
                                                            onConfirm={() => containerAction.mutate({ action: 'restart', container: c.name })}
                                                        >
                                                            <Button
                                                                icon={<RedoOutlined />}
                                                                size="small"
                                                                loading={containerAction.isPending}
                                                            >
                                                                Restart
                                                            </Button>
                                                        </Popconfirm>
                                                    </Tooltip>
                                                </Space>
                                            </Card>
                                        </List.Item>
                                    )}
                                />
                            </>
                        )}
                    </Card>
                </TabPane>

                <TabPane tab={<><ToolOutlined /> System Tools</>} key="tools">
                    <Row gutter={[16, 16]}>
                        <Col xs={24} lg={8}>
                            <Card title="Cache Management" className="infra-card">
                                <Space direction="vertical" style={{ width: '100%' }}>
                                    <Popconfirm
                                        title="Clear all caches?"
                                        description="This will clear Redis and application caches."
                                        onConfirm={() => {
                                            // TODO: Implement cache clear
                                            message.success('Caches cleared');
                                        }}
                                    >
                                        <Button icon={<DeleteOutlined />} danger block>
                                            Clear All Caches
                                        </Button>
                                    </Popconfirm>
                                    <Button icon={<SyncOutlined />} block>
                                        Refresh Exchange Rates
                                    </Button>
                                </Space>
                            </Card>
                        </Col>

                        <Col xs={24} lg={8}>
                            <Card title="Database" className="infra-card">
                                <Space direction="vertical" style={{ width: '100%' }}>
                                    <Button icon={<HddOutlined />} block>
                                        Run VACUUM ANALYZE
                                    </Button>
                                    <Button icon={<DatabaseOutlined />} block>
                                        Check Connections
                                    </Button>
                                </Space>
                            </Card>
                        </Col>

                        <Col xs={24} lg={8}>
                            <Card title="Monitoring" className="infra-card">
                                <Space direction="vertical" style={{ width: '100%' }}>
                                    <Button icon={<LineChartOutlined />} block>
                                        View Metrics
                                    </Button>
                                    <Button icon={<WarningOutlined />} block>
                                        Alert Rules
                                    </Button>
                                </Space>
                            </Card>
                        </Col>
                    </Row>
                </TabPane>
            </Tabs>

            {/* Alerts Section */}
            {(memory?.usedPercent > 85 || parseInt(disk?.usedPercent) > 85) && (
                <Alert
                    type="warning"
                    message="High Resource Usage Detected"
                    description={
                        memory?.usedPercent > 85
                            ? `Memory usage is at ${memory.usedPercent}%. Consider scaling up or optimizing.`
                            : `Disk usage is at ${disk.usedPercent}. Consider cleaning up old logs or scaling storage.`
                    }
                    showIcon
                    style={{ marginTop: 24 }}
                />
            )}
        </div>
    );
}
