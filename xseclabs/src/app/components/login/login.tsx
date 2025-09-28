'use client'
import { useState } from "react"

export default function Login () {
    const [user, setUser] = useState<string>("");
    const [pass, serPass] = useState<string>("");
    
    return (
        <div>
            <input 
            type="text"
            placeholder="Username"
            value={user}
            onChange={(e) => setUser(e.target.value)}
            className="border p-2 rounded"
            />        
        </div>
    )
}