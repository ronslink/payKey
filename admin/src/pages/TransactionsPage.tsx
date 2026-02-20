import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Input, Select, Typography, Tag, Button, Modal, Form, message } from 'antd';
import { SearchOutlined, RollbackOutlined } from '@ant-design/icons';
import { adminTransactions } from '../api/client';

const { Title } = Typography;

const statusColors: Record<string, string> = {
    SUCCESS: 'green', FAILED: 'red', PENDING: 'orange', CLEARING: 'blue', MANUAL_INTERVENTION: 'purple',
};

export default function TransactionsPage() {
    const qc = useQueryClient();
    const [search, setSearch] = useState('');
    const [status, setStatus] = useState<string | undefined>();
    const [type, setType] = useState<string | undefined>();
    const [page, setPage] = useState(1);
    const [refundModal, setRefundModal] = useState<{ open: boolean; txId?: string; maxAmount?: number }>({ open: false });
    const [form] = Form.useForm();

    const { data, isLoading } = useQuery({
        queryKey: ['admin-transactions', search, status, type, page],
        queryFn: () => adminTransactions.list({ search: search || undefined, status, type, page }),
    });

    const refundMut = useMutation({
        mutationFn: (vals: { amount?: number; reason: string }) =>
            adminTransactions.refund({ transactionId: refundModal.txId!, ...vals }),
        onSuccess: () => {
            message.success('Refund initiated');
            setRefundModal({ open: false });
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-transactions'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Refund failed'),
    });

    const columns = [
        { title: 'Date', dataIndex: 'createdAt', key: 'date', render: (v: string) => new Date(v).toLocaleDateString() },
        { title: 'Employer', dataIndex: 'employer_name', key: 'employer', render: (v: string, r: any) => <span>{v}<br /><small style={{ color: '#94a3b8' }}>{r.employer_email}</small></span> },
        { title: 'Worker', dataIndex: 'worker_name', key: 'worker', render: (v: string) => v || '—' },
        { title: 'Type', dataIndex: 'type', key: 'type', render: (v: string) => <Tag>{v}</Tag> },
        { title: 'Amount (KES)', dataIndex: 'amount', key: 'amount', align: 'right' as const, render: (v: number) => Number(v).toLocaleString() },
        { title: 'Status', dataIndex: 'status', key: 'status', render: (v: string) => <Tag color={statusColors[v] || 'default'}>{v}</Tag> },
        { title: 'Provider Ref', dataIndex: 'providerRef', key: 'ref', render: (v: string) => <small style={{ color: '#64748b' }}>{v || '—'}</small> },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, r: any) =>
                r.status === 'SUCCESS' && r.type !== 'REFUND' ? (
                    <Button
                        icon={<RollbackOutlined />}
                        size="small"
                        danger
                        onClick={() => setRefundModal({ open: true, txId: r.id, maxAmount: Math.abs(Number(r.amount)) })}
                    >
                        Refund
                    </Button>
                ) : null,
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                <Title level={3} style={{ margin: 0 }}>Transactions</Title>
                <div style={{ display: 'flex', gap: 8 }}>
                    <Input.Search
                        placeholder="Search..."
                        prefix={<SearchOutlined />}
                        style={{ width: 200 }}
                        allowClear
                        onSearch={setSearch}
                        onChange={(e) => !e.target.value && setSearch('')}
                    />
                    <Select placeholder="Status" allowClear style={{ width: 140 }} onChange={setStatus}>
                        {['PENDING', 'SUCCESS', 'FAILED', 'CLEARING', 'MANUAL_INTERVENTION'].map(s => <Select.Option key={s} value={s}>{s}</Select.Option>)}
                    </Select>
                    <Select placeholder="Type" allowClear style={{ width: 140 }} onChange={setType}>
                        {['SUBSCRIPTION', 'SALARY_PAYOUT', 'TOPUP', 'DEPOSIT', 'REFUND'].map(t => <Select.Option key={t} value={t}>{t}</Select.Option>)}
                    </Select>
                </div>
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
                title="Initiate Refund"
                open={refundModal.open}
                onCancel={() => setRefundModal({ open: false })}
                onOk={() => form.submit()}
                confirmLoading={refundMut.isPending}
                okText="Confirm Refund"
                okButtonProps={{ danger: true }}
            >
                <Form form={form} layout="vertical" onFinish={(v) => refundMut.mutate(v)}>
                    <Form.Item label={`Amount (KES) — max ${refundModal.maxAmount?.toLocaleString()}`} name="amount">
                        <Input type="number" placeholder={`Leave blank for full amount (${refundModal.maxAmount?.toLocaleString()} KES)`} min={1} max={refundModal.maxAmount} />
                    </Form.Item>
                    <Form.Item label="Reason" name="reason" rules={[{ required: true, message: 'Please enter a reason' }]}>
                        <Input.TextArea rows={3} placeholder="Reason for refund..." />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
