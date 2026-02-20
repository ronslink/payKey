import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Space, Input, Card, Statistic, Row, Col } from 'antd';
import { FileTextOutlined, ReloadOutlined, SearchOutlined, BugOutlined, InfoCircleOutlined, WarningOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminLogs } from '../api/client';

const { Title, Text } = Typography;

interface LogEntry {
    timestamp: string;
    level: string;
    message: string;
    raw: string;
}

interface LogsResponse {
    data: LogEntry[];
    total: number;
    page: number;
    limit: number;
}

export default function LogsPage() {
    const [page, setPage] = useState(1);
    const [level, setLevel] = useState<string>();
    const [search, setSearch] = useState<string>();
    const [searchInput, setSearchInput] = useState<string>();

    const { data, isLoading, refetch } = useQuery<LogsResponse>({
        queryKey: ['admin-logs', page, level, search],
        queryFn: () => adminLogs.list({ page, level, search, limit: 100 }),
        refetchInterval: 30000, // Auto-refresh every 30 seconds
    });

    const levelColors: Record<string, string> = {
        ERROR: 'red',
        WARN: 'orange',
        INFO: 'blue',
        DEBUG: 'default',
        VERBOSE: 'default',
        LOG: 'blue',
    };

    const levelIcons: Record<string, React.ReactNode> = {
        ERROR: <BugOutlined />,
        WARN: <WarningOutlined />,
        INFO: <InfoCircleOutlined />,
        DEBUG: <FileTextOutlined />,
        VERBOSE: <FileTextOutlined />,
        LOG: <FileTextOutlined />,
    };

    // Calculate statistics
    const errorCount = data?.data?.filter((log: LogEntry) => log.level === 'ERROR').length || 0;
    const warnCount = data?.data?.filter((log: LogEntry) => log.level === 'WARN').length || 0;
    const infoCount = data?.data?.filter((log: LogEntry) => log.level === 'INFO').length || 0;

    const handleSearch = () => {
        setSearch(searchInput);
        setPage(1);
    };

    const handleClear = () => {
        setSearchInput('');
        setSearch(undefined);
        setPage(1);
    };

    const columns = [
        {
            title: 'Timestamp',
            dataIndex: 'timestamp',
            key: 'timestamp',
            width: 180,
            render: (v: string) => {
                if (!v) return '—';
                try {
                    const date = new Date(v);
                    return date.toLocaleString();
                } catch {
                    return v;
                }
            },
        },
        {
            title: 'Level',
            dataIndex: 'level',
            key: 'level',
            width: 100,
            render: (v: string) => (
                <Tag color={levelColors[v] || 'default'} icon={levelIcons[v]}>
                    {v}
                </Tag>
            ),
        },
        {
            title: 'Message',
            dataIndex: 'message',
            key: 'message',
            render: (v: string) => (
                <Text
                    style={{
                        fontFamily: 'monospace',
                        fontSize: 12,
                        maxWidth: 800,
                        display: 'block',
                        wordBreak: 'break-word',
                    }}
                >
                    {v}
                </Text>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, alignItems: 'center' }}>
                <Title level={3} style={{ margin: 0 }}>Application Logs</Title>
                <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
                    Refresh
                </Button>
            </div>

            {/* Statistics Cards */}
            <Row gutter={16} style={{ marginBottom: 24 }}>
                <Col span={6}>
                    <Card>
                        <Statistic
                            title="Total Logs"
                            value={data?.total || 0}
                            prefix={<FileTextOutlined />}
                            valueStyle={{ color: '#1890ff' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card>
                        <Statistic
                            title="Errors"
                            value={errorCount}
                            prefix={<BugOutlined />}
                            valueStyle={{ color: '#ff4d4f' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card>
                        <Statistic
                            title="Warnings"
                            value={warnCount}
                            prefix={<WarningOutlined />}
                            valueStyle={{ color: '#faad14' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card>
                        <Statistic
                            title="Info"
                            value={infoCount}
                            prefix={<InfoCircleOutlined />}
                            valueStyle={{ color: '#52c41a' }}
                        />
                    </Card>
                </Col>
            </Row>

            {/* Filters */}
            <Card style={{ marginBottom: 24 }}>
                <Space size="middle" wrap>
                    <Select
                        placeholder="Filter by Level"
                        allowClear
                        style={{ width: 150 }}
                        onChange={(value) => {
                            setLevel(value);
                            setPage(1);
                        }}
                        value={level}
                    >
                        <Select.Option value="ERROR">ERROR</Select.Option>
                        <Select.Option value="WARN">WARN</Select.Option>
                        <Select.Option value="INFO">INFO</Select.Option>
                        <Select.Option value="DEBUG">DEBUG</Select.Option>
                        <Select.Option value="LOG">LOG</Select.Option>
                    </Select>

                    <Input
                        placeholder="Search logs..."
                        prefix={<SearchOutlined />}
                        style={{ width: 300 }}
                        value={searchInput}
                        onChange={(e) => setSearchInput(e.target.value)}
                        onPressEnter={handleSearch}
                        allowClear
                    />

                    <Button type="primary" onClick={handleSearch}>
                        Search
                    </Button>
                    <Button onClick={handleClear}>
                        Clear
                    </Button>

                    <Button
                        danger
                        onClick={() => {
                            setLevel('ERROR');
                            setPage(1);
                        }}
                    >
                        Show Errors Only
                    </Button>
                </Space>
            </Card>

            {/* Logs Table */}
            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey={(record: LogEntry, index?: number) => `${record.timestamp}-${index || 0}`}
                loading={isLoading}
                pagination={{
                    total: data?.total,
                    pageSize: 100,
                    current: page,
                    onChange: setPage,
                    showSizeChanger: false,
                    showTotal: (total) => `Total ${total} logs`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
                scroll={{ y: 600 }}
                size="small"
            />
        </div>
    );
}
