'use client';

import React, { useState } from 'react';
import { supabase } from "../../../../lib/supabaseClient";
import { useRouter } from "next/navigation";
import FormContainer from '../ui/FormContainer';
import FormInput from '../ui/FormInput';
import FormButton from '../ui/FormButton';
import ErrorMessage from '../ui/ErrorMessage';
import FormLink from '../ui/FormLink';

export default function Login() {
    const [emailOrUsername, setEmailOrUsername] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const router = useRouter();

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError("");

        try {
            let loginData;
            
            // Check if input is email or username
            const isEmail = emailOrUsername.includes('@');
            
            if (isEmail) {
                // Login with email
                loginData = await supabase.auth.signInWithPassword({
                    email: emailOrUsername,
                    password: password,
                });
            } else {
                // Login with username - first get the user data from user_profiles
                const { data: profileData, error: profileError } = await supabase
                    .from('user_profiles')
                    .select('id_uuid, full_name')
                    .eq('username', emailOrUsername)
                    .single();

                if (profileError || !profileData) {
                    setError('Non-existent user, please check.');
                    setLoading(false);
                    return;
                }

                // Get the email from users table
                const { data: userData, error: userError } = await supabase
                    .from('users')
                    .select('email')
                    .eq('id_uuid', profileData.id_uuid)
                    .single();

                if (userError || !userData) {
                    setError('Error getting user data');
                    setLoading(false);
                    return;
                }

                // Now try to login with the found email
                loginData = await supabase.auth.signInWithPassword({
                    email: userData.email,
                    password: password,
                });
            }

            const { data, error } = loginData;

            if (error) {
                if (error.message.includes('Invalid login credentials')) {
                    setError('Credenciales incorrectas. Verifica tu email/usuario y contraseña.');
                } else {
                    setError('Error al iniciar sesión: ' + error.message);
                }
            } else {
                // Update last_login in user_profiles
                if (data.user) {
                    await supabase
                        .from('user_profiles')
                        .update({ 
                            last_login: new Date().toISOString(),
                            updated_at: new Date().toISOString()
                        })
                        .eq('id_uuid', data.user.id);
                }
                
                // Redirect to dashboard with user info
                router.push('/dashboard');
            }
        } catch (err) {
            setError('Unexpected error');
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <FormContainer title="Sign In">
            <ErrorMessage message={error} />
            
            <form onSubmit={handleLogin} className="flex flex-col gap-2 w-full">
                <FormInput
                    type="text"
                    placeholder="Email or username"
                    value={emailOrUsername}
                    onChange={(e) => setEmailOrUsername(e.target.value)}
                    required
                />
                
                <FormInput
                    type="password"
                    placeholder="Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                />
                
                <FormButton 
                    type="submit"
                    disabled={loading}
                    loading={loading}
                    loadingText="Signing in..."
                >
                    Sign In
                </FormButton>
            </form>
            
            <FormLink 
                text="Don't have an account?"
                linkText="Register"
                href="/register"
            />
            
            <FormLink 
                text="Forgot your password?"
                linkText="Recover"
                href="#"
            />
        </FormContainer>
    );
}