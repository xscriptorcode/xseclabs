'use client'
import { useState } from "react"

export default function Register () {
    const [user, setUser] = useState("");
    const [pass, setPass] = useState("");
    const [num, setNum] = useState("");
    
    return (
        <div className="flex flex-col items-center m-4">
            <div className="flex flex-col gap-2 justify-center text-center items-center border p-8 rounded-xl w-64">    
                <input 
                type="text"
                placeholder="Username"
                value={user}
                onChange={(e) => setUser(e.target.value)}
                className="border p-2 rounded-xl"
                />
                <input 
                type="password"
                placeholder="Password"
                value={pass}
                onChange={(e) => setPass(e.target.value)}
                className="border p-2 rounded-xl"
                />
                <input 
                type="phone"
                placeholder="phone"
                value={num}
                onChange={(e) => setNum(e.target.value)}
                className="border p-2 rounded-xl"
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