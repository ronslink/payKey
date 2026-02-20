import { useState } from 'react';
import { Card, Form, Input, Button, Typography, Alert } from 'antd';
import { LockOutlined, MailOutlined } from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';

const { Title, Text } = Typography;

export default function LoginPage() {
    const { login } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const onFinish = async (values: { email: string; password: string }) => {
        setLoading(true);
        setError('');
        try {
            await login(values.email, values.password);
            // App.tsx handles redirect via isAuthenticated
        } catch (err: any) {
            setError(err?.response?.data?.message || err.message || 'Login failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            minHeight: '100vh',
            background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
        }}>
            <Card
                style={{ width: 400, borderRadius: 16, boxShadow: '0 25px 50px rgba(0,0,0,.3)' }}
                styles={{ body: { padding: 40 } }}
            >
                <div style={{ textAlign: 'center', marginBottom: 32 }}>
                    <div style={{ fontSize: 32, fontWeight: 800, color: '#6366f1', marginBottom: 4 }}>
                        PayDome
                    </div>
                    <Title level={4} style={{ margin: 0, color: '#334155' }}>Admin Console</Title>
                    <Text type="secondary">Sign in with your admin credentials</Text>
                </div>

                {error && <Alert title={error} type="error" style={{ marginBottom: 16 }} />}

                <Form onFinish={onFinish} layout="vertical" requiredMark={false}>
                    <Form.Item name="email" rules={[{ required: true, type: 'email' }]}>
                        <Input
                            prefix={<MailOutlined />}
                            placeholder="Admin email"
                            size="large"
                        />
                    </Form.Item>
                    <Form.Item name="password" rules={[{ required: true }]}>
                        <Input.Password
                            prefix={<LockOutlined />}
                            placeholder="Password"
                            size="large"
                        />
                    </Form.Item>
                    <Form.Item style={{ marginBottom: 0 }}>
                        <Button
                            type="primary"
                            htmlType="submit"
                            size="large"
                            block
                            loading={loading}
                            style={{ background: '#6366f1', borderColor: '#6366f1', fontWeight: 600 }}
                        >
                            Sign In
                        </Button>
                    </Form.Item>
                </Form>
            </Card>
        </div>
    );
}
