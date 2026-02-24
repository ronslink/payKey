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

// Compact health badge
function HealthBadge({ status }: { status: string }) {
    const normalized = status?.toLowerCase();
    const healthy = ['healthy', 'ok', 'running', 'up'].includes(normalized);
    const unavailable = normalized === 'unavailable' || normalized === 'down';
    
    let color = 'green';
    let icon = <CheckCircleOutlined />;
    
    if (unavailable) {
        color = 'default';
        icon = <ClockCircleOutlined />;
    } else if (!healthy) {
        color = 'red';
        icon = <ExclamationCircleOutlined />;
    }

    return (
        <Badge
            status={color as any}
            text={<Tag color={color} icon={icon}>{status?.toUpperCase()}</Tag>}
        />
    );
}

// Compact stat card
function StatCard({ title, value, suffix, icon, color, subtitle }: any) {
    return (
        <Card 
            bordered={false} 
            style={{ 
                background: `linear-gradient(135deg, ${color}10 0%, ${color}05 100%)`, 
                borderRadius: 12,
                border: `1px solid ${color}20`
            }}
            bodyStyle={{ padding: 16 }}
        >
            <Space align="start">
                <div style={{
                    width: 36,
                    height: 36,
                    borderRadius: 8,
                    background: `${color}15`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                }}>
                    {icon}
                </div>
                <div style={{ flex: 1 }}>
                    <Text type="secondary" style={{ fontSize: 11, textTransform: 'uppercase' }}>
                        {title}
                    </Text>
                    <div style={{ fontSize: 22, fontWeight: 700, color: '#1f2937', lineHeight: 1.2 }}>
                        {value}{suffix}
                    </div>
                    {subtitle && (
                        <Text type="secondary" style={{ fontSize: 10 }}>{subtitle}</Text>
                    )}
                </div>
            </Space>
        </Card>
    );
}

// Compact circular gauge
function ResourceGauge({ percent, title, color }: { percent: number; title: string; color: string }) {
    const getColor = () => {
        if (percent > 90) return '#ef4444';
        if (percent > 75) return '#f59e0b';
        if (percent > 50) return '#3b82f6';
        return color || '#10b981';
    };

    return (
        <div style={{ textAlign: 'center', padding: 8 }}>
            <Progress
                type="circle"
                percent={percent}
                strokeColor={getColor()}
                width={80}
                strokeWidth={8}
                trailColor="#e5e7eb"
                format={(pct) => (
                    <span style={{ fontSize: 16, fontWeight: 700, color: '#1f2937' }}>{pct}%</span>
                )}
            />
            <div style={{ fontSize: 11, fontWeight: 500, color: '#4b5563', marginTop: 8 }}>{title}</div>
        </div>
    );
}

