'use client'
import React from "react"

type NavbarProps = {
    links: {label: string; href: string}[];
};


export function Navbar({ links = [] }: NavbarProps) { 
    
    return (
    <div className="flex justify-center p-8">
    <nav className="flex items-center justify-between text-center px-4 py-2 bg-(--color-primary) text-(--color-text-secondary) rounded-xl">  
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
    </div>
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

