import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Typography, Tag, Button, Modal, Form, Input, DatePicker, InputNumber, Select, Space, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useState } from 'react';
import { adminTaxConfigs } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title } = Typography;

export default function TaxConfigPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [createModal, setCreateModal] = useState(false);
    const [form] = Form.useForm();

    const { data, isLoading } = useQuery({ queryKey: ['admin-tax-configs'], queryFn: adminTaxConfigs.list });

    const createMut = useMutation({
        mutationFn: (vals: any) => adminTaxConfigs.create({
            ...vals,
            effectiveFrom: vals.effectiveFrom ? vals.effectiveFrom.toISOString() : undefined,
            effectiveTo: vals.effectiveTo ? vals.effectiveTo.toISOString() : undefined,
        }),
        onSuccess: () => {
            message.success('Tax config created');
            setCreateModal(false);
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-tax-configs'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Create failed'),
    });

    const deactivateMut = useMutation({
        mutationFn: (id: string) => adminTaxConfigs.deactivate(id),
        onSuccess: () => {
            message.success('Deactivated');
            qc.invalidateQueries({ queryKey: ['admin-tax-configs'] });
        },
    });

    const columns = [
        { title: 'Tax Type', dataIndex: 'taxType', key: 'type', render: (v: string) => <Tag color="blue">{v}</Tag> },
        { title: 'Country', dataIndex: 'country', key: 'country' },
        {
            title: 'Configuration',
            key: 'configuration',
            render: (_: any, r: any) => {
                const config = r.configuration || {};

                if (r.rateType === 'PERCENTAGE') {
                    return (
                        <Space direction="vertical" size="small">
                            <div><strong>Rate:</strong> {config.percentage}%</div>
                            {config.minAmount && <div><strong>Min:</strong> KES {config.minAmount}</div>}
                            {config.maxAmount && <div><strong>Max:</strong> KES {config.maxAmount}</div>}
                        </Space>
                    );
                }

                if (r.rateType === 'GRADUATED' && config.brackets) {
                    return (
                        <Space direction="vertical" size={1}>
                            <div><strong>Personal Relief:</strong> {config.personalRelief}</div>
                            {config.brackets.map((b: any, i: number) => (
                                <div key={i} style={{ fontSize: 12 }}>
                                    {b.to ? `${b.from} - ${b.to}` : `${b.from}+`}: {b.rate * 100}%
                                </div>
                            ))}
                        </Space>
                    );
                }

                if (r.rateType === 'TIERED' && config.tiers) {
                    return (
                        <Space direction="vertical" size={1}>
                            {config.tiers.map((t: any, i: number) => (
                                <div key={i} style={{ fontSize: 12 }}>
                                    {t.name}: {t.rate * 100}% ({t.salaryFrom} - {t.salaryTo})
                                </div>
                            ))}
                        </Space>
                    );
                }

                return <Tag>Complex Object</Tag>;
            },
        },
        {
            title: 'Effective From',
            dataIndex: 'effectiveFrom',
            key: 'from',
            render: (v: string) => v ? new Date(v).toLocaleDateString() : '—',
        },
        {
            title: 'Effective To',
            dataIndex: 'effectiveTo',
            key: 'to',
            render: (v: string) => v ? new Date(v).toLocaleDateString() : 'Present',
        },
        {
            title: 'Active',
            dataIndex: 'isActive',
            key: 'active',
            render: (v: boolean) => <Tag color={v ? 'green' : 'red'}>{v ? 'Active' : 'Inactive'}</Tag>,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, r: any) =>
                canEdit && r.isActive ? (
                    <Button size="small" danger onClick={() => deactivateMut.mutate(r.id)}>
                        Deactivate
                    </Button>
                ) : null,
        },
    ];

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                <Title level={3} style={{ margin: 0 }}>Tax Configurations</Title>
                {canEdit && (
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        style={{ background: '#6366f1' }}
                        onClick={() => setCreateModal(true)}
                    >
                        Add Config
                    </Button>
                )}
            </div>

            <Table
                columns={columns}
                dataSource={data || []}
                rowKey="id"
                loading={isLoading}
                pagination={false}
                style={{ background: '#fff', borderRadius: 12 }}
            />

            <Modal
                title="New Tax Configuration"
                open={createModal}
                onCancel={() => setCreateModal(false)}
                onOk={() => form.submit()}
                confirmLoading={createMut.isPending}
            >
                <Form form={form} layout="vertical" onFinish={(v) => createMut.mutate(v)}>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Tax Type" name="taxType" rules={[{ required: true }]}>
                            <Select style={{ width: 140 }}>
                                {['PAYE', 'NHIF', 'NSSF', 'SHIF', 'HOUSING_LEVY', 'VAT'].map((t) => (
                                    <Select.Option key={t} value={t}>{t}</Select.Option>
                                ))}
                            </Select>
                        </Form.Item>
                        <Form.Item label="Country" name="country" initialValue="KE">
                            <Input style={{ width: 80 }} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Rate Type" name="rateType" initialValue="PERCENTAGE" rules={[{ required: true }]}>
                        <Select style={{ width: '100%' }}>
                            {['PERCENTAGE', 'GRADUATED', 'TIERED', 'BANDED'].map((t) => (
                                <Select.Option key={t} value={t}>{t}</Select.Option>
                            ))}
                        </Select>
                    </Form.Item>

                    {/* Simplified Form for PERCENTAGE type for MVP */}
                    <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                        Note: Creating complex Graduated/Tiered configurations via UI is currently limited. Use the database script for complex 2025 brackets.
                    </Typography.Text>

                    <Form.Item label="Percentage Rate (%)" name={['configuration', 'percentage']}>
                        <InputNumber min={0} max={100} step={0.01} style={{ width: '100%' }} />
                    </Form.Item>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Min Amount (KES)" name={['configuration', 'minAmount']}>
                            <InputNumber min={0} style={{ width: 150 }} />
                        </Form.Item>
                        <Form.Item label="Max Amount (KES)" name={['configuration', 'maxAmount']}>
                            <InputNumber min={0} style={{ width: 150 }} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Effective From" name="effectiveFrom">
                        <DatePicker style={{ width: '100%' }} />
                    </Form.Item>
                    <Form.Item label="Notes" name="notes">
                        <Input.TextArea rows={2} />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
}
