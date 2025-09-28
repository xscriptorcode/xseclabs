'use client'
import { useState } from "react"

export default function Login () {
    const [user, setUser] = useState<string>("");
    const [pass, setPass] = useState<string>("");
    
    return (
        <div className="flex flex-col gap-2 justify-center text-center items-center">
            
            <input 
            type="text"
            placeholder="Username"
            value={user}
            onChange={(e) => setUser(e.target.value)}
            className="border p-2 rounded"
            />
            <input 
            type="password"
            placeholder="Password"
            value={pass}
            onChange={(e) => setPass(e.target.value)}
            className="border p-2 rounded"
            />
            <button className="text-white px-2 py-2 rounded hover:bg-red-500 border p-4 rounded">
                Login
            </button>     
        </div>

    )
}