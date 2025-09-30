'use client'
import { useState } from "react"
import { supabase } from "../../../../lib/supabaseClient";
import { useRouter } from "next/router";

export default function Login () {
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

            //check if input is email or username

            const isEmail = emailOrUsername.includes ('@');
            if (isEmail){
                loginData = await supabase.auth.signInWithPassword({
                    email: emailOrUsername,
                    password: password,
                });
            } else{
                // login with username
                const { data: profileData, error: profileError} = await supabase
                .from('user_profiles')
                .select('id_uuid, full_name')
                .eq ('username', emailOrUsername)
                .single();

                if (profileError || !profileData){
                    setError('User not found, please verify or register...');
                    setLoading(false);
                    return;
                }

                const { data: userData, error: userError} = await supabase
                .from('users')
                .select('email')
                .eq('id_uuid', profileData.id_uuid)
                .single();

                if (userError || !userData) {
                    setError('Error finding data');
                    setLoading(false);
                    return;
                }

                //try to login with the found email
                loginData = await supabase.auth.signInWithPassword({
                    email: userData.email,
                    password: password,
                });

            }

            const {data, error} = loginData;

            if (error) {
                if (error.message.includes('Invalid login credentials')){
                    setError('Invalid credentials. Please verify your email/user and password.')
                } else {
                    setError('Error logging: ' + error.message);
                }
            } else {
                // update last_login in user_profiles
                if(data.user){
                    await supabase
                    .from('user_profiles')
                    .update({
                        last_login: new Date().toISOString(),
                        updated_at: new Date().toISOString()
                    })
                    .eq('id_uiid', data.user.id);
                }

                router.push('/dashboard');
            }
        } catch (err) {
            setError('Unexpected error')
        } finally {
            setLoading(false);
        }
    };

    const handleLogin = async () =>{
        try {
            await supabase.auth.signOut();
            router.push('/login');
        }catch (error){
            console.error('Error Logging out: ', error);
        }
    }

    if (loading) {
        return (
            <div className="justify-center">
                <div>loading...</div>
            </div>
        )
    }

    return (
        <div className="flex flex-col items-center m-4">
            <div className="flex flex-col gap-2 justify-center text-center items-center border border-(--color-primary) p-8 rounded-xl w-64">    
                <h2> Sign in</h2>
                    <input 
                    type="text"
                    placeholder="Email/User"
                    value={emailOrUsername}
                    onChange={(e) => setEmailOrUsername(e.target.value)}
                    className="border border border-(--color-primary) p-2 rounded-xl"
                    required
                    />
                    <input 
                    type="password"
                    placeholder="Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="border border border-(--color-primary) p-2 rounded-xl"
                    required
                    />
                    <button
                        type="submit"
                        disabled={loading}
                        className="text-(--color-primary) px-2 py-2 rounded hover:bg-(--color-primary) hover:text-(--color-text-secondary) border border-(--color-primary) p-4 rounded">
                        {loading ? 'Logging in...' : 'Login'}
                    </button>
                    <p className="text-xs"><a className="hover:text-yellow-500" href="/register"><strong><em>Join Us</em></strong></a></p>
                    <p className="text-xs">Forgot the password?, try <a className="hover:text-yellow-500" href="#"><strong><em>recovery</em></strong></a></p>
            </div>
        </div>
    )
}