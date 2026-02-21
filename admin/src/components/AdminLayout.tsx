import { Layout, Menu, Avatar, Dropdown, theme } from 'antd';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
    DashboardOutlined,
    UserOutlined,
    TeamOutlined,
    TransactionOutlined,
    CalendarOutlined,
    CrownOutlined,
    FileTextOutlined,
    CustomerServiceOutlined,
    LogoutOutlined,
    HeartOutlined,
    SettingOutlined,
    HistoryOutlined,
    NotificationOutlined,
    ContainerOutlined,
} from '@ant-design/icons';
import { useAuth } from '../contexts/AuthContext';

const { Sider, Header, Content } = Layout;

const menuItems = [
    { key: '/', icon: <DashboardOutlined />, label: 'Dashboard' },
    { key: '/infra', icon: <HeartOutlined />, label: 'Infrastructure' },
    { type: 'divider' as const },
    { key: '/users', icon: <UserOutlined />, label: 'Employers' },
    { key: '/workers', icon: <TeamOutlined />, label: 'Workers' },
    { key: '/transactions', icon: <TransactionOutlined />, label: 'Transactions' },
    { key: '/payroll', icon: <CalendarOutlined />, label: 'Payroll' },
    { type: 'divider' as const },
    { key: '/plans', icon: <CrownOutlined />, label: 'Subscription Plans' },
    { key: '/tax-configs', icon: <FileTextOutlined />, label: 'Tax Configs' },
    { key: '/support', icon: <CustomerServiceOutlined />, label: 'Support Tickets' },
    { key: '/settings', icon: <SettingOutlined />, label: 'System Settings' },
    { key: '/logs', icon: <ContainerOutlined />, label: 'Logs' },
    { key: '/audit-logs', icon: <HistoryOutlined />, label: 'Audit Logs' },
    { key: '/notifications', icon: <NotificationOutlined />, label: 'Notifications' },
];

export default function AdminLayout() {
    const navigate = useNavigate();
    const location = useLocation();
    const { user, logout } = useAuth();
    const { token } = theme.useToken();

    const selectedKey = menuItems.find(
        (m) => m.key && m.key !== '/' && location.pathname.startsWith(m.key)
    )?.key || '/';

    return (
        <Layout style={{ minHeight: '100vh' }}>
            <Sider
                theme="dark"
                width={220}
                style={{ background: '#0f172a', position: 'fixed', height: '100vh', left: 0, top: 0 }}
            >
                {/* Logo */}
                <div style={{
                    padding: '20px 16px',
                    fontSize: 20,
                    fontWeight: 700,
                    color: '#6366f1',
                    letterSpacing: '-0.5px',
                }}>
                    PayDome Admin
                </div>

                <Menu
                    theme="dark"
                    mode="inline"
                    selectedKeys={[selectedKey]}
                    style={{ background: '#0f172a', border: 'none' }}
                    onClick={({ key }) => navigate(key)}
                    items={menuItems as any}
                />
            </Sider>

            <Layout style={{ marginLeft: 220 }}>
                <Header style={{
                    background: '#fff',
                    padding: '0 24px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'flex-end',
                    borderBottom: `1px solid ${token.colorBorderSecondary}`,
                    boxShadow: '0 1px 3px rgba(0,0,0,.06)',
                }}>
                    <Dropdown
                        menu={{
                            items: [
                                {
                                    key: 'logout',
                                    icon: <LogoutOutlined />,
                                    label: 'Sign out',
                                    onClick: () => { logout(); window.location.href = '/login'; },
                                },
                            ],
                        }}
                    >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                            <Avatar icon={<UserOutlined />} style={{ background: '#6366f1' }} />
                            <span style={{ fontWeight: 500 }}>{user?.email}</span>
                        </div>
                    </Dropdown>
                </Header>

                <Content style={{ padding: '24px', background: '#f8fafc', minHeight: 'calc(100vh - 64px)' }}>
                    <Outlet />
                </Content>
            </Layout>
        </Layout>
    );
}
