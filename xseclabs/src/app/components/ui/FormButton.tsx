import React from 'react';

interface FormButtonProps {
    type: 'submit' | 'button';
    disabled?: boolean;
    loading?: boolean;
    children: React.ReactNode;
    loadingText?: string;
}

export default function FormButton({ 
    type, 
    disabled = false, 
    loading = false, 
    children, 
    loadingText 
}: FormButtonProps) {
    return (
        <button 
            type={type}
            disabled={disabled || loading}
            className="px-2 py-2 rounded hover:opacity-90 disabled:opacity-50 p-4 transition-opacity"
            style={{
                backgroundColor: (disabled || loading) ? 'var(--color-muted)' : 'var(--color-muted)',
                color: 'white',
                border: 'none'
            }}
        >
            {loading && loadingText ? loadingText : children}
        </button>
    );
}