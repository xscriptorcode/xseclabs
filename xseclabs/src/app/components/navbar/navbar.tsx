'use client'
import React, { useState } from "react"
import { useAuth } from "../../contexts/AuthContext"
import ThemeToggle from './ThemeToggle'
import { 
  HomeIcon, 
  ProjectsIcon, 
  ReportsIcon, 
  ProfileIcon, 
  LogoutIcon,
  MenuIcon,
  CloseIcon
} from "./NavbarIcons"

const NavLinks: React.FC = () => {
  const { signOut } = useAuth()
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  const handleLogout = async () => {
    try {
      await signOut()
      window.location.href = '/login'
    } catch (error) {
      console.error('Error al cerrar sesión:', error)
    }
  }

  const navItems = [
    { label: "Dashboard", href: "/dashboard", icon: HomeIcon },
    { label: "Projects", href: "/projects", icon: ProjectsIcon },
    { label: "Reports", href: "/reports", icon: ReportsIcon },
    { label: "Profile", href: "/profile", icon: ProfileIcon },
  ]

  return (
    <>
      {/* Desktop Sidebar */}
      <div 
        className="hidden lg:flex lg:flex-col lg:fixed lg:inset-y-0 lg:left-0 lg:w-16 lg:z-50"
        style={{ 
          backgroundColor: 'var(--color-surface)',
          borderRight: '1px solid var(--color-border)'
        }}
      >
        <div className="flex flex-col items-center py-4 space-y-4">
          {navItems.map((item, index) => (
            <div key={index} className="relative group">
              <a
                href={item.href}
                className="flex items-center justify-center w-12 h-12 rounded-lg transition-all duration-200"
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
              >
                <item.icon size={24} />
              </a>
              {/* Tooltip */}
              <div 
                className="absolute left-16 top-1/2 transform -translate-y-1/2 px-3 py-2 rounded-lg text-sm opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-10 card"
                style={{ 
                  backgroundColor: 'var(--color-surface)',
                  color: 'var(--color-text)',
                  border: '1px solid var(--color-border)',
                  fontFamily: 'Eb-Garamond, serif'
                }}
              >
                {item.label}
              </div>
            </div>
          ))}
          
          {/* Theme Toggle Button */}
          <div className="relative group">
            <ThemeToggle size={24} />
            {/* Tooltip */}
            <div 
              className="absolute left-16 top-1/2 transform -translate-y-1/2 px-3 py-2 rounded-lg text-sm opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-10 card"
              style={{ 
                backgroundColor: 'var(--color-surface)',
                color: 'var(--color-text)',
                border: '1px solid var(--color-border)',
                fontFamily: 'Eb-Garamond, serif'
              }}
            >
                Change Theme
              </div>
          </div>
          
          {/* Logout Button */}
          <div className="relative group mt-auto">
            <button
              onClick={handleLogout}
              className="flex items-center justify-center w-12 h-12 rounded-lg transition-all duration-200"
              style={{ 
                color: 'var(--color-muted)',
                backgroundColor: 'transparent'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.color = 'var(--color-accent)'
                e.currentTarget.style.backgroundColor = 'rgba(249, 115, 22, 0.1)'
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = 'var(--color-muted)'
                e.currentTarget.style.backgroundColor = 'transparent'
              }}
            >
              <LogoutIcon size={24} />
            </button>
            {/* Tooltip */}
            <div 
              className="absolute left-16 top-1/2 transform -translate-y-1/2 px-3 py-2 rounded-lg text-sm opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-10 card"
              style={{ 
                backgroundColor: 'var(--color-surface)',
                color: 'var(--color-text)',
                border: '1px solid var(--color-border)',
                fontFamily: 'Eb-Garamond, serif'
              }}
            >
                Sign Out
              </div>
          </div>
        </div>
      </div>

      {/* Mobile Bottom Navigation - Dock Style */}
      <div className="lg:hidden fixed bottom-4 left-1/2 transform -translate-x-1/2 z-50">
        <div 
          className="card flex items-center px-4 py-3 space-x-3"
          style={{ 
            backgroundColor: 'var(--color-surface)',
            border: '1px solid var(--color-border)',
            borderRadius: '2rem',
            backdropFilter: 'blur(12px)',
            WebkitBackdropFilter: 'blur(12px)',
            boxShadow: '0 10px 25px rgba(0, 0, 0, 0.15)'
          }}
        >
          {navItems.map((item, index) => (
            <a
              key={index}
              href={item.href}
              className="flex items-center justify-center w-12 h-12 rounded-full transition-all duration-200"
              style={{ 
                color: 'var(--color-muted)',
                backgroundColor: 'transparent'
              }}
              onTouchStart={(e) => {
                e.currentTarget.style.color = 'var(--color-primary)'
                e.currentTarget.style.backgroundColor = 'var(--color-bg)'
                e.currentTarget.style.transform = 'scale(0.95)'
              }}
              onTouchEnd={(e) => {
                e.currentTarget.style.color = 'var(--color-muted)'
                e.currentTarget.style.backgroundColor = 'transparent'
                e.currentTarget.style.transform = 'scale(1)'
              }}
            >
              <item.icon size={20} />
            </a>
          ))}
          
          {/* Theme Toggle Button */}
          <div className="flex items-center justify-center w-12 h-12 rounded-full transition-all duration-200">
            <ThemeToggle size={20} />
          </div>
          
          {/* Logout Button - Larger and Direct */}
          <button
            onClick={handleLogout}
            className="flex items-center justify-center w-14 h-14 rounded-full transition-all duration-200"
            style={{ 
              color: 'var(--color-muted)',
              backgroundColor: 'transparent'
            }}
            onTouchStart={(e) => {
              e.currentTarget.style.color = 'var(--color-accent)'
              e.currentTarget.style.backgroundColor = 'rgba(249, 115, 22, 0.1)'
              e.currentTarget.style.transform = 'scale(0.95)'
            }}
            onTouchEnd={(e) => {
              e.currentTarget.style.color = 'var(--color-muted)'
              e.currentTarget.style.backgroundColor = 'transparent'
              e.currentTarget.style.transform = 'scale(1)'
            }}
          >
            <LogoutIcon size={26} />
          </button>
        </div>
      </div>
    </>
  )
}

export default NavLinks

