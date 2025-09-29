'use client'
import { useState } from "react"

export default function Login () {
    const [user, setUser] = useState("");
    const [pass, setPass] = useState("");
    
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
                <button className="text-white px-2 py-2 rounded hover:bg-red-500 border p-4 rounded">
                    Login
                </button>
                <p className="text-xs"><a className="hover:text-yellow-500" href="#"><strong><em>Join Us</em></strong></a></p>
                <p className="text-xs">Forgot the password?, try <a className="hover:text-yellow-500" href="#"><strong><em>recovery</em></strong></a></p>
            </div>
        </div>
    )
}