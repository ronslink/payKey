import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Row, Col, Card, Tag, Typography, Alert, Progress, Button, Statistic,
    Badge, Space, Divider, Empty, message, Descriptions, Skeleton
} from 'antd';
import {
    DatabaseOutlined, HddOutlined, CloudServerOutlined, ThunderboltOutlined,
    ReloadOutlined, CheckCircleOutlined, ExclamationCircleOutlined,
    ClockCircleOutlined, DashboardOutlined, WarningOutlined,
    ContainerOutlined, ArrowUpOutlined, ArrowDownOutlined,
    RedoOutlined, ClusterOutlined
} from '@ant-design/icons';
import { useState, useCallback } from 'react';
import { adminAnalytics, adminOperations } from '../api/client';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartTooltip,
    ResponsiveContainer
} from 'recharts';

dayjs.extend(relativeTime);

const { Title, Text } = Typography;

interface InfraData {
    database: any;
    disk: any;
    memory: any;
    redis: any;
    docker: any;
    timestamp: string;
    server?: {
        uptime: string;
        loadAvg: number[];
        cpuCount: number;
    };
}

// Enhanced health badge with detailed status
function HealthBadge({ status, showPulse = false }: { status: string; showPulse?: boolean }) {
    const normalized = status?.toLowerCase();
    const healthy = ['healthy', 'ok', 'running', 'up'].includes(normalized);
    const unavailable = normalized === 'unavailable' || normalized === 'down';
    const warning = normalized === 'degraded' || normalized === 'warning';
    
    let color = 'green';
    let icon = <CheckCircleOutlined />;
    
    if (unavailable) {
        color = 'default';
        icon = <ClockCircleOutlined />;
    } else if (!healthy) {
        color = 'red';
        icon = <ExclamationCircleOutlined />;
    } else if (warning) {
        color = 'orange';
        icon = <WarningOutlined />;
    }

    return (
        <Badge
            status={color as any}
            text={
                <Tag
                    color={color}
                    icon={icon}
                    style={showPulse && healthy ? { 
                        animation: 'pulse 2s infinite',
                        borderColor: '#52c41a'
                    } : {}}
                >
                    {status?.toUpperCase()}
                </Tag>
            }
        />
    );
}

// Enhanced stat card with more visual appeal
function StatCard({ title, value, suffix, prefix, icon, color, trend, subtitle, loading }: any) {
    const trendColor = trend > 0 ? '#10b981' : trend < 0 ? '#ef4444' : '#6b7280';
    const TrendIcon = trend > 0 ? ArrowUpOutlined : trend < 0 ? ArrowDownOutlined : null;
    
    return (
        <Card 
            bordered={false} 
            style={{ 
                background: `linear-gradient(135deg, ${color}10 0%, ${color}05 100%)`, 
                borderRadius: 16,
                border: `1px solid ${color}20`
            }}
            bodyStyle={{ padding: 20 }}
        >
            <Space align="start">
                <div style={{
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    background: `${color}15`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                }}>
                    {icon}
                </div>
                <div style={{ flex: 1 }}>
                    <Text type="secondary" style={{ fontSize: 12, textTransform: 'uppercase', letterSpacing: 0.5 }}>
                        {title}
                    </Text>
                    <div style={{ 
                        fontSize: 28, 
                        fontWeight: 700, 
                        color: '#1f2937',
                        lineHeight: 1.2,
                        fontFamily: 'SF Pro Display, -apple-system, sans-serif'
                    }}>
                        {prefix}{loading ? '—' : value}{suffix}
                    </div>
                    {subtitle && (
                        <Text type="secondary" style={{ fontSize: 11 }}>{subtitle}</Text>
                    )}
                    {trend !== undefined && (
                        <div style={{ marginTop: 4 }}>
                            <Text style={{ fontSize: 12, color: trendColor }}>
                                {TrendIcon && <TrendIcon />} {Math.abs(trend)}%
                            </Text>
                            <Text type="secondary" style={{ fontSize: 11, marginLeft: 4 }}>vs last hour</Text>
                        </div>
                    )}
                </div>
            </Space>
        </Card>
    );
}

