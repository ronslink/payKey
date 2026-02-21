import { useQuery } from '@tanstack/react-query';
import { Table, Typography, Select, Tag, Button, Space, Input, Card, Statistic, Row, Col, Badge } from 'antd';
import { FileTextOutlined, ReloadOutlined, SearchOutlined, BugOutlined, InfoCircleOutlined, WarningOutlined, ContainerOutlined } from '@ant-design/icons';
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
    container: string;
    lines: number;
}

const PAGE_SIZE = 50;

export default function LogsPage() {
    const [page, setPage] = useState(1);
    const [level, setLevel] = useState<string>();
    const [search, setSearch] = useState<string>();
    const [searchInput, setSearchInput] = useState<string>();
    const [selectedContainer, setSelectedContainer] = useState<string>();

    const { data: containersData } = useQuery({
        queryKey: ['admin-containers'],
        queryFn: () => adminLogs.containers(),
        refetchInterval: 30000,
    });

    const { data, isLoading, refetch, dataUpdatedAt } = useQuery<LogsResponse>({
        queryKey: ['admin-logs', selectedContainer, level, search],
        queryFn: () => adminLogs.list({ container: selectedContainer, lines: 500, search }),
        refetchInterval: 30000,
    });

    // Client-side filtering for level (backend may not support it yet)
    const filteredLogs = (data?.data || []).filter((log: LogEntry) => {
        if (level && log.level !== level) return false;
        if (search && !log.message.toLowerCase().includes(search.toLowerCase()) && !log.raw?.toLowerCase().includes(search.toLowerCase())) return false;
        return true;
    });

    // Paginate client-side
    const pagedLogs = filteredLogs.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

    const levelColors: Record<string, string> = {
        ERROR: 'red', WARN: 'orange', INFO: 'blue', DEBUG: 'default', VERBOSE: 'default', LOG: 'blue',
    };

    const levelIcons: Record<string, React.ReactNode> = {
        ERROR: <BugOutlined />, WARN: <WarningOutlined />, INFO: <InfoCircleOutlined />,
        DEBUG: <FileTextOutlined />, VERBOSE: <FileTextOutlined />, LOG: <FileTextOutlined />,
    };

    const errorCount = filteredLogs.filter((l: LogEntry) => l.level === 'ERROR').length;
    const warnCount = filteredLogs.filter((l: LogEntry) => l.level === 'WARN').length;
    const infoCount = filteredLogs.filter((l: LogEntry) => l.level === 'INFO' || l.level === 'LOG').length;

    const handleSearch = () => { setSearch(searchInput); setPage(1); };
    const handleClear = () => { setSearchInput(''); setSearch(undefined); setLevel(undefined); setSelectedContainer(undefined); setPage(1); };

    const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : '—';

    const rowClassName = (record: LogEntry) => {
        if (record.level === 'ERROR') return 'log-row-error';
        if (record.level === 'WARN') return 'log-row-warn';
        return '';
    };

    const columns = [
        {
            title: 'Timestamp',
            dataIndex: 'timestamp',
            key: 'timestamp',
            width: 175,
            render: (v: string) => {
                if (!v) return '—';
                try { return new Date(v).toLocaleString(); } catch { return v; }
            },
        },
        {
            title: 'Level',
            dataIndex: 'level',
            key: 'level',
            width: 90,
            render: (v: string) => (
                <Tag color={levelColors[v] || 'default'} icon={levelIcons[v]}>{v}</Tag>
            ),
        },
        {
            title: 'Message',
            dataIndex: 'message',
            key: 'message',
            render: (v: string) => (
                <Text style={{ fontFamily: 'monospace', fontSize: 12, display: 'block', wordBreak: 'break-word' }}>
                    {v}
                </Text>
            ),
        },
    ];

    return (
        <div>
            <style>{`
                .log-row-error td { background: #fff1f0 !important; }
                .log-row-warn td { background: #fffbe6 !important; }
            `}</style>

            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, alignItems: 'center' }}>
                <div>
                    <Title level={3} style={{ margin: 0 }}>Application Logs</Title>
                    <Text type="secondary" style={{ fontSize: 12 }}>Auto-refreshes every 30s · Last updated: {lastUpdated}</Text>
                </div>
                <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
                    Refresh
                </Button>
            </div>

            {/* Statistics Cards */}
            <Row gutter={16} style={{ marginBottom: 24 }}>
                <Col span={6}>
                    <Card style={{ cursor: 'pointer' }} onClick={() => { setLevel(undefined); setPage(1); }}>
                        <Statistic title="Total (filtered)" value={filteredLogs.length} prefix={<FileTextOutlined />} valueStyle={{ color: '#1890ff' }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card style={{ cursor: 'pointer', border: level === 'ERROR' ? '1px solid #ff4d4f' : undefined }} onClick={() => { setLevel('ERROR'); setPage(1); }}>
                        <Statistic title="Errors" value={errorCount} prefix={<BugOutlined />} valueStyle={{ color: '#ff4d4f' }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card style={{ cursor: 'pointer', border: level === 'WARN' ? '1px solid #faad14' : undefined }} onClick={() => { setLevel('WARN'); setPage(1); }}>
                        <Statistic title="Warnings" value={warnCount} prefix={<WarningOutlined />} valueStyle={{ color: '#faad14' }} />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card style={{ cursor: 'pointer', border: level === 'INFO' ? '1px solid #52c41a' : undefined }} onClick={() => { setLevel('INFO'); setPage(1); }}>
                        <Statistic title="Info / Log" value={infoCount} prefix={<InfoCircleOutlined />} valueStyle={{ color: '#52c41a' }} />
                    </Card>
                </Col>
            </Row>

            {/* Filters */}
            <Card style={{ marginBottom: 24 }}>
                <Space size="middle" wrap>
                    <Select
                        placeholder="All Containers"
                        allowClear
                        style={{ width: 220 }}
                        onChange={(value) => { setSelectedContainer(value); setPage(1); }}
                        value={selectedContainer}
                        suffixIcon={<ContainerOutlined />}
                    >
                        {(containersData?.data || []).map((c: any) => (
                            <Select.Option key={c.name} value={c.name}>
                                <Badge status={c.status === 'running' ? 'success' : 'error'} text={`${c.name} (${c.status})`} />
                            </Select.Option>
                        ))}
                    </Select>

                    <Select
                        placeholder="All Levels"
                        allowClear
                        style={{ width: 130 }}
                        onChange={(value) => { setLevel(value); setPage(1); }}
                        value={level}
                    >
                        {['ERROR', 'WARN', 'INFO', 'LOG', 'DEBUG'].map(l => (
                            <Select.Option key={l} value={l}>
                                <Tag color={levelColors[l]} style={{ margin: 0 }}>{l}</Tag>
                            </Select.Option>
                        ))}
                    </Select>

                    <Input
                        placeholder="Search logs..."
                        prefix={<SearchOutlined />}
                        style={{ width: 300 }}
                        value={searchInput}
                        onChange={(e) => setSearchInput(e.target.value)}
                        onPressEnter={handleSearch}
                        allowClear
                        onClear={() => { setSearch(undefined); setPage(1); }}
                    />

                    <Button type="primary" onClick={handleSearch} icon={<SearchOutlined />}>Search</Button>
                    <Button onClick={handleClear}>Clear All</Button>
                </Space>
            </Card>

            <Table
                columns={columns}
                dataSource={pagedLogs}
                rowKey={(record: LogEntry, index?: number) => `${record.timestamp}-${index ?? 0}`}
                rowClassName={rowClassName}
                loading={isLoading}
                pagination={{
                    total: filteredLogs.length,
                    pageSize: PAGE_SIZE,
                    current: page,
                    onChange: (p) => { setPage(p); },
                    showSizeChanger: false,
                    showTotal: (total, range) => `${range[0]}–${range[1]} of ${total} logs`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
                scroll={{ y: 560 }}
                size="small"
            />
        </div>
    );
}
