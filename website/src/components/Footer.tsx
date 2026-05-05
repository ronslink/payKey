import { Link } from 'react-router-dom'
import { Shield, Globe, Mail, Phone } from 'lucide-react'

const footerLinks = {
  product: [
    { label: 'Features', href: '/features' },
    { label: 'Pricing', href: '/pricing' },
    { label: 'Security', href: '/about' },
    { label: 'M-Pesa Payments', href: '/features' },
  ],
  company: [
    { label: 'About', href: '/about' },
    { label: 'Careers', href: '#' },
    { label: 'Press', href: '#' },
    { label: 'Blog', href: '#' },
  ],
  support: [
    { label: 'Help Center', href: '/help' },
    { label: 'Contact Us', href: '/contact' },
    { label: 'Status', href: '#' },
    { label: 'WhatsApp Support', href: '#' },
  ],
  legal: [
    { label: 'Privacy Policy', href: '#' },
    { label: 'Terms of Service', href: '#' },
    { label: 'Cookie Policy', href: '#' },
    { label: 'GDPR', href: '#' },
  ],
}

export default function Footer() {
  return (
    <footer className="border-t border-white/5 bg-[#050810]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Main Footer */}
        <div className="py-12 grid grid-cols-2 md:grid-cols-6 gap-8">
          {/* Brand Column */}
          <div className="col-span-2">
            <Link to="/" className="flex items-center gap-2.5 mb-4">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-lg shadow-emerald-500/20">
                <Shield className="w-4.5 h-4.5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex flex-col leading-none">
                <span className="text-base font-bold text-white tracking-tight">Paydome</span>
                <span className="text-[10px] text-muted-foreground tracking-wide">by PayGlobus</span>
              </div>
            </Link>
            <p className="text-sm text-slate-400 mb-4 max-w-xs">
              Modern payroll for Kenyan households. Pay your domestic staff via M-Pesa, stay compliant, and keep proper records.
            </p>
            <div className="space-y-2">
              <a href="mailto:support@paydome.co" className="flex items-center gap-2 text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                <Mail className="w-4 h-4" />
                support@paydome.co
              </a>
              <a href="tel:+254700123456" className="flex items-center gap-2 text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                <Phone className="w-4 h-4" />
                +254 700 123 456
              </a>
            </div>
          </div>

          {/* Links */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Product</h4>
            <ul className="space-y-2">
              {footerLinks.product.map((link) => (
                <li key={link.label}>
                  <Link to={link.href} className="text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Company</h4>
            <ul className="space-y-2">
              {footerLinks.company.map((link) => (
                <li key={link.label}>
                  <Link to={link.href} className="text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Support</h4>
            <ul className="space-y-2">
              {footerLinks.support.map((link) => (
                <li key={link.label}>
                  <Link to={link.href} className="text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Legal</h4>
            <ul className="space-y-2">
              {footerLinks.legal.map((link) => (
                <li key={link.label}>
                  <Link to={link.href} className="text-sm text-slate-400 hover:text-emerald-400 transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="py-6 border-t border-white/5 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-1.5 text-xs text-slate-500">
              <Globe className="w-3.5 h-3.5" />
              PayGlobus Group
            </span>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-slate-600">SOC 2 Certified</span>
            <span className="text-xs text-slate-600">GDPR Ready</span>
            <span className="text-xs text-slate-600">M-Pesa Authorized</span>
          </div>
          <p className="text-xs text-slate-600">
            © {new Date().getFullYear()} Paydome / PayGlobus GmbH. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  )
}
