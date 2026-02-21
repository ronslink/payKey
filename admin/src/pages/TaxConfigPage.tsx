import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Typography, Tag, Button, Modal, Form, Input, DatePicker, InputNumber, Select, Space, message } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import { useState } from 'react';
import { adminTaxConfigs } from '../api/client';
import { useAuth } from '../contexts/AuthContext';

const { Title } = Typography;

export default function TaxConfigPage() {
    const { user } = useAuth();
    const canEdit = user?.role !== 'VIEWER';

    const qc = useQueryClient();
    const [createModal, setCreateModal] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [form] = Form.useForm();
    const rateType = Form.useWatch('rateType', form);

    const { data, isLoading } = useQuery({ queryKey: ['admin-tax-configs'], queryFn: adminTaxConfigs.list });

    const saveMut = useMutation({
        mutationFn: (vals: any) => {
            const payload = {
                ...vals,
                effectiveFrom: vals.effectiveFrom ? vals.effectiveFrom.toISOString() : undefined,
                effectiveTo: vals.effectiveTo ? vals.effectiveTo.toISOString() : undefined,
            };
            return editingId ? adminTaxConfigs.update(editingId, payload) : adminTaxConfigs.create(payload);
        },
        onSuccess: () => {
            message.success(`Tax config ${editingId ? 'updated' : 'created'}`);
            setCreateModal(false);
            setEditingId(null);
            form.resetFields();
            qc.invalidateQueries({ queryKey: ['admin-tax-configs'] });
        },
        onError: (e: any) => message.error(e?.response?.data?.message || 'Save failed'),
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
                canEdit ? (
                    <Space>
                        <Button size="small" type="primary" onClick={() => {
                            form.setFieldsValue({
                                ...r,
                                effectiveFrom: r.effectiveFrom ? dayjs(r.effectiveFrom) : undefined,
                                effectiveTo: r.effectiveTo ? dayjs(r.effectiveTo) : undefined,
                            });
                            setEditingId(r.id);
                            setCreateModal(true);
                        }}>Edit</Button>
                        {r.isActive && (
                            <Button size="small" danger onClick={() => deactivateMut.mutate(r.id)}>
                                Deactivate
                            </Button>
                        )}
                    </Space>
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
                        onClick={() => {
                            form.resetFields();
                            setEditingId(null);
                            form.setFieldsValue({ rateType: 'PERCENTAGE', country: 'KE' });
                            setCreateModal(true);
                        }}
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
                title={editingId ? "Edit Tax Configuration" : "New Tax Configuration"}
                open={createModal}
                onCancel={() => setCreateModal(false)}
                onOk={() => form.submit()}
                confirmLoading={saveMut.isPending}
                width={700}
            >
                <Form form={form} layout="vertical" onFinish={(v) => saveMut.mutate(v)}>
                    <Space style={{ width: '100%' }}>
                        <Form.Item label="Tax Type" name="taxType" rules={[{ required: true }]}>
                            <Select style={{ width: 140 }} disabled={!!editingId}>
                                {['PAYE', 'NHIF', 'NSSF', 'SHIF', 'HOUSING_LEVY', 'VAT'].map((t) => (
                                    <Select.Option key={t} value={t}>{t}</Select.Option>
                                ))}
                            </Select>
                        </Form.Item>
                        <Form.Item label="Country" name="country" initialValue="KE" rules={[{ required: true }]}>
                            <Input style={{ width: 80 }} disabled={!!editingId} />
                        </Form.Item>
                    </Space>
                    <Form.Item label="Rate Type" name="rateType" initialValue="PERCENTAGE" rules={[{ required: true }]}>
                        <Select style={{ width: '100%' }}>
                            {['PERCENTAGE', 'GRADUATED', 'TIERED', 'BANDED'].map((t) => (
                                <Select.Option key={t} value={t}>{t}</Select.Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                        Use extreme caution when editing existing configurations. Previous pay periods will not retroactively apply these changes.
                    </Typography.Text>

                    {rateType === 'PERCENTAGE' && (
                        <>
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
                        </>
                    )}

                    {rateType === 'GRADUATED' && (
                        <div style={{ padding: 16, background: '#fafafa', borderRadius: 8, marginBottom: 16 }}>
                            <Form.Item label="Personal Relief (KES)" name={['configuration', 'personalRelief']}>
                                <InputNumber min={0} style={{ width: '100%' }} />
                            </Form.Item>
                            <Typography.Title level={5}>Brackets</Typography.Title>
                            <Form.List name={['configuration', 'brackets']}>
                                {(fields, { add, remove }) => (
                                    <>
                                        {fields.map(({ key, name, ...restField }) => (
                                            <Space key={key} style={{ display: 'flex', marginBottom: 8 }} align="baseline" wrap>
                                                <Form.Item {...restField} name={[name, 'from']} rules={[{ required: true, message: 'Missing from' }]}>
                                                    <InputNumber placeholder="From (KES)" min={0} />
                                                </Form.Item>
                                                <Form.Item {...restField} name={[name, 'to']}>
                                                    <InputNumber placeholder="To (KES)" min={0} />
                                                </Form.Item>
                                                <Form.Item {...restField} name={[name, 'rate']} rules={[{ required: true, message: 'Missing rate' }]}>
                                                    <InputNumber placeholder="Rate (0-1)" min={0} max={1} step={0.01} />
                                                </Form.Item>
                                                <DeleteOutlined onClick={() => remove(name)} style={{ color: 'red', cursor: 'pointer' }} />
                                            </Space>
                                        ))}
                                        <Form.Item>
                                            <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                                                Add Bracket
                                            </Button>
                                        </Form.Item>
                                    </>
                                )}
                            </Form.List>
                        </div>
                    )}

                    {rateType === 'TIERED' && (
                        <div style={{ padding: 16, background: '#fafafa', borderRadius: 8, marginBottom: 16 }}>
                            <Typography.Title level={5}>Tiers</Typography.Title>
                            <Form.List name={['configuration', 'tiers']}>
                                {(fields, { add, remove }) => (
                                    <>
                                        {fields.map(({ key, name, ...restField }) => (
                                            <div key={key} style={{ border: '1px solid #f0f0f0', padding: 16, marginBottom: 16, borderRadius: 8, background: '#fff' }}>
                                                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                                                    <strong>Tier {name + 1}</strong>
                                                    <DeleteOutlined onClick={() => remove(name)} style={{ color: 'red', cursor: 'pointer' }} />
                                                </div>
                                                <Space wrap>
                                                    <Form.Item {...restField} name={[name, 'name']} rules={[{ required: true, message: 'Missing' }]}>
                                                        <Input placeholder="Tier Name (e.g. Band 1)" />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'salaryFrom']} rules={[{ required: true, message: 'Missing' }]}>
                                                        <InputNumber placeholder="Salary From (KES)" min={0} />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'salaryTo']}>
                                                        <InputNumber placeholder="Salary To (KES)" min={0} />
                                                    </Form.Item>
                                                </Space>
                                                <Space wrap>
                                                    <Form.Item {...restField} name={[name, 'rate']}>
                                                        <InputNumber placeholder="Rate (0-1)" min={0} max={1} step={0.01} />
                                                    </Form.Item>
                                                    <Form.Item {...restField} name={[name, 'amount']}>
                                                        <InputNumber placeholder="Fixed Amount (KES)" min={0} />
                                                    </Form.Item>
                                                </Space>
                                            </div>
                                        ))}
                                        <Form.Item>
                                            <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                                                Add Tier
                                            </Button>
                                        </Form.Item>
                                    </>
                                )}
                            </Form.List>
                        </div>
                    )}
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
