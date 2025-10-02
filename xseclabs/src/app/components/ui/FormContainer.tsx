import React from 'react';

interface FormContainerProps {
    children: React.ReactNode;
    title: string;
}

export default function FormContainer({ children, title }: FormContainerProps) {
    return (
        <div className="min-h-screen flex flex-col items-center justify-center p-4">
            <div 
                className="flex flex-col gap-2 justify-center text-center items-center p-8 rounded-xl w-80 max-w-md"
                style={{
                    backgroundColor: 'var(--color-surface)',
                    border: '1px solid var(--color-border)',
                    color: 'var(--color-text)'
                }}
            >    
                <h2 
                    className="text-xl font-bold mb-4"
                    style={{ color: 'var(--color-text)' }}
                >
                    {title}
                </h2>
                {children}
            </div>
        </div>
    );
}