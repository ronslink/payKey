import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Table, Input, Typography, Tag, Button, Modal, Card, Row, Col } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import { adminPayroll } from '../api/client';

const { Title } = Typography;

export default function PayrollPage() {
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);
    const [detailModal, setDetailModal] = useState<{ open: boolean; payPeriodId?: string; employerName?: string }>({ open: false });

    // Dashboard Metrics
    const { data: dashboard, isLoading: dashboardLoading } = useQuery({
        queryKey: ['admin-payroll-dashboard'],
        queryFn: adminPayroll.dashboard,
    });

    // List view
    const { data, isLoading } = useQuery({
        queryKey: ['admin-payroll', search, page],
        queryFn: () => adminPayroll.payPeriods({ search: search || undefined, page }),
    });

    const { data: recordsData, isLoading: recordsLoading } = useQuery({
        queryKey: ['admin-payroll-records', detailModal.payPeriodId],
        queryFn: () => adminPayroll.records(detailModal.payPeriodId!),
        enabled: !!detailModal.payPeriodId && detailModal.open,
    });

    const statusColor: Record<string, string> = { paid: 'green', processing: 'blue', open: 'orange', closed: 'default', failed: 'red' };

    const columns = [
        {
            title: 'Employer',
            dataIndex: 'employer_name',
            key: 'employer',
            render: (v: string, r: any) => <span><strong>{v}</strong><br /><small style={{ color: '#94a3b8' }}>{r.employer_email}</small></span>,
        },
        {
            title: 'Period',
            key: 'period',
            render: (_: any, r: any) => `${new Date(r.startDate).toLocaleDateString()} – ${new Date(r.endDate).toLocaleDateString()}`,
        },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={statusColor[v] || 'default'}>{v}</Tag> },
        { title: 'Workers Paid', dataIndex: 'recordCount', key: 'count', align: 'right' as const },
        { title: 'Total Net Pay (KES)', dataIndex: 'totalNetPay', key: 'amount', align: 'right' as const, render: (v: number) => Number(v).toLocaleString() },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, r: any) => (
                <Button size="small" onClick={() => setDetailModal({ open: true, payPeriodId: r.id, employerName: r.employer_name })}>
                    View Records
                </Button>
            ),
        },
    ];

    const recordColumns = [
        { title: 'Worker', dataIndex: 'worker_name', key: 'name' },
        { title: 'Phone', dataIndex: 'worker_phone', key: 'phone' },
        { title: 'Gross (KES)', dataIndex: 'grossSalary', key: 'gross', align: 'right' as const, render: (v: number) => Number(v).toLocaleString() },
        { title: 'Net Pay (KES)', dataIndex: 'netPay', key: 'net', align: 'right' as const, render: (v: number) => Number(v).toLocaleString() },
        { title: 'PAYE', dataIndex: 'payeTax', key: 'paye', align: 'right' as const, render: (v: number) => Number(v || 0).toLocaleString() },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={statusColor[v] || 'default'}>{v}</Tag> },
    ];

    return (
        <div>
            <Title level={3} style={{ marginBottom: 24 }}>Payroll Dashboard</Title>

            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
                <Col xs={24} sm={8}>
                    <Card size="small" loading={dashboardLoading}>
                        <div style={{ color: '#64748b', fontSize: 13, marginBottom: 4 }}>Total Pay Periods</div>
                        <div style={{ fontSize: 28, fontWeight: 600 }}>{dashboard?.summary?.totalPeriods || 0}</div>
                    </Card>
                </Col>
                <Col xs={24} sm={8}>
                    <Card size="small" loading={dashboardLoading}>
                        <div style={{ color: '#64748b', fontSize: 13, marginBottom: 4 }}>Successful Pay Periods</div>
                        <div style={{ fontSize: 28, fontWeight: 600, color: '#10b981' }}>{dashboard?.summary?.successfulPeriods || 0}</div>
                    </Card>
                </Col>
                <Col xs={24} sm={8}>
                    <Card size="small" loading={dashboardLoading}>
                        <div style={{ color: '#64748b', fontSize: 13, marginBottom: 4 }}>Total Volume (Net Pay)</div>
                        <div style={{ fontSize: 28, fontWeight: 600 }}>
                            <span style={{ fontSize: 16, color: '#94a3b8', marginRight: 4 }}>KES</span>
                            {Number(dashboard?.summary?.totalVolume || 0).toLocaleString()}
                        </div>
                    </Card>
                </Col>
            </Row>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 16 }}>
                <Title level={4} style={{ margin: 0 }}>All Pay Periods</Title>
                <Input.Search
                    placeholder="Search by employer..."
                    prefix={<SearchOutlined />}
                    style={{ width: 300 }}
                    allowClear
                    onSearch={setSearch}
                    onChange={(e) => !e.target.value && setSearch('')}
                />
            </div>

            <Table
                columns={columns}
                dataSource={data?.data || []}
                rowKey="id"
                loading={isLoading}
                pagination={{ total: data?.total, pageSize: 20, current: page, onChange: setPage }}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            <Modal
                title={`Records: ${detailModal.employerName}`}
                open={detailModal.open}
                onCancel={() => setDetailModal({ open: false })}
                footer={null}
                width={800}
            >
                <Table
                    columns={recordColumns}
                    dataSource={recordsData || []}
                    rowKey="id"
                    loading={recordsLoading}
                    pagination={false}
                    size="small"
                />
            </Modal>
        </div>
    );
}
