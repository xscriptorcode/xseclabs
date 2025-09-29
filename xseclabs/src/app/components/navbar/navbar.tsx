'use client'
import React from "react"

type NavbarProps = {
    links: {label: string; href: string}[];
};


export function Navbar({ links = [] }: NavbarProps) { 
    
    return (
    <nav className="flex items-center justify-between px-4 py-2 bg-gray-800 text-white">  
      <ul className="flex space-x-4">
        {links.map((link) => (
          <li key={link.href}>
            <a href={link.href} className="hover:text-gray-300">
              {link.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
    );
}


export default function NavLinks (){

return (
    <div>
    <Navbar
        links={[
            { label: "Home", href: "/"},
            { label: "News", href: "/news"},
            { label: "Reports", href: "/reports"},
        ]}
    />
</div>
);
}

