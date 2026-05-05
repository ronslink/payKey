import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { Menu, X } from 'lucide-react'
import { Button } from '@/components/ui/button'

const navLinks = [
  { href: '/', label: 'Home' },
  { href: '/features', label: 'Features' },
  { href: '/pricing', label: 'Pricing' },
  { href: '/about', label: 'About' },
  { href: '/help', label: 'Help' },
]

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 border-b border-white/5 bg-[#070B14]/80 backdrop-blur-xl">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2.5 shrink-0">
            <img src="/app-icon.jpg" alt="Paydome" className="w-8 h-8 rounded-lg shadow-lg" />
            <div className="flex flex-col leading-none">
              <span className="text-base font-bold text-white tracking-tight">Paydome</span>
              <span className="text-[10px] text-muted-foreground tracking-wide">by PayGlobus</span>
            </div>
          </Link>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center gap-1">
            {navLinks.map((link) => {
              const isActive = location.pathname === link.href
              return (
                <Link
                  key={link.href}
                  to={link.href}
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    isActive
                      ? 'text-emerald-400 bg-emerald-500/10'
                      : 'text-slate-300 hover:text-white hover:bg-white/5'
                  }`}
                >
                  {link.label}
                </Link>
              )
            })}
          </div>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-3">
            <Link
              to="/contact"
              className="text-sm text-slate-300 hover:text-white transition-colors"
            >
              Contact
            </Link>
            <Button
              size="sm"
              className="bg-emerald-500 hover:bg-emerald-600 text-white font-medium shadow-lg shadow-emerald-500/20 transition-all"
            >
              Start Free Trial
            </Button>
          </div>

          {/* Mobile Toggle */}
          <button
            className="md:hidden p-2 rounded-md text-slate-300 hover:text-white hover:bg-white/5"
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileOpen && (
        <div className="md:hidden border-t border-white/5 bg-[#070B14]/95 backdrop-blur-xl">
          <div className="px-4 py-3 space-y-1">
            {navLinks.map((link) => {
              const isActive = location.pathname === link.href
              return (
                <Link
                  key={link.href}
                  to={link.href}
                  className={`block px-3 py-2.5 rounded-md text-sm font-medium transition-colors ${
                    isActive
                      ? 'text-emerald-400 bg-emerald-500/10'
                      : 'text-slate-300 hover:text-white hover:bg-white/5'
                  }`}
                  onClick={() => setMobileOpen(false)}
                >
                  {link.label}
                </Link>
              )
            })}
            <div className="pt-3 border-t border-white/5 flex flex-col gap-2">
              <Link
                to="/contact"
                className="px-3 py-2 text-sm text-slate-300 hover:text-white"
                onClick={() => setMobileOpen(false)}
              >
                Contact
              </Link>
              <Button className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-medium">
                Start Free Trial
              </Button>
            </div>
          </div>
        </div>
      )}
    </nav>
  )
}
