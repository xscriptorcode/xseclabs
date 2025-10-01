'use client'
import React, { useState } from "react"
import { supabase } from "../../../../lib/supabaseClient";
import { useRouter } from "next/router";


export default function Register () {

    const [user, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [fullName, setFullName] = useState("");
    const [username, setUsername] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [success, setSuccess] = useState("");
    const router = useRouter();

    const handleRegister = async (e: React.FormEvent)=>{
        e.preventDefault()
            setLoading(true);
            setError("");
            setSuccess("");
        
        if (password !== confirmPassword){
            setError("Use the same passord");
            setLoading(false);
            return;
        }

        if (password.length<6){
            setError("Use at least 6 characters for your password.");
            setLoading(false);
            return;
        }

        if (!fullName.trim()){
            setError("Full name is required");
            setLoading(false);
            return;
        }

        if(!username.trim()) {
            setError("UserName is required");
            setLoading(false);
            return;
        }

        try {

            // first, sign up the user with supabase auth
            const { data: authData, error: authError} = await supabase.auth.signUp({
                email: setEmail,
                password: password,
            });

            if (authError){
                setError(authError.message);
                setLoading(false);
                return;
            }

            if (authData.user){
                const {error: profileError} = await supabase
                .form('user_profiles')
                .update({
                    full_name: fullName,
                    username: username,
                    updated_at: new Date().toISOString()
                })
                .eq('id_uuid', authData.user.id);

                if (profileError){
                    console.error('Errror updating profile: ', profileError);
                }

            }
        }
    }
    return (
        <div className="flex flex-col items-center m-4">
            <div className="flex flex-col gap-2 justify-center text-center items-center border border border-(--color-primary) p-8 rounded-xl w-64">    
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
                <input 
                type="phone"
                placeholder="phone"
                value={num}
                onChange={(e) => setNum(e.target.value)}
                className="border border border-(--color-primary) p-2 rounded-xl"
                />
                <button className="text-white px-2 py-2 rounded hover:bg-red-500 border p-4 rounded">
                    Register
                </button>
                <p className="text-xs">Already registered?<a className="hover:text-yellow-500" href="#"><strong><em>Login</em></strong></a></p>
                <p className="text-xs">Forgot the password?, try <a className="hover:text-yellow-500" href="#"><strong><em>recovery</em></strong></a></p>
            </div>
        </div>
    )
}