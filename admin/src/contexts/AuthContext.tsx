import React, { createContext, useContext, useState, useCallback } from 'react';
import { adminAuth } from '../api/client';

interface User {
    id: string;
    email: string;
    role: string;
}

interface AuthContextType {
    user: User | null;
    login: (email: string, password: string) => Promise<void>;
    logout: () => void;
    isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const storedUser = localStorage.getItem('admin_user');
    const [user, setUser] = useState<User | null>(
        storedUser ? JSON.parse(storedUser) : null,
    );

    const login = useCallback(async (email: string, password: string) => {
        const data = await adminAuth.login(email, password);
        // Backend returns { access_token: '...' } (snake_case)
        const token = data.accessToken || data.access_token;
        if (!token) throw new Error('Invalid response from server');

        const payload = JSON.parse(atob(token.split('.')[1]));
        const validRoles = ['SUPER_ADMIN', 'ADMIN', 'VIEWER'];
        if (!validRoles.includes(payload.role)) {
            throw new Error('Access denied: Admin role required');
        }

        localStorage.setItem('admin_token', token);
        const userObj = { id: payload.sub, email: payload.email || email, role: payload.role };
        localStorage.setItem('admin_user', JSON.stringify(userObj));
        setUser(userObj);
    }, []);

    const logout = useCallback(() => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setUser(null);
    }, []);

    return (
        <AuthContext.Provider value={{ user, login, logout, isAuthenticated: !!user }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
    return ctx;
};
