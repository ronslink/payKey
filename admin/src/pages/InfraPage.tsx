import { useQuery } from '@tanstack/react-query';
import { Row, Col, Card, Tag, Typography, Spin, Alert, Progress, List } from 'antd';
import {
    DatabaseOutlined,
    HddOutlined,
    CloudServerOutlined,
    ThunderboltOutlined,
} from '@ant-design/icons';
import { adminAnalytics } from '../api/client';

const { Title, Text } = Typography;

function HealthBadge({ status }: { status: string }) {
    const healthy = ['healthy', 'ok'].includes(status?.toLowerCase());
    return (
        <Tag color={healthy ? 'green' : status === 'unavailable' ? 'default' : 'red'}>
            {status?.toUpperCase()}
        </Tag>
    );
}

export default function InfraPage() {
    const { data, isLoading, error } = useQuery({
        queryKey: ['admin-infra'],
        queryFn: adminAnalytics.infra,
        refetchInterval: 30_000, // Auto-refresh every 30s
    });

    if (isLoading) return <Spin size="large" style={{ display: 'block', marginTop: 100, textAlign: 'center' }} />;
    if (error) return <Alert type="error" title="Failed to load infra data" />;

    const { database, disk, memory, redis, docker, timestamp } = data;

    return (
        <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
                <Title level={3} style={{ margin: 0 }}>Infrastructure Health</Title>
                <Text type="secondary">Auto-refreshes every 30s · Last: {new Date(timestamp).toLocaleTimeString()}</Text>
            </div>

            <Row gutter={[16, 16]}>
                {/* Database */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<><DatabaseOutlined /> PostgreSQL</>}
                        extra={<HealthBadge status={database.status} />}
                        style={{ borderRadius: 12 }}
                    >
                        {database.status === 'healthy' ? (
                            <>
                                <p><strong>DB Size:</strong> {database.size}</p>
                                <p><strong>Active Connections:</strong> {database.activeConnections}</p>
                                <p><strong>Longest Query:</strong> {database.longestQuerySeconds?.toFixed(1)}s</p>
                                <Title level={5} style={{ marginTop: 16, marginBottom: 8 }}>Top Tables (by rows)</Title>
                                <List
                                    size="small"
                                    dataSource={database.topTables}
                                    renderItem={(t: any) => (
                                        <List.Item style={{ padding: '4px 0' }}>
                                            <Text code>{t.table}</Text>
                                            <Text type="secondary">{t.rows.toLocaleString()} rows</Text>
                                        </List.Item>
                                    )}
                                />
                            </>
                        ) : (
                            <Alert type="error" title={database.error} />
                        )}
                    </Card>
                </Col>

                {/* Memory */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<><ThunderboltOutlined /> Memory</>}
                        style={{ borderRadius: 12 }}
                    >
                        <Progress
                            percent={memory.usedPercent}
                            strokeColor={memory.usedPercent > 85 ? '#ef4444' : '#6366f1'}
                            style={{ marginBottom: 16 }}
                        />
                        <p><strong>Total:</strong> {memory.totalMB} MB</p>
                        <p><strong>Used:</strong> {memory.usedMB} MB</p>
                        <p><strong>Free:</strong> {memory.freeMB} MB</p>
                        <p><strong>Node.js Process RSS:</strong> {memory.processRssMB} MB</p>
                    </Card>
                </Col>

                {/* Disk */}
                <Col xs={24} lg={12}>
                    <Card
                        title={<><HddOutlined /> Disk (/)</>}
                        style={{ borderRadius: 12 }}
                    >
                        <Progress
                            percent={parseInt(disk.usedPercent) || 0}
                            strokeColor={parseInt(disk.usedPercent) > 85 ? '#ef4444' : '#06b6d4'}
                            format={() => disk.usedPercent}
                            style={{ marginBottom: 16 }}
                        />
                        <p><strong>Total:</strong> {disk.total}</p>
                        <p><strong>Used:</strong> {disk.used}</p>
                        <p><strong>Available:</strong> {disk.available}</p>
                    </Card>
                </Col>

                {/* Redis */}
                <Col xs={24} lg={12}>
                    <Card
                        title="Redis"
                        extra={<HealthBadge status={redis.status} />}
                        style={{ borderRadius: 12 }}
                    >
                        {redis.status === 'healthy' ? (
                            <>
                                <p><strong>Version:</strong> {redis.version}</p>
                                <p><strong>Memory Used:</strong> {redis.usedMemoryHuman}</p>
                                <p><strong>Connected Clients:</strong> {redis.connectedClients}</p>
                                <p><strong>Commands Processed:</strong> {redis.totalCommandsProcessed}</p>
                                <p><strong>Uptime:</strong> {Math.round((parseInt(redis.uptimeSeconds) || 0) / 3600)}h</p>
                            </>
                        ) : (
                            <Alert type="error" title={redis.error} />
                        )}
                    </Card>
                </Col>

                {/* Docker */}
                <Col xs={24}>
                    <Card
                        title={<><CloudServerOutlined /> Docker Containers</>}
                        extra={<HealthBadge status={docker.status} />}
                        style={{ borderRadius: 12 }}
                    >
                        {docker.status === 'unavailable' ? (
                            <Text type="secondary">Docker info not available (running in non-docker env or permission denied)</Text>
                        ) : (
                            <List
                                dataSource={docker.containers}
                                renderItem={(c: any) => (
                                    <List.Item>
                                        <Text strong>{c.name}</Text>
                                        <div>
                                            <Text type="secondary" style={{ marginRight: 8 }}>{c.image}</Text>
                                            <Tag color={c.healthy ? 'green' : 'red'}>{c.status}</Tag>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        )}
                    </Card>
                </Col>
            </Row>
        </div>
    );
}