// Compact container card
function ContainerCard({ container, onRestart }: { container: any; onRestart: (name: string) => void }) {
    const isHealthy = container.status === 'running' || container.healthy;
    
    return (
        <Card
            size="small"
            style={{ 
                borderRadius: 8,
                border: isHealthy ? '1px solid #10b98130' : '1px solid #ef444430'
            }}
            bodyStyle={{ padding: 12 }}
        >
            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                <Space>
                    <Badge status={isHealthy ? 'success' : 'error'} />
                    <Text strong style={{ fontSize: 12 }}>{container.name}</Text>
                </Space>
                <Tag color={isHealthy ? 'green' : 'red'} style={{ margin: 0 }}>{container.status}</Tag>
            </Space>
            <div style={{ marginTop: 8 }}>
                <Row gutter={8}>
                    <Col span={12}>
                        <Text type="secondary" style={{ fontSize: 9 }}>CPU</Text>
                        <Progress 
                            percent={container.cpu || 0} 
                            size="small" 
                            showInfo={false}
                            strokeColor={container.cpu > 80 ? '#ef4444' : '#3b82f6'}
                        />
                    </Col>
                    <Col span={12}>
                        <Text type="secondary" style={{ fontSize: 9 }}>MEM</Text>
                        <Progress 
                            percent={container.memory || 0} 
                            size="small" 
                            showInfo={false}
                            strokeColor={container.memory > 80 ? '#ef4444' : '#8b5cf6'}
                        />
                    </Col>
                </Row>
            </div>
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
            return Promise.resolve();
        },
        onSuccess: () => {
            message.success('Container restarted');
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
            <div style={{ padding: 16 }}>
                <Skeleton active paragraph={{ rows: 4 }} />
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
                action={<Button icon={<ReloadOutlined />} onClick={() => refetch()}>Retry</Button>}
            />
        );
    }

    const { database, disk, memory, redis, docker } = data!;

    const tableSizeData = database?.topTables?.slice(0, 6).map((t: any) => ({
        name: t.table.length > 15 ? t.table.substring(0, 15) + '...' : t.table,
        rows: t.rows,
    })) || [];

    return (
        <div style={{ background: '#f8fafc', minHeight: '100vh', padding: 16 }}>
            <style>{`
                .infra-card { transition: all 0.2s ease; border-radius: 12px; }
                .infra-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
            `}</style>

            {/* Header */}
            <div style={{ 
                display: 'flex', 
                justifyContent: 'space-between', 
                alignItems: 'center', 
                marginBottom: 16,
                background: 'white',
                padding: '12px 16px',
                borderRadius: 12,
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
            }}>
                <div>
                    <Title level={4} style={{ margin: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
                        <DashboardOutlined /> Infrastructure
                    </Title>
                    <Text type="secondary" style={{ fontSize: 11 }}>Updated {lastUpdated}</Text>
                </div>
                <Space>
                    <Tag color="blue"><ClusterOutlined /> {docker?.containers?.length || 0} Services</Tag>
                    <Tag color={database?.status === 'healthy' ? 'green' : 'red'}>{database?.status}</Tag>
                    <Button onClick={handleRefresh} loading={refreshing} size="small">Refresh</Button>
                </Space>
            </div>

            {/* Quick Stats */}
            <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
                <Col xs={12} sm={6}>
                    <StatCard title="Database" value={database?.size || 'N/A'} icon={<DatabaseOutlined style={{ color: '#6366f1', fontSize: 16 }} />} color="#6366f1" subtitle={`${database?.activeConnections || 0} conns`} />
                </Col>
                <Col xs={12} sm={6}>
                    <StatCard title="Memory" value={memory?.usedPercent || 0} suffix="%" icon={<ThunderboltOutlined style={{ color: '#f59e0b', fontSize: 16 }} />} color="#f59e0b" subtitle={`${memory?.usedMB}MB`} />
                </Col>
                <Col xs={12} sm={6}>
                    <StatCard title="Disk" value={parseInt(disk?.usedPercent) || 0} suffix="%" icon={<HddOutlined style={{ color: '#06b6d4', fontSize: 16 }} />} color="#06b6d4" subtitle={disk?.used} />
                </Col>
                <Col xs={12} sm={6}>
                    <StatCard title="Redis Up" value={redis?.uptimeSeconds ? Math.round(parseInt(redis.uptimeSeconds) / 86400) : 0} suffix="d" icon={<CloudServerOutlined style={{ color: '#ec4899', fontSize: 16 }} />} color="#ec4899" subtitle={`v${redis?.version || 'N/A'}`} />
                </Col>
            </Row>

            {/* Main Grid - 2 columns */}
            <Row gutter={[12, 12]}>
                {/* Database */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<Space><DatabaseOutlined style={{ color: '#6366f1' }} /><span>PostgreSQL</span></Space>}
                        extra={<HealthBadge status={database?.status} />}
                        size="small"
                        className="infra-card"
                    >
                        {database?.status === 'healthy' ? (
                            <Row gutter={[8, 12]}>
                                <Col span={8}><Statistic title="Size" value={database.size} valueStyle={{ fontSize: 16 }} /></Col>
                                <Col span={8}><Statistic title="Connections" value={database.activeConnections} suffix="/100" valueStyle={{ fontSize: 16 }} /></Col>
                                <Col span={8}><Statistic title="Slow Query" value={database.longestQuerySeconds?.toFixed(2)} suffix="s" valueStyle={{ fontSize: 16, color: database.longestQuerySeconds > 5 ? '#ef4444' : '#10b981' }} /></Col>
                                <Col span={24}>
                                    <Text strong style={{ fontSize: 10, color: '#6b7280' }}>TOP TABLES</Text>
                                    <div style={{ height: 140, marginTop: 8 }}>
                                        <ResponsiveContainer width="100%" height="100%">
                                            <BarChart data={tableSizeData} layout="vertical" margin={{ left: 5 }}>
                                                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                                                <XAxis type="number" stroke="#9ca3af" fontSize={9} />
                                                <YAxis dataKey="name" type="category" width={80} style={{ fontSize: 9 }} tick={{ fill: '#6b7280' }} />
                                                <RechartTooltip contentStyle={{ borderRadius: 6, border: 'none', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }} />
                                                <Bar dataKey="rows" fill="#6366f1" radius={[0, 4, 4, 0]} />
                                            </BarChart>
                                        </ResponsiveContainer>
                                    </div>
                                </Col>
                            </Row>
                        ) : (
                            <Alert type="error" message="Database unavailable" />
                        )}
                    </Card>
                </Col>

                {/* System Resources */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<Space><ThunderboltOutlined style={{ color: '#f59e0b' }} /><span>System</span></Space>}
                        size="small"
                        className="infra-card"
                    >
                        <Row gutter={[8, 8]} align="middle">
                            <Col xs={12} sm={6}>
                                <ResourceGauge percent={memory?.usedPercent || 0} title="Memory" color="#f59e0b" />
                            </Col>
                            <Col xs={12} sm={18}>
                                <Descriptions column={2} size="small" bordered>
                                    <Descriptions.Item label="Total">{memory?.totalMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Used">{memory?.usedMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Free">{memory?.freeMB} MB</Descriptions.Item>
                                    <Descriptions.Item label="Node RSS">{memory?.processRssMB} MB</Descriptions.Item>
                                </Descriptions>
                            </Col>
                            <Col span={24}>
                                <Text strong style={{ fontSize: 10, color: '#6b7280' }}>DISK</Text>
                                <Progress 
                                    percent={parseInt(disk?.usedPercent) || 0}
                                    strokeColor={parseInt(disk?.usedPercent) > 85 ? '#ef4444' : '#06b6d4'}
                                    trailColor="#e5e7eb"
                                    strokeWidth={8}
                                    style={{ marginTop: 4 }}
                                />
                                <Space style={{ marginTop: 4 }}>
                                    <Text type="secondary" style={{ fontSize: 10 }}>Used: {disk?.used}</Text>
                                    <Text type="secondary" style={{ fontSize: 10 }}>Available: {disk?.available}</Text>
                                </Space>
                            </Col>
                        </Row>
                    </Card>
                </Col>

                {/* Redis */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<Space><CloudServerOutlined style={{ color: '#ec4899' }} /><span>Redis</span></Space>}
                        extra={<HealthBadge status={redis?.status} />}
                        size="small"
                        className="infra-card"
                    >
                        {redis?.status === 'healthy' ? (
                            <Row gutter={[8, 8]}>
                                <Col span={12}><Statistic title="Version" value={redis.version} valueStyle={{ fontSize: 14 }} /></Col>
                                <Col span={12}><Statistic title="Memory" value={redis.usedMemoryHuman} valueStyle={{ fontSize: 14 }} /></Col>
                                <Col span={12}><Statistic title="Clients" value={redis.connectedClients} valueStyle={{ fontSize: 14 }} /></Col>
                                <Col span={12}><Statistic title="Cmd/sec" value={Math.round(redis.totalCommandsProcessed / 3600).toLocaleString()} valueStyle={{ fontSize: 14 }} /></Col>
                            </Row>
                        ) : (
                            <Alert type="error" message="Redis unavailable" />
                        )}
                    </Card>
                </Col>

                {/* Docker Containers */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<Space><ContainerOutlined style={{ color: '#10b981' }} /><span>Containers</span><Badge count={docker?.containers?.length || 0} /></Space>}
                        size="small"
                        className="infra-card"
                    >
                        {docker?.status === 'unavailable' ? (
                            <Empty description="Docker not available" />
                        ) : (
                            <Row gutter={[8, 8]}>
                                {docker?.containers?.slice(0, 4).map((c: any) => (
                                    <Col xs={24} sm={12} key={c.name}>
                                        <ContainerCard container={c} onRestart={handleRestart} />
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
                        <ul style={{ margin: 0, paddingLeft: 16, fontSize: 12 }}>
                            {memory?.usedPercent > 85 && <li>Memory high ({memory.usedPercent}%)</li>}
                            {parseInt(disk?.usedPercent) > 85 && <li>Disk low ({disk.usedPercent})</li>}
                            {database?.longestQuerySeconds > 5 && <li>Slow query ({database.longestQuerySeconds}s)</li>}
                        </ul>
                    }
                    showIcon
                    style={{ marginTop: 12, borderRadius: 8 }}
                />
            )}
        </div>
    );
}
