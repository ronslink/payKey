import { useQuery } from '@tanstack/react-query';
import {
    Table, Typography, Select, Tag, Button, Space, Input, Card, Statistic, Row, Col, Badge,
    Drawer, Tooltip, Switch, DatePicker, Divider, Alert, message, Empty
} from 'antd';
import {
    FileTextOutlined, ReloadOutlined, BugOutlined, InfoCircleOutlined,
    WarningOutlined, ContainerOutlined, CopyOutlined, DownloadOutlined, ClockCircleOutlined,
    EyeOutlined, PauseCircleOutlined, PlayCircleOutlined,
    FilterOutlined, ClearOutlined, CloseOutlined
} from '@ant-design/icons';
import { useState, useEffect, useCallback, useRef } from 'react';
import { adminLogs } from '../api/client';
import dayjs from 'dayjs';

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

interface LogEntry {
    timestamp: string;
    level: string;
    message: string;
    raw: string;
    container?: string;
}

interface LogsResponse {
    data: LogEntry[];
    total: number;
    container: string;
    lines: number;
}

const PAGE_SIZE = 50;

// Date range presets - simplified for Ant Design 5.x
const RANGE_PRESETS: any[] = [
    { label: 'Last 15 min', value: [dayjs().subtract(15, 'minute'), dayjs()] },
    { label: 'Last 1 hour', value: [dayjs().subtract(1, 'hour'), dayjs()] },
    { label: 'Last 6 hours', value: [dayjs().subtract(6, 'hour'), dayjs()] },
    { label: 'Last 24 hours', value: [dayjs().subtract(24, 'hour'), dayjs()] },
    { label: 'Last 7 days', value: [dayjs().subtract(7, 'day'), dayjs()] },
];

