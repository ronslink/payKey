import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Table, Input, Typography, Tag } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import { adminWorkers } from '../api/client';

const { Title } = Typography;

export default function WorkersPage() {
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);

    const { data, isLoading } = useQuery({
        queryKey: ['admin-workers', search, page],
        queryFn: () => adminWorkers.list({ search: search || undefined, page }),
    });

    const columns = [
        { title: 'Worker Name', dataIndex: 'worker_name', key: 'name', render: (v: string) => <strong>{v}</strong> },
        { title: 'Phone', dataIndex: 'phoneNumber', key: 'phone' },
        { title: 'Employer', dataIndex: 'employer_name', key: 'employer', render: (v: string, r: any) => <span>{v}<br /><small style={{ color: '#94a3b8' }}>{r.employer_email}</small></span> },
        { title: 'Gross Salary (KES)', dataIndex: 'salaryGross', key: 'salary', align: 'right' as const, render: (v: number) => Number(v || 0).toLocaleString() },
        { title: 'Status', dataIndex: 'isActive', key: 'active', render: (v: boolean) => <Tag color={v ? 'green' : 'red'}>{v ? 'Active' : 'Inactive'}</Tag> },
        { title: 'Payment Method', dataIndex: 'paymentMethod', key: 'method', render: (v: string) => <Tag>{v || '—'}</Tag> },
        {
            title: 'Employee Portal',
            key: 'portal',
            render: (_: any, r: any) => {
                if (r.linkedUserId) return <Tag color="green">Connected</Tag>;
                if (r.inviteCode) return <Tag color="orange">Invite Sent</Tag>;
                return <Tag color="default">Uninvited</Tag>;
            }
        },
        { title: 'Added', dataIndex: 'createdAt', key: 'created', render: (v: string) => new Date(v).toLocaleDateString() },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                <Title level={3} style={{ margin: 0 }}>Workers</Title>
                <Input.Search
                    placeholder="Search by name or employer..."
                    prefix={<SearchOutlined />}
                    style={{ width: 280 }}
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
                pagination={{ total: data?.total, pageSize: 20, current: page, onChange: setPage, showTotal: (t) => `${t} workers` }}
                style={{ background: '#fff', borderRadius: 12 }}
            />
        </div>
    );
}