// Enhanced circular gauge
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function ResourceGauge({ percent, title, color, size = 140, showLabel = true }: { percent: number; title?: string; color?: string; size?: number; showLabel?: boolean }) {
    const getColor = () => {
        if (percent > 90) return '#ef4444';
        if (percent > 75) return '#f59e0b';
        if (percent > 50) return '#3b82f6';
        return color || '#10b981';
    };
    
    const gaugeColor = getColor();

    return (
        <div style={{ textAlign: 'center', padding: 16 }}>
            <div style={{ position: 'relative', width: size, height: size, margin: '0 auto' }}>
                <Progress
                    type="circle"
                    percent={percent}
                    strokeColor={gaugeColor}
                    width={size}
                    strokeWidth={10}
                    trailColor="#e5e7eb"
                    format={(pct) => (
                        <div style={{ textAlign: 'center' }}>
                            <div style={{ fontSize: 24, fontWeight: 700, color: '#1f2937' }}>
                                {pct}%
                            </div>
                        </div>
                    )}
                />
            </div>
            {showLabel && (
                <Text style={{ 
                    fontSize: 14, 
                    fontWeight: 500, 
                    color: '#4b5563',
                    display: 'block',
                    marginTop: 12
                }}>
                    {title}
                </Text>
            )}
        </div>
    );
}

// Container status with resource usage
function ContainerCard({ container, onRestart }: { container: any; onRestart: (name: string) => void }) {
    const isHealthy = container.status === 'running' || container.healthy;
    
    return (
        <Card
            size="small"
            style={{ 
                borderRadius: 12,
                border: isHealthy ? '1px solid #10b98130' : '1px solid #ef444430'
            }}
            bodyStyle={{ padding: 16 }}
        >
            <Space direction="vertical" size={8} style={{ width: '100%' }}>
                <Space>
                    <Badge 
                        status={isHealthy ? 'success' : 'error'} 
                    />
                    <Text strong style={{ fontSize: 14 }}>{container.name}</Text>
                    <Tag color={isHealthy ? 'green' : 'red'} style={{ marginLeft: 'auto' }}>
                        {container.status}
                    </Tag>
                </Space>
                
                <Text type="secondary" style={{ fontSize: 11 }} ellipsis>
                    {container.image}
                </Text>
                
                <Row gutter={8}>
                    <Col span={12}>
                        <Text type="secondary" style={{ fontSize: 10 }}>CPU</Text>
                        <Progress 
                            percent={container.cpu || 0} 
                            size="small" 
                            showInfo={false}
                            strokeColor={container.cpu > 80 ? '#ef4444' : '#3b82f6'}
                        />
                    </Col>
                    <Col span={12}>
                        <Text type="secondary" style={{ fontSize: 10 }}>Memory</Text>
                        <Progress 
                            percent={container.memory || 0} 
                            size="small" 
                            showInfo={false}
                            strokeColor={container.memory > 80 ? '#ef4444' : '#8b5cf6'}
                        />
                    </Col>
                </Row>
                
                <Button 
                    icon={<RedoOutlined />} 
                    size="small" 
                    block
                    onClick={() => onRestart(container.name)}
                    disabled={!isHealthy}
                >
                    Restart
                </Button>
            </Space>
        </Card>
    );
}

