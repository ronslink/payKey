import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Tabs, Card, Descriptions, Tag, Table, Button, Spin, Alert, Typography } from 'antd';
import { ArrowLeftOutlined } from '@ant-design/icons';
import { adminUsers } from '../api/client';

const { Title } = Typography;

export default function UserDetailPage() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();

    const { data, isLoading, error } = useQuery({
        queryKey: ['admin-user', id],
        queryFn: () => adminUsers.detail(id!),
    });

    if (isLoading) return <Spin size="large" style={{ display: 'block', marginTop: 60, textAlign: 'center' }} />;
    if (error) return <Alert type="error" title="Failed to load user" />;

    const { user, workers, recentTransactions, subscription, payPeriods } = data;
    const displayName = user?.businessName || `${user?.firstName || ''} ${user?.lastName || ''}`.trim() || user?.email;

    return (
        <div>
            <Button icon={<ArrowLeftOutlined />} onClick={() => navigate(-1)} style={{ marginBottom: 16 }}>
                Back
            </Button>
            <Title level={3}>{displayName}</Title>

            <Tabs defaultActiveKey="overview" items={[
                {
                    key: 'overview',
                    label: 'Overview',
                    children: (
                        <Card>
                            <Descriptions column={2} bordered>
                                <Descriptions.Item label="Email">{user?.email}</Descriptions.Item>
                                <Descriptions.Item label="Role">{user?.role}</Descriptions.Item>
                                <Descriptions.Item label="Plan Tier">
                                    <Tag>{user?.tier || 'FREE'}</Tag>
                                </Descriptions.Item>
                                <Descriptions.Item label="Subscription Status">
                                    {subscription ? <Tag color="green">{subscription.status}</Tag> : <Tag>None</Tag>}
                                </Descriptions.Item>
                                <Descriptions.Item label="Wallet Balance">KES {Number(user?.walletBalance || 0).toLocaleString()}</Descriptions.Item>
                                <Descriptions.Item label="Joined">{new Date(user?.createdAt).toLocaleDateString()}</Descriptions.Item>
                                <Descriptions.Item label="KRA PIN">{user?.kraPIN || '—'}</Descriptions.Item>
                                <Descriptions.Item label="Phone">{user?.phone || '—'}</Descriptions.Item>
                            </Descriptions>
                        </Card>
                    ),
                },
                {
                    key: 'workers',
                    label: `Workers (${workers?.length || 0})`,
                    children: (
                        <Table
                            dataSource={workers}
                            rowKey="id"
                            columns={[
                                { title: 'Name', dataIndex: 'name', key: 'name' },
                                { title: 'Phone', dataIndex: 'phoneNumber', key: 'phone' },
                                { title: 'Gross Salary (KES)', dataIndex: 'salaryGross', key: 'salary', render: (v: number) => Number(v).toLocaleString() },
                                { title: 'Active', dataIndex: 'isActive', key: 'active', render: (v: boolean) => <Tag color={v ? 'green' : 'red'}>{v ? 'Active' : 'Inactive'}</Tag> },
                                {
                                    title: 'Employee Portal',
                                    key: 'portal',
                                    render: (_: any, r: any) => {
                                        if (r.linkedUserId) return <Tag color="green">Connected</Tag>;
                                        if (r.inviteCode) return <Tag color="orange">Invite Sent</Tag>;
                                        return <Tag color="default">Uninvited</Tag>;
                                    }
                                },
                            ]}
                            pagination={false}
                        />
                    ),
                },
                {
                    key: 'transactions',
                    label: 'Transactions',
                    children: (
                        <Table
                            dataSource={recentTransactions}
                            rowKey="id"
                            columns={[
                                { title: 'Date', dataIndex: 'createdAt', key: 'date', render: (v: string) => new Date(v).toLocaleDateString() },
                                { title: 'Type', dataIndex: 'type', key: 'type', render: (v: string) => <Tag>{v}</Tag> },
                                { title: 'Amount', dataIndex: 'amount', key: 'amount', render: (v: number) => `KES ${Number(v).toLocaleString()}` },
                                { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={v === 'SUCCESS' ? 'green' : v === 'FAILED' ? 'red' : 'orange'}>{v}</Tag> },
                            ]}
                        />
                    ),
                },
                {
                    key: 'payroll',
                    label: `Pay Periods (${payPeriods?.length || 0})`,
                    children: (
                        <Table
                            dataSource={payPeriods}
                            rowKey="id"
                            columns={[
                                { title: 'Period', key: 'period', render: (_: any, r: any) => `${new Date(r.startDate).toLocaleDateString()} – ${new Date(r.endDate).toLocaleDateString()}` },
                                { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={v === 'paid' ? 'green' : 'orange'}>{v}</Tag> },
                                { title: 'Created', dataIndex: 'createdAt', key: 'created', render: (v: string) => new Date(v).toLocaleDateString() },
                            ]}
                        />
                    ),
                },
            ]} />
        </div>
    );
}