// Highlight search terms in text
function highlightText(text: string, searchTerm: string) {
    if (!searchTerm) return text;
    const regex = new RegExp(`(${searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
    const parts = text.split(regex);
    return parts.map((part, i) =>
        regex.test(part) ? <mark key={i} style={{ background: '#fff566', padding: '0 2px' }}>{part}</mark> : part
    );
}

// Format stack trace for better readability
function formatStackTrace(message: string): React.ReactNode {
    const lines = message.split('\n');
    if (lines.length <= 2) return message;

    // Check if it looks like a stack trace
    const hasStackTrace = lines.some(line => line.includes('at ') || line.includes('Error:') || line.includes('Traceback'));
    if (!hasStackTrace) return message;

    return (
        <div style={{ fontFamily: 'monospace', fontSize: 12 }}>
            {lines.map((line, idx) => {
                const isErrorLine = line.includes('Error:') || line.includes('error') || line.includes('Exception');
                const isStackLine = line.trim().startsWith('at ');
                return (
                    <div
                        key={idx}
                        style={{
                            paddingLeft: isStackLine ? 16 : 0,
                            color: isErrorLine ? '#cf1322' : isStackLine ? '#666' : 'inherit',
                            fontWeight: isErrorLine ? 600 : 400,
                        }}
                    >
                        {line}
                    </div>
                );
            })}
        </div>
    );
}

export default function LogsPage() {
    // State
    const [page, setPage] = useState(1);
    const [level, setLevel] = useState<string>();
    const [search, setSearch] = useState<string>();
    const [searchInput, setSearchInput] = useState<string>();
    const [selectedContainer, setSelectedContainer] = useState<string>();
    const [dateRange, setDateRange] = useState<[dayjs.Dayjs | null, dayjs.Dayjs | null] | null>(null);

    // Live mode
    const [liveMode, setLiveMode] = useState(false);
    const liveIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

    // Detail drawer
    const [selectedLog, setSelectedLog] = useState<LogEntry | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);

    // Auto-refresh
    const [autoRefresh, setAutoRefresh] = useState(true);

    // Fetch containers
    const { data: containersData } = useQuery({
        queryKey: ['admin-containers'],
        queryFn: () => adminLogs.containers(),
        refetchInterval: 30000,
    });

    // Fetch logs
    const { data, isLoading, refetch, dataUpdatedAt, error } = useQuery<LogsResponse>({
        queryKey: ['admin-logs', selectedContainer, level, search, dateRange?.[0]?.toISOString(), dateRange?.[1]?.toISOString()],
        queryFn: () => {
            const params: any = { container: selectedContainer, lines: liveMode ? 100 : 500, search };
            if (dateRange?.[0] && dateRange?.[1]) {
                params.startTime = dateRange[0].toISOString();
                params.endTime = dateRange[1].toISOString();
            }
            return adminLogs.list(params);
        },
        refetchInterval: autoRefresh && !liveMode ? 30000 : false,
        retry: 2,
    });

    // Live tail mode - more frequent polling
    useEffect(() => {
        if (liveMode) {
            liveIntervalRef.current = setInterval(() => {
                refetch();
            }, 2000);
        } else if (liveIntervalRef.current) {
            clearInterval(liveIntervalRef.current);
            liveIntervalRef.current = null;
        }
        return () => {
            if (liveIntervalRef.current) {
                clearInterval(liveIntervalRef.current);
            }
        };
    }, [liveMode, refetch]);

    // Filter logs client-side
    const filteredLogs = (data?.data || []).filter((log: LogEntry) => {
        if (level && log.level !== level) return false;
        if (search && !log.message.toLowerCase().includes(search.toLowerCase()) && !log.raw?.toLowerCase().includes(search.toLowerCase())) return false;
        return true;
    });

    // Paginate
    const pagedLogs = filteredLogs.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

    // Stats
    const errorCount = filteredLogs.filter((l: LogEntry) => l.level === 'ERROR').length;
    const warnCount = filteredLogs.filter((l: LogEntry) => l.level === 'WARN').length;
    const infoCount = filteredLogs.filter((l: LogEntry) => l.level === 'INFO' || l.level === 'LOG').length;

    // Handlers
    const handleSearch = useCallback(() => { setSearch(searchInput); setPage(1); }, [searchInput]);
    const handleClear = useCallback(() => {
        setSearchInput(''); setSearch(undefined); setLevel(undefined);
        setSelectedContainer(undefined); setDateRange(null); setPage(1);
    }, []);

    const handleCopyLog = useCallback((log: LogEntry) => {
        navigator.clipboard.writeText(JSON.stringify(log, null, 2));
        message.success('Log copied to clipboard');
    }, []);

    const handleExport = useCallback(() => {
        const exportData = {
            exportedAt: new Date().toISOString(),
            filters: { level, search, container: selectedContainer, dateRange: dateRange?.map(d => d?.toISOString()) },
            logs: filteredLogs,
            total: filteredLogs.length,
        };
        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `logs-${dayjs().format('YYYY-MM-DD-HHmm')}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        message.success(`Exported ${filteredLogs.length} logs`);
    }, [filteredLogs, level, search, selectedContainer, dateRange]);

    const openLogDetail = useCallback((log: LogEntry) => {
        setSelectedLog(log);
        setDrawerOpen(true);
    }, []);

    const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : '—';

    // Styles
    const levelColors: Record<string, string> = {
        ERROR: 'red', WARN: 'orange', INFO: 'blue', DEBUG: 'default', VERBOSE: 'default', LOG: 'blue',
    };

    const levelIcons: Record<string, React.ReactNode> = {
        ERROR: <BugOutlined />, WARN: <WarningOutlined />, INFO: <InfoCircleOutlined />,
        DEBUG: <FileTextOutlined />, VERBOSE: <FileTextOutlined />, LOG: <FileTextOutlined />,
    };

    const rowClassName = (record: LogEntry) => {
        if (record.level === 'ERROR') return 'log-row-error';
        if (record.level === 'WARN') return 'log-row-warn';
        return '';
    };

    const columns = [
        {
            title: 'Time',
            dataIndex: 'timestamp',
            key: 'timestamp',
            width: 100,
            render: (v: string) => {
                if (!v) return '—';
                try {
                    const date = new Date(v);
                    return (
                        <Tooltip title={date.toLocaleString()}>
                            <Text style={{ fontSize: 11, fontFamily: 'monospace' }}>
                                {dayjs(date).format('HH:mm:ss')}
                            </Text>
                        </Tooltip>
                    );
                } catch { return v; }
            },
        },
        {
            title: 'Container',
            dataIndex: 'container',
            key: 'container',
            width: 130,
            render: (v: string) => (
                <Tag style={{ fontSize: 10 }}>{v || 'unknown'}</Tag>
            ),
        },
        {
            title: 'Level',
            dataIndex: 'level',
            key: 'level',
            width: 70,
            render: (v: string) => (
                <Tag color={levelColors[v] || 'default'} icon={levelIcons[v]} style={{ fontSize: 10, padding: '0 4px' }}>{v}</Tag>
            ),
        },
        {
            title: 'Message',
            dataIndex: 'message',
            key: 'message',
            render: (v: string) => (
                <Text style={{ fontFamily: 'monospace', fontSize: 12, display: 'block', wordBreak: 'break-word' }} ellipsis>
                    {search ? highlightText(v, search) : v}
                </Text>
            ),
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 100,
            fixed: 'right' as const,
            render: (_: any, record: LogEntry) => (
                <Space size="small">
                    <Tooltip title="View details">
                        <Button icon={<EyeOutlined />} size="small" onClick={() => openLogDetail(record)} />
                    </Tooltip>
                    <Tooltip title="Copy to clipboard">
                        <Button icon={<CopyOutlined />} size="small" onClick={() => handleCopyLog(record)} />
                    </Tooltip>
                </Space>
            ),
        },
    ];

    return (
        <div>
            <style>{`
                .log-row-error td { background: #fff1f0 !important; }
                .log-row-warn td { background: #fffbe6 !important; }
                .live-indicator {
                    animation: pulse 1.5s ease-in-out infinite;
                }
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.5; }
                }
            `}</style>

            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 24, alignItems: 'center' }}>
                <div>
                    <Title level={3} style={{ margin: 0 }}>
                        Application Logs
                        {liveMode && <Badge color="red" text="LIVE" style={{ marginLeft: 12 }} className="live-indicator" />}
                    </Title>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        {autoRefresh && !liveMode && 'Auto-refreshes every 30s · '}
                        {liveMode && 'Live tail mode · '}
                        Last updated: {lastUpdated}
                    </Text>
                </div>
                <Space>
                    <Tooltip title={liveMode ? 'Stop live tail' : 'Start live tail'}>
                        <Button
                            icon={liveMode ? <PauseCircleOutlined /> : <PlayCircleOutlined />}
                            onClick={() => setLiveMode(!liveMode)}
                            type={liveMode ? 'primary' : 'default'}
                            danger={liveMode}
                        >
                            {liveMode ? 'Stop Live' : 'Live Tail'}
                        </Button>
                    </Tooltip>
                    <Tooltip title="Export logs">
                        <Button icon={<DownloadOutlined />} onClick={handleExport} disabled={filteredLogs.length === 0}>
                            Export JSON
                        </Button>
                    </Tooltip>
                    <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
                        Refresh
                    </Button>
                </Space>
            </div>

            {/* Error Alert */}
            {error && (
                <Alert
                    message="Failed to fetch logs"
                    description={error instanceof Error ? error.message : 'Unknown error'}
                    type="error"
                    showIcon
                    style={{ marginBottom: 16 }}
                    closable
                />
            )}

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
                        style={{ width: 200 }}
                        onChange={(value) => { setSelectedContainer(value); setPage(1); }}
                        value={selectedContainer}
                        suffixIcon={<ContainerOutlined />}
                    >
                        {(containersData?.data || []).map((c: any) => (
                            <Select.Option key={c.name} value={c.name}>
                                <Badge status={c.status === 'running' ? 'success' : 'error'} text={`${c.name}`} />
                            </Select.Option>
                        ))}
                    </Select>

                    <Select
                        placeholder="All Levels"
                        allowClear
                        style={{ width: 120 }}
                        onChange={(value) => { setLevel(value); setPage(1); }}
                        value={level}
                        suffixIcon={<FilterOutlined />}
                    >
                        {['ERROR', 'WARN', 'INFO', 'LOG', 'DEBUG'].map(l => (
                            <Select.Option key={l} value={l}>
                                <Tag color={levelColors[l]} style={{ margin: 0 }}>{l}</Tag>
                            </Select.Option>
                        ))}
                    </Select>

                    <RangePicker
                        showTime
                        presets={RANGE_PRESETS}
                        value={dateRange}
                        onChange={(dates) => { setDateRange(dates); setPage(1); }}
                        style={{ width: 320 }}
                        suffixIcon={<ClockCircleOutlined />}
                    />

                    <Input.Search
                        placeholder="Search logs..."
                        style={{ width: 280 }}
                        value={searchInput}
                        onChange={(e) => setSearchInput(e.target.value)}
                        onSearch={handleSearch}
                        allowClear
                        onClear={() => { setSearch(undefined); setPage(1); }}
                    />

                    <Button icon={<ClearOutlined />} onClick={handleClear}>Clear All</Button>

                    <Divider type="vertical" />

                    <Tooltip title="Auto-refresh">
                        <Switch
                            checked={autoRefresh}
                            onChange={setAutoRefresh}
                            checkedChildren={<PlayCircleOutlined />}
                            unCheckedChildren={<PauseCircleOutlined />}
                        />
                    </Tooltip>
                </Space>
            </Card>

            {/* Logs Table */}
            {filteredLogs.length === 0 && !isLoading ? (
                <Empty description="No logs found matching your filters" style={{ marginTop: 40 }} />
            ) : (
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
                    scroll={{ y: 500, x: 800 }}
                    size="small"
                    onRow={(record) => ({
                        onDoubleClick: () => openLogDetail(record),
                    })}
                />
            )}

            {/* Log Detail Drawer */}
            <Drawer
                title={
                    <Space>
                        <Tag color={levelColors[selectedLog?.level || 'LOG']}>{selectedLog?.level}</Tag>
                        Log Details
                    </Space>
                }
                placement="right"
                width={800}
                onClose={() => setDrawerOpen(false)}
                open={drawerOpen}
                extra={
                    <Space>
                        <Button icon={<CopyOutlined />} onClick={() => selectedLog && handleCopyLog(selectedLog)}>
                            Copy
                        </Button>
                        <Button icon={<CloseOutlined />} onClick={() => setDrawerOpen(false)} />
                    </Space>
                }
            >
                {selectedLog && (
                    <div>
                        <Card size="small" style={{ marginBottom: 16 }}>
                            <Row gutter={[16, 16]}>
                                <Col span={12}>
                                    <Text type="secondary">Timestamp</Text>
                                    <div><Text code style={{ fontSize: 13 }}>{selectedLog.timestamp}</Text></div>
                                    <Text type="secondary" style={{ fontSize: 11 }}>
                                        {dayjs(selectedLog.timestamp).format('MMMM D, YYYY h:mm:ss A')}
                                    </Text>
                                </Col>
                                <Col span={12}>
                                    <Text type="secondary">Level</Text>
                                    <div>
                                        <Tag color={levelColors[selectedLog.level]} icon={levelIcons[selectedLog.level]}>
                                            {selectedLog.level}
                                        </Tag>
                                    </div>
                                </Col>
                                {selectedLog.container && (
                                    <Col span={12}>
                                        <Text type="secondary">Container</Text>
                                        <div><Tag>{selectedLog.container}</Tag></div>
                                    </Col>
                                )}
                            </Row>
                        </Card>

                        <Divider>Message</Divider>
                        <Card size="small" style={{ background: '#fafafa' }}>
                            <div style={{ fontFamily: 'monospace', fontSize: 13, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                                {formatStackTrace(selectedLog.message)}
                            </div>
                        </Card>

                        <Divider>Raw Log</Divider>
                        <Card size="small" style={{ background: '#1e1e1e' }}>
                            <pre style={{ color: '#d4d4d4', fontSize: 12, margin: 0, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                                {selectedLog.raw}
                            </pre>
                        </Card>
                    </div>
                )}
            </Drawer>
        </div>
    );
}
