import React from 'react';

interface FormInputProps {
    type: string;
    placeholder: string;
    value: string;
    onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    required?: boolean;
    minLength?: number;
}

export default function FormInput({ 
    type, 
    placeholder, 
    value, 
    onChange, 
    required = false,
    minLength 
}: FormInputProps) {
    return (
        <input 
            type={type}
            placeholder={placeholder}
            value={value}
            onChange={onChange}
            className="p-2 rounded-xl"
            style={{
                backgroundColor: 'var(--color-background)',
                border: '1px solid var(--color-border)',
                color: 'var(--color-text)'
            }}
            required={required}
            minLength={minLength}
        />
    );
}