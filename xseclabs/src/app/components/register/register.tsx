'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '../../../../lib/supabaseClient';
import FormContainer from '../ui/FormContainer';
import FormInput from '../ui/FormInput';
import FormButton from '../ui/FormButton';
import ErrorMessage from '../ui/ErrorMessage';
import SuccessMessage from '../ui/SuccessMessage';
import FormLink from '../ui/FormLink';

export default function Register() {
    const [fullName, setFullName] = useState('');
    const [username, setUsername] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess('');
        setLoading(true);

        if (password !== confirmPassword) {
            setError('Passwords do not match');
            setLoading(false);
            return;
        }

        // Validate password length
        if (password.length < 6) {
            setError('Password must be at least 6 characters long');
            setLoading(false);
            return;
        }

        // Validate required fields
        if (!fullName.trim()) {
            setError('Full name is required');
            setLoading(false);
            return;
        }

        if (!username.trim()) {
            setError('Username is required');
            setLoading(false);
            return;
        }

        try {
            // First, sign up the user with Supabase Auth
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email: email,
                password: password,
            });

            if (authError) {
                setError(authError.message);
                setLoading(false);
                return;
            }

            // If user is created successfully, update their profile
            if (authData.user) {
                const { error: profileError } = await supabase
                    .from('user_profiles')
                    .update({
                        full_name: fullName,
                        username: username,
                        updated_at: new Date().toISOString()
                    })
                    .eq('id_uuid', authData.user.id);

                if (profileError) {
                    console.error('Error updating profile:', profileError);
                    // Don't show this error to user as the account was created successfully
                }
            }

            setSuccess('Registration successful! Please check your email to confirm your account.');
            // Redirect to login page after a delay
            setTimeout(() => {
                router.push('/profile');
            }, 2000);

        } catch (err) {
            setError('An unexpected error occurred');
        } finally {
            setLoading(false);
        }
    };

    return (
        <FormContainer title="Register">
            <ErrorMessage message={error} />
            <SuccessMessage message={success} />
            
            <form onSubmit={handleSubmit} className="space-y-4">
                <FormInput
                    type="text"
                    placeholder="Full Name"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                />
                
                <FormInput
                    type="text"
                    placeholder="Username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                />
                
                <FormInput
                    type="email"
                    placeholder="Email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                />
                
                <FormInput
                    type="password"
                    placeholder="Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                />
                
                <FormInput
                    type="password"
                    placeholder="Confirm Password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                    minLength={6}
                />
                
                <FormButton 
                    type="submit"
                    disabled={loading}
                    loading={loading}
                    loadingText="Registering..."
                >
                    Register
                </FormButton>
            </form>
            
            <FormLink 
                text="Already have an account?"
                linkText="Login here"
                href="/login"
            />
        </FormContainer>
    );
}