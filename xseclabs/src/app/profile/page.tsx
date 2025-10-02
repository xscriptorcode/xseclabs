'use client';

import { useAuth } from '../contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import UserProfile from '../components/profile/UserProfile';

export default function ProfilePage() {
    const { user, loading } = useAuth();
    const router = useRouter();

    useEffect(() => {
        if (!loading && !user) {
            router.push('/login');
        }
    }, [user, loading, router]);

    if (loading) {
        return (
            <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '100vh',
                backgroundColor: 'var(--color-background)',
                color: 'var(--color-text)'
            }}>
                <div>Loading...</div>
            </div>
        );
    }

    if (!user) {
        return null;
    }

    return (
        <div style={{
            minHeight: '100vh',
            backgroundColor: 'var(--color-background)',
            padding: '2rem',
            paddingTop: window.innerWidth >= 1024 ? '6rem' : '2rem',
            display: 'flex',
            alignItems: window.innerWidth >= 1024 ? 'center' : 'flex-start'
        }}
        >
            <div style={{
                maxWidth: '1200px',
                margin: '0 auto',
                width: '100%'
            }}>
                
                <UserProfile userId={user.id} onProfileUpdate={() => {}} />
            </div>
        </div>
    );
}