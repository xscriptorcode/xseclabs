import React from 'react';

interface ErrorMessageProps {
    message: string;
}

export default function ErrorMessage({ message }: ErrorMessageProps) {
    if (!message) return null;
    
    return (
        <div 
            className="text-sm mb-2 text-center p-2 rounded"
            style={{
                color: 'var(--color-error)',
                backgroundColor: 'var(--color-error-bg)'
            }}
        >
            {message}
        </div>
    );
}