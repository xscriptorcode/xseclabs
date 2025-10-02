'use client'
import { useState } from "react"
import { supabase } from "../../../../lib/supabaseClient"
import { useRouter } from "next/navigation"

export default function Register () {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [fullName, setFullName] = useState("");
    const [username, setUsername] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const router = useRouter();

    const handleRegister = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError("");
        setSuccess("");

        // Validate passwords match
        if (password !== confirmPassword) {
            setError("Passwords do not match");
            setLoading(false);
            return;
        }

        // Validate password length
        if (password.length < 6) {
            setError("Password must be at least 6 characters long");
            setLoading(false);
            return;
        }

        // Validate required fields
        if (!fullName.trim()) {
            setError("Full name is required");
            setLoading(false);
            return;
        }

        if (!username.trim()) {
            setError("Username is required");
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

            setSuccess("Registration successful! Please check your email to confirm your account.");
            // Redirect to login page after a delay
            setTimeout(() => {
                router.push('/login');
            }, 3000);

        } catch (err) {
            setError('An unexpected error occurred');
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div className="min-h-screen flex flex-col items-center justify-center p-4">
            <div 
                className="flex flex-col gap-2 justify-center text-center items-center p-8 rounded-xl w-80 max-w-md"
                style={{
                    backgroundColor: 'var(--color-surface)',
                    border: '1px solid var(--color-border)',
                    color: 'var(--color-text)'
                }}
            >    
                <h2 
                    className="text-xl font-bold mb-4"
                    style={{ color: 'var(--color-text)' }}
                >
                    Register
                </h2>
                
                {error && (
                    <div 
                        className="text-sm mb-2 text-center p-2 rounded"
                        style={{
                            color: 'var(--color-error)',
                            backgroundColor: 'var(--color-error-bg)'
                        }}
                    >
                        {error}
                    </div>
                )}

                {success && (
                    <div 
                        className="text-sm mb-2 text-center p-2 rounded"
                        style={{
                            color: 'var(--color-success)',
                            backgroundColor: 'var(--color-priority-low-bg)'
                        }}
                    >
                        {success}
                    </div>
                )}

                <form onSubmit={handleRegister} className="flex flex-col gap-2 w-full">
                    <input 
                        type="text"
                        placeholder="Full name"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        className="p-2 rounded-xl"
                        style={{
                            backgroundColor: 'var(--color-background)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text)'
                        }}
                        required
                    />
                    <input 
                        type="text"
                        placeholder="Username"
                        value={username}
                        onChange={(e) => setUsername(e.target.value)}
                        className="p-2 rounded-xl"
                        style={{
                            backgroundColor: 'var(--color-background)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text)'
                        }}
                        required
                    />
                    <input 
                        type="email"
                        placeholder="Email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="p-2 rounded-xl"
                        style={{
                            backgroundColor: 'var(--color-background)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text)'
                        }}
                        required
                    />
                    <input 
                        type="password"
                        placeholder="Password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="p-2 rounded-xl"
                        style={{
                            backgroundColor: 'var(--color-background)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text)'
                        }}
                        required
                        minLength={6}
                    />
                    <input 
                        type="password"
                        placeholder="Confirm password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="p-2 rounded-xl"
                        style={{
                            backgroundColor: 'var(--color-background)',
                            border: '1px solid var(--color-border)',
                            color: 'var(--color-text)'
                        }}
                        required
                        minLength={6}
                    />
                    <button 
                        type="submit"
                        disabled={loading}
                        className="px-2 py-2 rounded hover:opacity-90 disabled:opacity-50 p-4 transition-opacity"
                        style={{
                            backgroundColor: loading ? 'var(--color-muted)' : 'var(--color-muted)',
                            color: 'white',
                            border: 'none'
                        }}
                    >
                        {loading ? 'Registering...' : 'Register'}
                    </button>
                </form>
                
                <p 
                    className="text-xs"
                    style={{ color: 'var(--color-text-secondary)' }}
                >
                    Already have an account? 
                    <a 
                        className="hover:opacity-80 ml-1"
                        href="/login"
                        style={{ color: 'var(--color-primary)' }}
                    >
                        <strong><em>Sign in</em></strong>
                    </a>
                </p>
                <p 
                    className="text-xs"
                    style={{ color: 'var(--color-text-secondary)' }}
                >
                    Forgot your password? 
                    <a 
                        className="hover:opacity-80 ml-1"
                        href="#"
                        style={{ color: 'var(--color-primary)' }}
                    >
                        <strong><em>Recover</em></strong>
                    </a>
                </p>
            </div>
        </div>
    )
}