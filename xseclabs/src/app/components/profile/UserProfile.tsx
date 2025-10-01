'use client'
import { useState, useEffect } from 'react'
import { supabase } from '../../../../lib/supabaseClient'

interface UserProfileData {
    id_uuid: string;
    full_name: string | null;
    username: string | null;
    avatar_url: string | null;
    bio: string | null;
    created_at: string;
    updated_at: string;
    last_login: string | null;
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

            // Usar una consulta más simple que evite problemas con RLS
            const { data, error } = await supabase
                .from('user_profiles')
                .select(`
                    id_uuid,
                    full_name,
                    username,
                    avatar_url,
                    bio,
                    created_at,
                    updated_at,
                    last_login
                `)
                .eq('id_uuid', userId)
                .single();

            if (error) {
                console.error('Profile fetch error:', error);
                setError('Error al cargar el perfil: ' + error.message);
                return;
            }

            setProfile(data);
            setEditForm({
                full_name: data.full_name || '',
                username: data.username || '',
                bio: data.bio || '',
                avatar_url: data.avatar_url || ''
            });

            if (onProfileUpdate) {
                onProfileUpdate(data);
            }
        } catch (err) {
            console.error('Unexpected error fetching profile:', err);
            setError('Error inesperado al cargar el perfil');
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async () => {
        try {
            setLoading(true);
            setError('');

            // Validaciones básicas
            if (!editForm.full_name.trim()) {
                setError('El nombre completo es requerido');
                setLoading(false);
                return;
            }

            if (!editForm.username.trim()) {
                setError('El nombre de usuario es requerido');
                setLoading(false);
                return;
            }

            // Verificar que el username no esté en uso por otro usuario
            const { data: existingUser, error: checkError } = await supabase
                .from('user_profiles')
                .select('id_uuid')
                .eq('username', editForm.username.trim())
                .neq('id_uuid', userId)
                .single();

            if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows found
                setError('Error al verificar el nombre de usuario');
                setLoading(false);
                return;
            }

            if (existingUser) {
                setError('Este nombre de usuario ya está en uso');
                setLoading(false);
                return;
            }

            const { data, error } = await supabase
                .from('user_profiles')
                .update({
                    full_name: editForm.full_name.trim(),
                    username: editForm.username.trim(),
                    bio: editForm.bio.trim() || null,
                    avatar_url: editForm.avatar_url.trim() || null,
                    updated_at: new Date().toISOString()
                })
                .eq('id_uuid', userId)
                .select()
                .single();

            if (error) {
                setError('Error al actualizar el perfil: ' + error.message);
                return;
            }

            setProfile(data);
            setIsEditing(false);

            if (onProfileUpdate) {
                onProfileUpdate(data);
            }
        } catch (err) {
            setError('Error inesperado al actualizar el perfil');
            console.error('Error updating profile:', err);
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateString: string | null) => {
        if (!dateString) return 'No disponible';
        return new Date(dateString).toLocaleString('es-ES', {
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
                    <div style={{ color: 'var(--color-muted)' }}>Cargando perfil...</div>
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
            <div className="flex justify-between items-center mb-6">
                <h2 style={{ color: 'var(--color-text)', margin: 0 }}>
                    Perfil de Usuario
                </h2>
                <button
                    onClick={() => setIsEditing(!isEditing)}
                    disabled={loading}
                    style={{
                        backgroundColor: isEditing ? 'var(--color-accent)' : 'var(--color-primary)',
                        fontSize: '0.875rem',
                        padding: '0.5rem 1rem'
                    }}
                >
                    {isEditing ? 'Cancelar' : 'Editar'}
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
                /* Vista de solo lectura */
                <div className="space-y-6">
                    {/* Avatar y nombre */}
                    <div className="flex items-center space-x-4">
                        <div 
                            className="w-20 h-20 rounded-full flex items-center justify-center text-2xl font-bold"
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
                        <div>
                            <h3 style={{ color: 'var(--color-text)', margin: '0 0 0.5rem 0' }}>
                                {profile?.full_name || 'Sin nombre'}
                            </h3>
                            <p style={{ color: 'var(--color-muted)', margin: 0 }}>
                                @{profile?.username || 'sin-usuario'}
                            </p>
                        </div>
                    </div>

                    {/* Bio */}
                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Biografía
                        </label>
                        <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0' }}>
                            {profile?.bio || 'Sin biografía'}
                        </p>
                    </div>

                    {/* Información adicional */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                Último acceso
                            </label>
                            <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                {formatDate(profile?.last_login)}
                            </p>
                        </div>
                        <div>
                            <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                                Miembro desde
                            </label>
                            <p style={{ color: 'var(--color-text)', margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>
                                {formatDate(profile?.created_at)}
                            </p>
                        </div>
                    </div>
                </div>
            ) : (
                /* Vista de edición */
                <div className="space-y-4">
                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Nombre completo *
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
                            placeholder="Ingresa tu nombre completo"
                            required
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Nombre de usuario *
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
                            placeholder="usuario123"
                            required
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            URL del avatar
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
                            placeholder="https://ejemplo.com/avatar.jpg"
                        />
                    </div>

                    <div>
                        <label style={{ color: 'var(--color-muted)', fontSize: '0.875rem', fontWeight: '500' }}>
                            Biografía
                        </label>
                        <textarea
                            value={editForm.bio}
                            onChange={(e) => setEditForm({ ...editForm, bio: e.target.value })}
                            className="w-full mt-1 p-3 rounded-lg"
                            style={{
                                backgroundColor: 'var(--color-bg)',
                                border: '1px solid var(--color-border)',
                                color: 'var(--color-text)',
                                minHeight: '100px',
                                resize: 'vertical'
                            }}
                            placeholder="Cuéntanos sobre ti..."
                        />
                    </div>

                    <div className="flex space-x-3 pt-4">
                        <button
                            onClick={handleUpdateProfile}
                            disabled={loading}
                            style={{
                                backgroundColor: 'var(--color-primary)',
                                flex: 1
                            }}
                        >
                            {loading ? 'Guardando...' : 'Guardar Cambios'}
                        </button>
                        <button
                            onClick={() => {
                                setIsEditing(false);
                                setError('');
                                setEditForm({
                                    full_name: profile?.full_name || '',
                                    username: profile?.username || '',
                                    bio: profile?.bio || '',
                                    avatar_url: profile?.avatar_url || ''
                                });
                            }}
                            style={{
                                backgroundColor: 'var(--color-muted)',
                                flex: 1
                            }}
                        >
                            Cancelar
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}