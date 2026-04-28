import { Layout, Menu, Avatar, Dropdown, theme, Badge, Drawer } from 'antd';
import { useState, useEffect } from 'react';
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
import { useQuery } from '@tanstack/react-query';
import { adminSupport } from '../api/client';

const { Sider, Header, Content } = Layout;

// ─── Responsive helpers ──────────────────────────────────────────────────────
function useIsMobile(breakpoint = 768) {
    const [mobile, setMobile] = useState(false);
    useEffect(() => {
        const mq = window.matchMedia(`(max-width: ${breakpoint}px)`);
        setMobile(mq.matches);
        const handler = (e: MediaQueryListEvent) => setMobile(e.matches);
        mq.addEventListener('change', handler);
        return () => mq.removeEventListener('change', handler);
    }, [breakpoint]);
    return mobile;
}

export default function AdminLayout() {
    const navigate = useNavigate();
    const location = useLocation();
    const { user, logout } = useAuth();
    const { token } = theme.useToken();
    const isMobile = useIsMobile();
    const [drawerOpen, setDrawerOpen] = useState(false);

    // Fetch open ticket count for badge
    const { data: supportData } = useQuery({
        queryKey: ['admin-support-open-count'],
        queryFn: () => adminSupport.list({ status: 'OPEN', page: 1 }),
        refetchInterval: 60000,
        staleTime: 30000,
    });
    const openTickets = supportData?.total || 0;

    // Determine selected key — match /users/:id -> /users, etc.
    const selectedKey = (() => {
        if (location.pathname === '/') return '/';
        const match = [
            '/infra', '/users', '/workers', '/transactions', '/payroll',
            '/plans', '/tax-configs', '/support', '/settings', '/logs', '/audit-logs', '/notifications',
        ].find(k => location.pathname.startsWith(k));
        return match || '/';
    })();

    const menuItems = [
        {
            key: '/',
            icon: <DashboardOutlined />,
            label: 'Dashboard',
        },
        {
            key: '/infra',
            icon: <HeartOutlined />,
            label: 'Infrastructure',
        },
        { type: 'divider' as const },
        {
            key: '/users',
            icon: <UserOutlined />,
            label: 'Employers',
        },
        {
            key: '/workers',
            icon: <TeamOutlined />,
            label: 'Workers',
        },
        {
            key: '/transactions',
            icon: <TransactionOutlined />,
            label: 'Transactions',
        },
        {
            key: '/payroll',
            icon: <CalendarOutlined />,
            label: 'Payroll',
        },
        { type: 'divider' as const },
        {
            key: '/plans',
            icon: <CrownOutlined />,
            label: 'Subscription Plans',
        },
        {
            key: '/tax-configs',
            icon: <FileTextOutlined />,
            label: 'Tax Configs',
        },
        {
            key: '/support',
            icon: (
                <Badge count={openTickets} size="small" offset={[6, 0]} style={{ fontSize: 10 }}>
                    <CustomerServiceOutlined />
                </Badge>
            ),
            label: (
                <span style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    Support Tickets
                    {openTickets > 0 && (
                        <Badge
                            count={openTickets}
                            size="small"
                            style={{ background: '#ef4444', fontSize: 10, marginLeft: 8 }}
                        />
                    )}
                </span>
            ),
        },
        {
            key: '/settings',
            icon: <SettingOutlined />,
            label: 'System Settings',
        },
        {
            key: '/logs',
            icon: <ContainerOutlined />,
            label: 'Logs',
        },
        {
            key: '/audit-logs',
            icon: <HistoryOutlined />,
            label: 'Audit Logs',
        },
        {
            key: '/notifications',
            icon: <NotificationOutlined />,
            label: 'Notifications',
        },
    ];

    return (
        <Layout style={{ minHeight: '100vh' }}>
            {/* Desktop sidebar — hidden on mobile */}
            {!isMobile && (
                <Sider
                    theme="dark"
                    width={224}
                    breakpoint="lg"
                    collapsedWidth={0}
                    onCollapse={() => {}}
                    style={{ background: '#0f172a', position: 'fixed', height: '100vh', left: 0, top: 0, overflowY: 'auto' }}
                >
                {/* Logo */}
                <div style={{
                    padding: '20px 16px 16px',
                    fontSize: 18,
                    fontWeight: 700,
                    color: '#6366f1',
                    letterSpacing: '-0.5px',
                    borderBottom: '1px solid rgba(255,255,255,0.07)',
                    marginBottom: 4,
                }}>
                    PayDome Admin
                    <div style={{ fontSize: 11, color: '#475569', fontWeight: 400, marginTop: 2 }}>
                        {user?.role}
                    </div>
                </div>

                    <Menu
                        theme="dark"
                        mode="inline"
                        selectedKeys={[selectedKey]}
                        style={{ background: '#0f172a', border: 'none', paddingTop: 4 }}
                        onClick={({ key }) => navigate(key)}
                        items={menuItems as any}
                    />
                </Sider>
            )}

            {/* Mobile drawer */}
            <Drawer
                title={<span style={{ color: '#6366f1', fontWeight: 700, fontSize: 16 }}>PayDome Admin</span>}
                placement="left"
                width={260}
                onClose={() => setDrawerOpen(false)}
                open={drawerOpen}
                styles={{ body: { padding: 0, background: '#0f172a' } }}
                closable
            >
                <Menu
                    theme="dark"
                    mode="inline"
                    selectedKeys={[selectedKey]}
                    style={{ background: '#0f172a', border: 'none', paddingTop: 4 }}
                    onClick={({ key }) => { navigate(key); setDrawerOpen(false); }}
                    items={menuItems as any}
                />
            </Drawer>

            <Layout style={{ marginLeft: isMobile ? 0 : 224 }}>
                <Header style={{
                    background: '#fff',
                    padding: isMobile ? '0 16px' : '0 24px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: isMobile ? 'space-between' : 'flex-end',
                    borderBottom: `1px solid ${token.colorBorderSecondary}`,
                    boxShadow: '0 1px 3px rgba(0,0,0,.06)',
                    position: 'sticky',
                    top: 0,
                    zIndex: 100,
                }}>
                    {/* Hamburger — only on mobile */}
                    {isMobile && (
                        <button
                            onClick={() => setDrawerOpen(true)}
                            style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 8, fontSize: 20, color: '#475569', lineHeight: 1 }}
                            aria-label="Open menu"
                        >
                            <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                                <path d="M3 5h14M3 10h14M3 15h14" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/>
                            </svg>
                        </button>
                    )}
                    <Dropdown
                        menu={{
                            items: [
                                {
                                    key: 'email',
                                    label: <span style={{ color: '#64748b', fontSize: 12 }}>{user?.email}</span>,
                                    disabled: true,
                                },
                                { type: 'divider' as const },
                                {
                                    key: 'logout',
                                    icon: <LogoutOutlined />,
                                    label: 'Sign out',
                                    danger: true,
                                    onClick: () => { logout(); window.location.href = '/login'; },
                                },
                            ],
                        }}
                    >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', padding: '4px 8px', borderRadius: 8 }}>

                            <Avatar icon={<UserOutlined />} style={{ background: '#6366f1' }} size="small" />
                            <span style={{ fontWeight: 500, fontSize: 14 }}>{user?.email?.split('@')[0]}</span>
                        </div>
                    </Dropdown>
                </Header>

                <Content style={{ padding: isMobile ? '16px' : '24px', background: '#f8fafc', minHeight: 'calc(100vh - 64px)' }}>
                    <Outlet />
                </Content>
            </Layout>
        </Layout>
    );
}
