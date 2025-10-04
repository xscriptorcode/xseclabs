'use client'
import { useAuth } from '../../contexts/AuthContext'
import NavLinks from './navbar'

export default function ConditionalNavbar() {
  const { user, loading } = useAuth()

  // No mostrar nada mientras se carga
  if (loading) {
    return null
  }

  // Solo mostrar la navbar si el usuario está autenticado
  if (!user) {
    return null
  }

  return <NavLinks />
}