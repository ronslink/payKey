import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Table, Input, Typography, Tag, Button } from 'antd';
import { SearchOutlined, EyeOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { adminUsers } from '../api/client';

const { Title } = Typography;

export default function UsersPage() {
    const navigate = useNavigate();
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(1);

    const { data, isLoading } = useQuery({
        queryKey: ['admin-users', search, page],
        queryFn: () => adminUsers.list({ search: search || undefined, page }),
    });

    const tierColor: Record<string, string> = {
        FREE: 'default',
        BASIC: 'blue',
        GOLD: 'gold',
        PLATINUM: 'purple',
    };

    const columns = [
        { title: 'Name / Business', dataIndex: 'displayName', key: 'name', render: (v: string) => <strong>{v}</strong> },
        { title: 'Email', dataIndex: 'employer_email', key: 'email', render: (_: any, r: any) => r.email || r.employer_email },
        { title: 'Plan', dataIndex: 'subscription_tier', key: 'tier', render: (v: string) => v ? <Tag color={tierColor[v] || 'default'}>{v}</Tag> : <Tag>No plan</Tag> },
        { title: 'Sub Status', dataIndex: 'subscription_status', key: 'status', render: (v: string) => v ? <Tag color={v === 'ACTIVE' ? 'green' : 'red'}>{v}</Tag> : '—' },
        { title: 'Workers', dataIndex: 'workerCount', key: 'workers', align: 'right' as const },
        { title: 'Wallet (KES)', dataIndex: 'walletBalance', key: 'wallet', align: 'right' as const, render: (v: number) => Number(v || 0).toLocaleString() },
        { title: 'Joined', dataIndex: 'createdAt', key: 'created', render: (v: string) => new Date(v).toLocaleDateString() },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, r: any) => (
                <Button icon={<EyeOutlined />} size="small" onClick={() => navigate(`/users/${r.id}`)}>
                    View
                </Button>
            ),
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                <Title level={3} style={{ margin: 0 }}>Employers</Title>
                <Input.Search
                    placeholder="Search by name or email..."
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
                pagination={{
                    total: data?.total,
                    pageSize: 20,
                    current: page,
                    onChange: setPage,
                    showTotal: (t) => `${t} employers`,
                }}
                style={{ background: '#fff', borderRadius: 12 }}
            />
        </div>
    );
}
