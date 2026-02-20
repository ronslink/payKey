import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Space, Input, Card, Statistic, Row, Col, Spin } from 'antd';
import { FileTextOutlined, ReloadOutlined, SearchOutlined, BugOutlined, InfoCircleOutlined, WarningOutlined, ContainerOutlined } from '@ant-design/icons';
import { useState, useEffect } from 'react';
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
    container: string;
    lines: number;
}

export default function LogsPage() {
    const [page, setPage] = useState(1);
    const [level, setLevel] = useState<string>();
    const [search, setSearch] = useState<string>();
    const [searchInput, setSearchInput] = useState<string>();
    const [selectedContainer, setSelectedContainer] = useState<string>();

    // Fetch available containers
    const { data: containersData } = useQuery({
        queryKey: ['admin-containers'],
        queryFn: () => adminLogs.containers(),
        refetchInterval: 30000,
    });

    // Fetch logs
    const { data, isLoading, refetch } = useQuery<LogsResponse>({
        queryKey: ['admin-logs', selectedContainer, page, level, search],
        queryFn: () => {
            // Get raw logs (no filtering by level/search on backend yet)
            return adminLogs.list({ container: selectedContainer, lines: 500 });
        },
        refetchInterval: 30000,
    });

    // Client-side filtering
    const filteredLogs = data?.data?.filter((log: LogEntry) => {
        if (level && log.level !== level) return false;
        if (search && !log.message.toLowerCase().includes(search.toLowerCase())) return false;
        return true;
    }) || [];

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
    const errorCount = filteredLogs.filter((log: LogEntry) => log.level === 'ERROR').length;
    const warnCount = filteredLogs.filter((log: LogEntry) => log.level === 'WARN').length;
    const infoCount = filteredLogs.filter((log: LogEntry) => log.level === 'INFO').length;

    const handleSearch = () => {
        setSearch(searchInput);
        setPage(1);
    };

    const handleClear = () => {
        setSearchInput('');
        setSearch(undefined);
        setLevel(undefined);
        setSelectedContainer(undefined);
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
                            value={filteredLogs.length}
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
                        placeholder="Select Container"
                        allowClear
                        style={{ width: 200 }}
                        onChange={(value) => {
                            setSelectedContainer(value);
                            setPage(1);
                        }}
                        value={selectedContainer}
                        suffixIcon={<ContainerOutlined />}
                    >
                        {(containersData?.data || []).map((c: any) => (
                            <Select.Option key={c.name} value={c.name}>
                                {c.name} ({c.status})
                            </Select.Option>
                        ))}
                    </Select>

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
                dataSource={filteredLogs.slice(0, 100)}
                rowKey={(record: LogEntry, index?: number) => `${record.timestamp}-${index || 0}`}
                loading={isLoading}
                pagination={{
                    total: filteredLogs.length,
                    pageSize: 100,
                    current: page,
                    onChange: setPage,
                    showSizeChanger: false,
                    showTotal: (total) => `Showing ${Math.min(total, 100)} of ${total} logs`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
                scroll={{ y: 600 }}
                size="small"
            />
        </div>
    );
}
