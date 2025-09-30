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
                })

            }
        }
    }

    return (
        <div className="flex flex-col items-center m-4">
            <div className="flex flex-col gap-2 justify-center text-center items-center border border-(--color-primary) p-8 rounded-xl w-64">    
                <input 
                type="text"
                placeholder="Username"
                value={user}
                onChange={(e) => setUser(e.target.value)}
                className="border border border-(--color-primary) p-2 rounded-xl"
                />
                <input 
                type="password"
                placeholder="Password"
                value={pass}
                onChange={(e) => setPass(e.target.value)}
                className="border border border-(--color-primary) p-2 rounded-xl"
                />
                <button className="text-(--color-primary) px-2 py-2 rounded hover:bg-(--color-primary) hover:text-(--color-text-secondary) border border-(--color-primary) p-4 rounded">
                    Login
                </button>
                <p className="text-xs"><a className="hover:text-yellow-500" href="/register"><strong><em>Join Us</em></strong></a></p>
                <p className="text-xs">Forgot the password?, try <a className="hover:text-yellow-500" href="#"><strong><em>recovery</em></strong></a></p>
            </div>
        </div>
    )
}