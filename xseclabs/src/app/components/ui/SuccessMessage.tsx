import React from 'react';

interface SuccessMessageProps {
    message: string;
}

export default function SuccessMessage({ message }: SuccessMessageProps) {
    if (!message) return null;
    
    return (
        <div 
            className="text-sm mb-2 text-center p-2 rounded"
            style={{
                color: 'var(--color-success)',
                backgroundColor: 'var(--color-priority-low-bg)'
            }}
        >
            {message}
        </div>
    );
}