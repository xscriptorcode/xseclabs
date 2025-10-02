import React from 'react';

interface FormLinkProps {
    text: string;
    linkText: string;
    href: string;
}

export default function FormLink({ text, linkText, href }: FormLinkProps) {
    return (
        <p 
            className="text-xs"
            style={{ color: 'var(--color-text-secondary)' }}
        >
            {text} 
            <a 
                className="hover:opacity-80 ml-1"
                href={href}
                style={{ color: 'var(--color-primary)' }}
            >
                <strong><em>{linkText}</em></strong>
            </a>
        </p>
    );
}