export default function InfraPage() {
    const [refreshing, setRefreshing] = useState(false);
    const queryClient = useQueryClient();

    const { data, isLoading, error, refetch, dataUpdatedAt } = useQuery<InfraData>({
        queryKey: ['admin-infra'],
        queryFn: adminAnalytics.infra,
        refetchInterval: 30_000,
    });

    const containerAction = useMutation({
        mutationFn: ({ action, container }: { action: string; container: string }) => {
            if (action === 'restart') return adminOperations.restartContainer(container);
            if (action === 'stop') return adminOperations.stopContainer(container);
            return Promise.resolve();
        },
        onSuccess: () => {
            message.success('Container restarted successfully');
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

    const handleRestart = useCallback((containerName: string) => {
        containerAction.mutate({ action: 'restart', container: containerName });
    }, [containerAction]);

    const lastUpdated = dataUpdatedAt ? dayjs(dataUpdatedAt).fromNow() : '—';

    if (isLoading && !data) {
        return (
            <div style={{ padding: 24 }}>
                <Skeleton active paragraph={{ rows: 4 }} />
                <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
                    <Col span={6}><Skeleton active /></Col>
                    <Col span={6}><Skeleton active /></Col>
                    <Col span={6}><Skeleton active /></Col>
                    <Col span={6}><Skeleton active /></Col>
                </Row>
            </div>
        );
    }

    if (error && !data) {
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

    const { database, disk, memory, redis, docker } = data!;

    // Chart data
    const tableSizeData = database?.topTables?.slice(0, 8).map((t: any) => ({
        name: t.table.length > 20 ? t.table.substring(0, 20) + '...' : t.table,
        rows: t.rows,
    })) || [];

    return (
        <div style={{ background: '#f8fafc', minHeight: '100vh', padding: 24 }}>
            <style>{`
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.6; }
                }
                .infra-card { 
                    transition: all 0.3s ease; 
                    border-radius: 16px;
                }
                .infra-card:hover { 
                    transform: translateY(-4px); 
                    box-shadow: 0 8px 24px rgba(0,0,0,0.08); 
                }
                .gradient-text {
                    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }
            `}</style>

            {/* Header */}
            <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center', 
                marginBottom: 24,
                background: 'white',
                padding: '20px 24px',
                borderRadius: 16,
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
            }}>
                <div>
                    <Title level={3} style={{ margin: 0, display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div style={{
                            width: 40,
                            height: 40,
                            borderRadius: 10,
                            background: 'linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: 'white'
                        }}>
                            <DashboardOutlined />
                        </div>
                        <span className="gradient-text">Infrastructure Dashboard</span>
                    </Title>
                    <Text type="secondary">
                        Real-time monitoring • Auto-refreshes every 30s • Updated {lastUpdated}
                    </Text>
                </div>
                <Space>
                    <Tag color="blue" icon={<ClusterOutlined />}>
                        {docker?.containers?.length || 0} Services
                    </Tag>
                    <Tag color={database?.status === 'healthy' ? 'green' : 'red'} icon={<DatabaseOutlined />}>
                        PostgreSQL {database?.status}
                    </Tag>
                    <Button 
                        icon={<ReloadOutlined spin={refreshing} />} 
                        onClick={handleRefresh} 
                        loading={refreshing}
                        type="primary"
                    >
                        Refresh
                    </Button>
                </Space>
            </div>

            {/* Quick Stats Row */}
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Database Size"
                        value={database?.size || 'N/A'}
                        icon={<DatabaseOutlined style={{ color: '#6366f1', fontSize: 20 }} />}
                        color="#6366f1"
                        subtitle={`${database?.activeConnections || 0} active connections`}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Memory Usage"
                        value={memory?.usedPercent || 0}
                        suffix="%"
                        icon={<ThunderboltOutlined style={{ color: '#f59e0b', fontSize: 20 }} />}
                        color="#f59e0b"
                        subtitle={`${memory?.usedMB}MB / ${memory?.totalMB}MB`}
                        trend={2}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Disk Usage"
                        value={parseInt(disk?.usedPercent) || 0}
                        suffix="%"
                        icon={<HddOutlined style={{ color: '#06b6d4', fontSize: 20 }} />}
                        color="#06b6d4"
                        subtitle={`${disk?.used} / ${disk?.total}`}
                    />
                </Col>
                <Col xs={24} sm={12} lg={6}>
                    <StatCard
                        title="Redis Uptime"
                        value={redis?.uptimeSeconds ? Math.round(parseInt(redis.uptimeSeconds) / 86400) : 0}
                        suffix="d"
                        icon={<CloudServerOutlined style={{ color: '#ec4899', fontSize: 20 }} />}
                        color="#ec4899"
                        subtitle={`v${redis?.version || 'N/A'}`}
                    />
                </Col>
            </Row>

            {/* Main Content */}
            <Row gutter={[16, 16]}>
                {/* Database Overview */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <Space>
                                <div style={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: 8,
                                    background: '#6366f115',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    <DatabaseOutlined style={{ color: '#6366f1' }} />
                                </div>
                                <span>PostgreSQL Database</span>
                            </Space>
                        }
                        extra={<HealthBadge status={database?.status} showPulse />}
                        className="infra-card"
                    >
                        {database?.status === 'healthy' ? (
                            <Row gutter={[16, 16]}>
                                <Col span={8}>
                                    <Statistic 
                                        title="Database Size" 
                                        value={database.size} 
                                        valueStyle={{ fontSize: 20, color: '#6366f1' }}
                                    />
                                </Col>
                                <Col span={8}>
                                    <Statistic 
                                        title="Active Connections" 
                                        value={database.activeConnections} 
                                        suffix="/ 100"
                                        valueStyle={{ fontSize: 20 }}
                                    />
                                </Col>
                                <Col span={8}>
                                    <Statistic 
                                        title="Longest Query" 
                                        value={database.longestQuerySeconds?.toFixed(2)} 
                                        suffix="s"
                                        valueStyle={{ 
                                            fontSize: 20, 
                                            color: database.longestQuerySeconds > 5 ? '#ef4444' : '#10b981' 
                                        }}
                                    />
                                </Col>
                                
                                <Col span={24}>
                                    <Divider style={{ margin: '12px 0' }} />
                                    <Text strong style={{ fontSize: 12, color: '#6b7280' }}>
                                        TOP TABLES BY ROW COUNT
                                    </Text>
                                    <div style={{ height: 220, marginTop: 12 }}>
                                        <ResponsiveContainer width="100%" height="100%">
                                            <BarChart data={tableSizeData} layout="vertical" margin={{ left: 10 }}>
                                                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                                                <XAxis type="number" stroke="#9ca3af" fontSize={10} />
                                                <YAxis 
                                                    dataKey="name" 
                                                    type="category" 
                                                    width={120} 
                                                    style={{ fontSize: 10 }}
                                                    tick={{ fill: '#6b7280' }}
                                                />
                                                <RechartTooltip 
                                                    contentStyle={{ 
                                                        borderRadius: 8, 
                                                        border: 'none', 
                                                        boxShadow: '0 4px 12px rgba(0,0,0,0.1)' 
                                                    }}
                                                />
                                                <Bar 
                                                    dataKey="rows" 
                                                    fill="#6366f1" 
                                                    radius={[0, 6, 6, 0]} 
                                                />
                                            </BarChart>
                                        </ResponsiveContainer>
                                    </div>
                                </Col>
                            </Row>
                        ) : (
                            <Alert type="error" message="Database unavailable" description={database?.error} showIcon />
                        )}
                    </Card>
                </Col>

                {/* System Resources */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <Space>
                                <div style={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: 8,
                                    background: '#f59e0b15',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    <ThunderboltOutlined style={{ color: '#f59e0b' }} />
                                </div>
                                <span>System Resources</span>
                            </Space>
                        }
                        className="infra-card"
                    >
                        <Row gutter={[24, 24]} align="middle">
                            <Col xs={24} sm={8}>
                                <ResourceGauge
                                    percent={memory?.usedPercent || 0}
                                    title="Memory"
                                    color="#f59e0b"
                                />
                            </Col>
                            <Col xs={24} sm={16}>
                                <Descriptions column={1} size="small" bordered>
                                    <Descriptions.Item label="Total">{memory?.totalMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Used">{memory?.usedMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Free">{memory?.freeMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Node.js RSS">{memory?.processRssMB} MB</Descriptions.Item>
                                </Descriptions>
                            </Col>
                            
                            <Col span={24}>
                                <Divider style={{ margin: '12px 0' }} />
                                <Text strong style={{ fontSize: 12, color: '#6b7280' }}>
                                    DISK (/)
                                </Text>
                                <div style={{ marginTop: 12 }}>
                                    <Progress 
                                        percent={parseInt(disk?.usedPercent) || 0}
                                        strokeColor={parseInt(disk?.usedPercent) > 85 ? '#ef4444' : '#06b6d4'}
                                        trailColor="#e5e7eb"
                                        strokeWidth={12}
                                        showInfo
                                    />
                                    <Row style={{ marginTop: 8 }}>
                                        <Col>
                                            <Text type="secondary" style={{ fontSize: 11 }}>
                                                Used: {disk?.used}
                                            </Text>
                                        </Col>
                                        <Col style={{ marginLeft: 'auto' }}>
                                            <Text type="secondary" style={{ fontSize: 11 }}>
                                                Available: {disk?.available}
                                            </Text>
                                        </Col>
                                    </Row>
                                </div>
                            </Col>
                        </Row>
                    </Card>
                </Col>

                {/* Redis Cache */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <Space>
                                <div style={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: 8,
                                    background: '#ec489915',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    <CloudServerOutlined style={{ color: '#ec4899' }} />
                                </div>
                                <span>Redis Cache</span>
                            </Space>
                        }
                        extra={<HealthBadge status={redis?.status} />}
                        className="infra-card"
                    >
                        {redis?.status === 'healthy' ? (
                            <Row gutter={[16, 16]}>
                                <Col span={12}>
                                    <Statistic 
                                        title="Version" 
                                        value={redis.version} 
                                        valueStyle={{ fontSize: 18 }}
                                    />
                                </Col>
                                <Col span={12}>
                                    <Statistic 
                                        title="Memory" 
                                        value={redis.usedMemoryHuman} 
                                        valueStyle={{ fontSize: 18 }}
                                    />
                                </Col>
                                <Col span={12}>
                                    <Statistic 
                                        title="Connected Clients" 
                                        value={redis.connectedClients} 
                                        valueStyle={{ fontSize: 18 }}
                                    />
                                </Col>
                                <Col span={12}>
                                    <Statistic 
                                        title="Commands/sec" 
                                        value={Math.round(redis.totalCommandsProcessed / 3600).toLocaleString()} 
                                        valueStyle={{ fontSize: 18 }}
                                    />
                                </Col>
                            </Row>
                        ) : (
                            <Alert type="error" message="Redis unavailable" description={redis?.error} showIcon />
                        )}
                    </Card>
                </Col>

                {/* Docker Containers */}
                <Col xs={24} lg={12}>
                    <Card
                        title={
                            <Space>
                                <div style={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: 8,
                                    background: '#10b98115',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    <ContainerOutlined style={{ color: '#10b981' }} />
                                </div>
                                <span>Docker Containers</span>
                                <Badge 
                                    count={docker?.containers?.length || 0} 
                                    style={{ backgroundColor: '#6366f1' }} 
                                />
                            </Space>
                        }
                        className="infra-card"
                    >
                        {docker?.status === 'unavailable' ? (
                            <Empty description="Docker not available" />
                        ) : (
                            <Row gutter={[12, 12]}>
                                {docker?.containers?.slice(0, 6).map((c: any) => (
                                    <Col xs={24} sm={12} key={c.name}>
                                        <ContainerCard 
                                            container={c} 
                                            onRestart={handleRestart}
                                        />
                                    </Col>
                                ))}
                            </Row>
                        )}
                    </Card>
                </Col>
            </Row>

            {/* Alerts */}
            {(memory?.usedPercent > 85 || parseInt(disk?.usedPercent) > 85 || database?.longestQuerySeconds > 5) && (
                <Alert
                    type="warning"
                    message="Action Recommended"
                    description={
                        <ul style={{ margin: 0, paddingLeft: 20 }}>
                            {memory?.usedPercent > 85 && <li>Memory usage is high ({memory.usedPercent}%)</li>}
                            {parseInt(disk?.usedPercent) > 85 && <li>Disk space is running low ({disk.usedPercent})</li>}
                            {database?.longestQuerySeconds > 5 && <li>Slow database query detected ({database.longestQuerySeconds}s)</li>}
                        </ul>
                    }
                    showIcon
                    icon={<WarningOutlined />}
                    style={{ marginTop: 24, borderRadius: 12 }}
                    action={
                        <Button size="small" onClick={handleRefresh}>
                            Refresh Now
                        </Button>
                    }
                />
            )}
        </div>
    );
}
