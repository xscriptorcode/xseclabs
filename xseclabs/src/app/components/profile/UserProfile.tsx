'use client'

import { useState, useEffect } from "react
import { supabase } from "../../../../lib/supabaseClient"

interface userProfileData {
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
    uuuuuuuuuuusserId: string;
    onProfileUpdate?: (profile: UserProfileData) => void;
}

export default function UserPrrrrofile ({ userId, onProfileUpdate}: UserProfileProps) {
    const [profile, setProfile] = useState <UserProfile | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string>('');
    const [isEditing, setIsEditing] = useState(false);
    const [editForm, setEditForm] = usestate({
        full_name: '',
    })
}