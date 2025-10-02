'use client'
import { useState, useEffect } from 'react'
import { supabase } from '../../../../lib/supabaseClient'
import ClipboardIcon from '../icons/clipboard';

interface UserProfileData {
    id_uuid: string;
    full_name: string | null;
    username: string | null;
    email: string | null;
    phone: string | null;
    avatar_url: string | null;
    bio: string | null;
    plan: string;
    created_at: string;
    updated_at: string;
    last_login: string | null;
    role_type?: string;
    role_description?: string;
}

interface UserProfileProps {
    userId: string;
    onProfileUpdate?: (profile: UserProfileData) => void;
}

export default function UserProfile({ userId, onProfileUpdate }: UserProfileProps) {
    const [profile, setProfile] = useState<UserProfileData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string>('');
    const [isEditing, setIsEditing] = useState(false);
    const [editForm, setEditForm] = useState({
        full_name: '',
        username: '',
        bio: '',
        phone: '',
        avatar_url: ''
    });

    useEffect(() => {
        if (userId) {
            fetchProfile();
        }
    }, [userId]);

    const fetchProfile = async () => {
        try {
            setLoading(true);
            setError('');

            // Obtener el email del usuario autenticado
            const { data: { user }, error: authError } = await supabase.auth.getUser();
            
            if (authError) {
                console.error('Auth error:', authError);
                setError('Error getting user: ' + authError.message);
                return;
            }

            const { data, error } = await supabase
            .from('user_profiles')
            .select(`
                id_uuid,
                full_name,
                username,
                avatar_url,
                bio,
                phone,
                plan,
                created_at,
                updated_at,
                last_login,
                users!inner(
                    roles_id,
                    is_active,
                    roles(
                        type,
                        description
                    )
                )
            `)
            .eq('id_uuid', userId)
            .single();

            if (error) {
                console.error('Profile fetch error:', error);
                setError('Error loading profile: ' + error.message);
                return;
            }

            // Transform the data to include role information
            const profileData: UserProfileData = {
                ...data,
                email: user?.email || null, // Obtener email del usuario autenticado
                role_type: data.users?.[0]?.roles?.[0]?.type,
                role_description: data.users?.[0]?.roles?.[0]?.description
            };

            setProfile(profileData);
            setEditForm({
                full_name: profileData.full_name || '',
                username: profileData.username || '',
                bio: profileData.bio || '',
                phone: profileData.phone || '',
                avatar_url: profileData.avatar_url || ''
            });

            if (onProfileUpdate) {
                onProfileUpdate(profileData);
            }
        } catch (err) {
            console.error('Unexpected error fetching profile:', err);
            setError('Unexpected error loading profile');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async () => {
        try {
            setLoading(true);
            setError('');

            // Basic validations
            if (!editForm.full_name.trim()) {
                setError('Full name is required');
                setLoading(false);
                return;
            }

            if (!editForm.username.trim()) {
                setError('Username is required');
                setLoading(false);
                return;
            }

            // Check if username is already in use by another user
            const { data: existingUser, error: checkError } = await supabase
                .from('user_profiles')
                .select('id_uuid')
                .eq('username', editForm.username.trim())
                .neq('id_uuid', userId)
                .single();

            if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows found
                setError('Error verifying username');
                setLoading(false);
                return;
            }

            if (existingUser) {
                setError('This username is already in use');
                setLoading(false);
                return;
            }

            const { data, error } = await supabase
                .from('user_profiles')
                .update({
                    full_name: editForm.full_name.trim(),
                    username: editForm.username.trim(),
                    bio: editForm.bio.trim() || null,
                    phone: editForm.phone.trim() || null,
                    avatar_url: editForm.avatar_url.trim() || null,
                    updated_at: new Date().toISOString()
                })
                .eq('id_uuid', userId)
                .select()
                .single();

            if (error) {
                setError('Error updating profile: ' + error.message);
                return;
            }

            setProfile(data);
            setIsEditing(false);

            if (onProfileUpdate) {
                onProfileUpdate(data);
            }
        } catch (err) {
            setError('Unexpected error updating profile');
            console.error('Error updating profile:', err);
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateString: string | null) => {
        if (!dateString) return 'Not available';
        return new Date(dateString).toLocaleString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    if (loading && !profile) {
        return (
            <div className="card p-6" style={{ backgroundColor: 'var(--color-surface)' }}>
                <div className="flex justify-center items-center">
                    <div style={{ color: 'var(--color-muted)' }}>Loading profile...</div>
                </div>
            </div>
        );
    }

    if (error && !profile) {
        return (
            <div className="card p-6" style={{ backgroundColor: 'var(--color-surface)' }}>
                <div className="text-center" style={{ color: 'var(--color-accent)' }}>
                    {error}
                </div>
            </div>
        );
    }

    return (
        <div className="card p-6" style={{ backgroundColor: 'var(--color-surface)' }}>
            {/* Header */}
            <div className="flex justify-end items-center mb-6">
                <button
                    onClick={() => setIsEditing(!isEditing)}
                    disabled={loading}
                    style={{
                        backgroundColor: isEditing ? 'var(--color-accent)' : 'var(--color-primary)',
                        color: 'white',
                        fontSize: '0.875rem',
                        padding: '0.5rem 1rem',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: 'pointer'
                    }}
                >
                    {isEditing ? 'Cancel' : 'Edit'}
                </button>
            </div>

            {error && (
                <div 
                    className="mb-4 p-3 rounded-lg text-center"
                    style={{ 
                        backgroundColor: 'rgba(249, 115, 22, 0.1)',
                        color: 'var(--color-accent)',
                        border: '1px solid var(--color-accent)'
                    }}
                >
                    {error}
                </div>
            )}

            {!isEditing ? (
                /* Read-only view */
                <div className="space-y-6">
                    {/* Avatar and basic info - responsive layout */}
                    <div className="flex flex-col lg:flex-row lg:items-start lg:space-x-8 space-y-6 lg:space-y-0">
                        {/* Avatar */}
                        <div className="flex-shrink-0 flex justify-center lg:justify-start">
                            <div 
                                className="w-32 h-32 lg:w-60 lg:h-60 rounded-full flex items-center justify-center text-2xl font-bold"
                                style={{ 
                                    backgroundColor: 'var(--color-primary)',
                                    color: 'white'
                                }}
                            >
                                {profile?.avatar_url ? (
                                    <img 
                                        src={profile.avatar_url} 
                                        alt="Avatar" 
                                        className="w-full h-full rounded-full object-cover"
                                    />
                                ) : (
                                    profile?.full_name?.charAt(0)?.toUpperCase() || '?'
                                )}
                            </div>
                        </div>

                        {/* Profile information */}
                        <div className="flex-1 space-y-6">
                            {/* Name and username */}
                            <div className="text-center lg:text-left">
                                <h3 style={{ color: 'var(--color-text)', margin: '0 0 0.5rem 0', fontSize: '1.5rem', fontWeight: '600' }}>
                                    {profile?.full_name || 'No name'}
                                </h3>
                                <div className="flex flex-col lg:flex-row lg:items-center lg:space-x-3 space-y-2 lg:space-y-0">
                                    <p style={{ color: 'var(--color-muted)', margin: 0, fontSize: '1rem' }}>
                                        @{profile?.username || 'no-username'}
                                    </p>
                                    {profile?.email && (
                                        <div className="flex items-center space-x-2">
                                            <span style={{ 
                                                color: 'var(--color-muted)', 
                                                fontSize: '0.875rem', 
                                                fontFamily: 'monospace',
                                                backgroundColor: 'var(--color-background-secondary)',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '0.25rem',
                                                border: '1px solid var(--color-border)'
                                            }}>
                                                {profile.email}
                                            </span>
                                            <button
                                                onClick={() => {
                                                    navigator.clipboard.writeText(profile.email!);
                                                    // Opcional: mostrar feedback visual
                                                    const button = event?.target as HTMLButtonElement;
                                                    const originalText = button.textContent;
                                                    button.textContent = '✓';
                                                    setTimeout(() => {
                                                        button.textContent = originalText;
                                                    }, 1000);
                                                }}
                                                style={{
                                                    backgroundColor: 'transparent',
                                                    border: '1px solid var(--color-border)',
                                                    borderRadius: '0.25rem',
                                                    padding: '0.25rem 0.5rem',
                                                    color: 'var(--color-muted)',
                                                    fontSize: '0.75rem',
                                                    cursor: 'pointer',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    justifyContent: 'center',
                                                    minWidth: '2rem',
                                                    height: '1.75rem'
                                                }}
                                                onMouseEnter={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'var(--color-background-secondary)';
                                                }}
                                                onMouseLeave={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'transparent';
                                                }}
                                                title="Copy email"
                                            >
                                                <ClipboardIcon className="w-4 h-4 text-[var(--color-text)]" />
                                            </button>
                                        </div>
                                    )}
                                    {profile?.phone && (
                                        <div className="flex items-center space-x-2">
                                            <span style={{ 
                                                color: 'var(--color-muted)', 
                                                fontSize: '0.875rem', 
                                                fontFamily: 'monospace',
                                                backgroundColor: 'var(--color-background-secondary)',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '0.25rem',
                                                border: '1px solid var(--color-border)'
                                            }}>
                                                {profile.phone}
                                            </span>
                                            <button
                                                onClick={() => {
                                                    navigator.clipboard.writeText(profile.phone!);
                                                    // Opcional: mostrar feedback visual
                                                    const button = event?.target as HTMLButtonElement;
                                                    const originalText = button.textContent;
                                                    button.textContent = '✓';
                                                    setTimeout(() => {
                                                        button.textContent = originalText;
                                                    }, 1000);
                                                }}
                                                style={{
                                                    backgroundColor: 'transparent',
                                                    border: '1px solid var(--color-border)',
                                                    borderRadius: '0.25rem',
                                                    padding: '0.25rem 0.5rem',
                                                    color: 'var(--color-muted)',
                                                    fontSize: '0.75rem',
                                                    cursor: 'pointer',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    justifyContent: 'center',
                                                    minWidth: '2rem',
                                                    height: '1.75rem'
                                                }}
                                                onMouseEnter={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'var(--color-background-secondary)';
                                                }}
                                                onMouseLeave={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'transparent';
                                                }}
                                                title="Copy phone number"
                                            >
                                                <ClipboardIcon className="w-4 h-4 text-[var(--color-text)]" />
                                            </button>
                                        </div>
                                    )}
                                    {profile?.id_uuid && (
                                        <div className="flex items-center space-x-2">
                                            <span style={{ 
                                                color: 'var(--color-muted)', 
                                                fontSize: '0.75rem', 
                                                fontFamily: 'monospace',
                                                backgroundColor: 'var(--color-background-secondary)',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '0.25rem',
                                                border: '1px solid var(--color-border)'
                                            }}>
                                                {profile.id_uuid}
                                            </span>
                                            <button
                                                onClick={() => {
                                                    navigator.clipboard.writeText(profile.id_uuid);
                                                    // Opcional: mostrar feedback visual
                                                    const button = event?.target as HTMLButtonElement;
                                                    const originalText = button.textContent;
                                                    button.textContent = '✓';
                                                    setTimeout(() => {
                                                        button.textContent = originalText;
                                                    }, 1000);
                                                }}
                                                style={{
                                                    backgroundColor: 'transparent',
                                                    border: '1px solid var(--color-border)',
                                                    borderRadius: '0.25rem',
                                                    padding: '0.25rem 0.5rem',
                                                    color: 'var(--color-muted)',
                                                    fontSize: '0.75rem',
                                                    cursor: 'pointer',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    justifyContent: 'center',
                                                    minWidth: '2rem',
                                                    height: '1.75rem'
                                                }}
                                                onMouseEnter={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'var(--color-background-secondary)';
                                                }}
                                                onMouseLeave={(e) => {
                                                    e.currentTarget.style.backgroundColor = 'transparent';
                                                }}
                                                title="Copy UUID"
                                            >
                                                    <ClipboardIcon className="w-4 h-4 text-[var(--color-text)]" />

                                            </button>
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Bio */}
                            <div style={{ width: '100%', maxWidth: '100%', overflow: 'hidden' }}>
                                <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                    Biography
                                </label>
                                <div style={{ 
                                    color: 'var(--color-text)', 
                                    margin: '0.5rem 0 0 0',
                                    width: '100%',
                                    maxWidth: '100%',
                                    wordBreak: 'break-all',
                                    overflowWrap: 'anywhere',
                                    whiteSpace: 'pre-wrap',
                                    lineHeight: '1.5',
                                    boxSizing: 'border-box'
                                }}>
                                    {profile?.bio || 'No biography'}
                                </div>
                            </div>

                            {/* Plan and Role */}
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                        Plan
                                    </label>
                                    <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                        <span 
                                            style={{ 
                                                backgroundColor: profile?.plan === 'free' ? 'var(--color-muted)' : 'var(--color-primary)',
                                                color: 'white',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '0.375rem',
                                                fontSize: '0.75rem',
                                                fontWeight: '500',
                                                textTransform: 'uppercase'
                                            }}
                                        >
                                            {profile?.plan || 'free'}
                                        </span>
                                    </p>
                                </div>
                                <div>
                                    <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                        Application Role
                                    </label>
                                    <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                        <span 
                                            style={{ 
                                                backgroundColor: 'var(--color-primary)',
                                                color: 'white',
                                                padding: '0.25rem 0.5rem',
                                                borderRadius: '0.375rem',
                                                fontSize: '0.75rem',
                                                fontWeight: '500',
                                                textTransform: 'capitalize'
                                            }}
                                        >
                                            {profile?.role_type || 'user'}
                                        </span>
                                        {profile?.role_description && (
                                            <span style={{ color: 'var(--color-muted)', marginLeft: '0.5rem', fontSize: '0.75rem' }}>
                                                - {profile.role_description}
                                            </span>
                                        )}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Additional information */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                Last login
                            </label>
                            <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                {formatDate(profile?.last_login ?? null)}
                            </p>
                        </div>
                        <div>
                            <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                Member since
                            </label>
                            <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                {formatDate(profile?.created_at ?? null)}
                            </p>
                        </div>
                        <div>
                            <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                Last updated
                            </label>
                            <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                {formatDate(profile?.updated_at ?? null)}
                            </p>
                        </div>
                    </div>
                </div>
            ) : (
                /* Edit view */
                <div className="space-y-4">
                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Full name *
                        </label>
                        <input
                            type="text"
                            value={editForm.full_name}
                            onChange={(e) => setEditForm({ ...editForm, full_name: e.target.value })}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)'
                            }}
                            placeholder="Enter your full name"
                            required
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Username *
                        </label>
                        <input
                            type="text"
                            value={editForm.username}
                            onChange={(e) => setEditForm({ ...editForm, username: e.target.value })}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)'
                            }}
                            placeholder="username123"
                            required
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Avatar URL
                        </label>
                        <input
                            type="url"
                            value={editForm.avatar_url}
                            onChange={(e) => setEditForm({ ...editForm, avatar_url: e.target.value })}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)'
                            }}
                            placeholder="https://example.com/avatar.jpg"
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Phone Number
                        </label>
                        <input
                            type="tel"
                            value={editForm.phone}
                            onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)'
                            }}
                            placeholder="+1 (555) 123-4567"
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Biography
                        </label>
                        <textarea
                            value={editForm.bio}
                            onChange={(e) => {
                                setEditForm({ ...editForm, bio: e.target.value });
                                // Auto-resize textarea
                                const textarea = e.target as HTMLTextAreaElement;
                                textarea.style.height = 'auto';
                                textarea.style.height = `${textarea.scrollHeight}px`;
                            }}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)',
                                minHeight: '100px',
                                resize: 'none',
                                overflow: 'hidden'
                            }}
                            placeholder="Tell us about yourself..."
                            onInput={(e) => {
                                // Additional auto-resize on input
                                const textarea = e.target as HTMLTextAreaElement;
                                textarea.style.height = 'auto';
                                textarea.style.height = `${textarea.scrollHeight}px`;
                            }}
                        />
                    </div>

                    <div className="flex space-x-3 pt-4">
                        <button
                            onClick={handleUpdateProfile}
                            disabled={loading}
                            style={{
                                backgroundColor: 'var(--color-primary)',
                                color: 'white',
                                border: 'none',
                                borderRadius: '0.5rem',
                                padding: '0.75rem 1.5rem',
                                cursor: 'pointer',
                                fontSize: '0.875rem',
                                fontWeight: '500',
                                flex: 1
                            }}
                        >
                            {loading ? 'Saving...' : 'Save Changes'}
                        </button>
                        <button
                            onClick={() => {
                                setIsEditing(false);
                                setError('');
                                setEditForm({
                                    full_name: profile?.full_name || '',
                                    username: profile?.username || '',
                                    bio: profile?.bio || '',
                                    phone: profile?.phone || '',
                                    avatar_url: profile?.avatar_url || ''
                                });
                            }}
                            style={{
                                backgroundColor: 'var(--color-muted)',
                                color: 'var(--color-text)',
                                border: 'none',
                                borderRadius: '0.5rem',
                                padding: '0.75rem 1.5rem',
                                cursor: 'pointer',
                                fontSize: '0.875rem',
                                fontWeight: '500',
                                flex: 1
                            }}
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}