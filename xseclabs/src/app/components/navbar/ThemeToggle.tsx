'use client';

import React from 'react';
import { useTheme } from '../../contexts/ThemeContext';

const SunIcon: React.FC<{ size?: number }> = ({ size = 24 }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <circle cx="12" cy="12" r="5"/>
    <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/>
  </svg>
);

const MoonIcon: React.FC<{ size?: number }> = ({ size = 24 }) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  >
    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
  </svg>
);

interface ThemeToggleProps {
  size?: number;
  className?: string;
}

const ThemeToggle: React.FC<ThemeToggleProps> = ({ size = 24, className = "" }) => {
  const { theme, toggleTheme } = useTheme();

  const handleClick = () => {
    console.log('Theme toggle clicked, current theme:', theme);
    toggleTheme();
  };

  return (
    <button
      onClick={handleClick}
      className={`flex items-center justify-center w-12 h-12 rounded-lg transition-all duration-200 ${className}`}
      style={{ 
        color: 'var(--color-muted)',
        backgroundColor: 'transparent'
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.color = 'var(--color-primary)'
        e.currentTarget.style.backgroundColor = 'var(--color-bg)'
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.color = 'var(--color-muted)'
        e.currentTarget.style.backgroundColor = 'transparent'
      }}
      title={theme === 'light' ? 'Switch to dark theme' : 'Switch to light theme'}
    >
      {theme === 'light' ? <MoonIcon size={size} /> : <SunIcon size={size} />}
    </button>
  );
};

export default ThemeToggle;