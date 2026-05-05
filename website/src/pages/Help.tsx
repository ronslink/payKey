import { useState } from 'react'
import { Search, Mail, Phone, MessageCircle, ChevronDown, Smartphone, Shield, FileText, CreditCard, Users } from 'lucide-react'

const faqCategories = [
  {
    name: 'Getting Started',
    icon: Smartphone,
    questions: [
      { q: 'How do I download the app?', a: 'Paydome is available on the App Store (iOS) and Google Play Store (Android). Search for "Paydome" and download. Sign up with your phone number and you\'re ready to go.' },
      { q: 'How do I add my house help?', a: 'Open the app, tap "Add Worker," and enter their name, phone number (for M-Pesa), role (e.g., House Help, Gardener), and monthly salary. That\'s it!' },
      { q: 'Does my worker need the app too?', a: 'No. Your worker receives their salary via M-Pesa and their payslip via SMS or WhatsApp. They don\'t need to install anything.' },
    ],
  },
  {
    name: 'M-Pesa Payments',
    icon: CreditCard,
    questions: [
      { q: 'How do M-Pesa payments work?', a: 'Link your M-Pesa account to Paydome. When you process payroll, the salary amount is sent directly from your M-Pesa to your worker\'s M-Pesa. Both of you get an instant confirmation.' },
      { q: 'Are there M-Pesa transaction fees?', a: 'Standard Safaricom M-Pesa send money fees apply. These are shown clearly before you confirm each payment. Paydome itself does not charge extra for M-Pesa transfers.' },
      { q: 'Can I schedule automatic payments?', a: 'Yes! Set a recurring payment date (e.g., every 1st of the month) and Paydome will remind you and process the payment automatically.' },
    ],
  },
  {
    name: 'PAYE, NSSF, SHIF & KRA',
    icon: Shield,
    questions: [
      { q: 'Does Paydome calculate PAYE, NSSF, and SHIF?', a: 'Yes. Automatic tax calculations are included across PayKey subscription tiers. Paid plans add payroll processing, M-Pesa payments, P9 tax cards, and higher-tier reporting tools.' },
      { q: 'How does PAYE tax work?', a: 'Paydome calculates PAYE (Pay As You Earn) tax based on the current KRA tax brackets. The tax amount is shown on the payslip and deducted before the net pay is sent via M-Pesa.' },
      { q: 'Can I export reports for my accountant?', a: 'Absolutely. Go to "Reports" in the app, select the month or year, and export as PDF or Excel. These reports include all payments, deductions, and contributions.' },
    ],
  },
  {
    name: 'Payslips',
    icon: FileText,
    questions: [
      { q: 'How does my worker get their payslip?', a: 'Payslips are sent automatically via SMS or WhatsApp after each payment. They include gross salary, all deductions (PAYE, NSSF, SHIF), and net pay.' },
      { q: 'Are the payslips KRA compliant?', a: 'Yes. Our payslips follow the standard format accepted by KRA and include all required information for tax filing purposes.' },
      { q: 'Can I download payslips for my records?', a: 'Yes. All payslips are stored in your app and can be downloaded as PDF anytime. We recommend keeping them for at least 5 years for tax purposes.' },
    ],
  },
  {
    name: 'Managing Your Staff',
    icon: Users,
    questions: [
      { q: 'How many workers can I add?', a: 'Free supports up to 1 worker, Basic supports up to 5, Gold supports up to 10, and Platinum supports up to 20. You can upgrade anytime as your household grows.' },
      { q: 'What if a worker leaves?', a: 'You can mark a worker as inactive. Their payment history and records are preserved for your records but they won\'t appear in active payroll.' },
      { q: 'Can I edit a worker\'s salary?', a: 'Yes. Tap on the worker\'s profile and update their salary, role, or phone number. Changes take effect from the next pay cycle.' },
    ],
  },
]

export default function Help() {
  const [searchQuery, setSearchQuery] = useState('')
  const [openItems, setOpenItems] = useState<Record<string, boolean>>({})

  const toggleItem = (key: string) => {
    setOpenItems((prev) => ({ ...prev, [key]: !prev[key] }))
  }

  const filteredCategories = faqCategories.map((cat) => ({
    ...cat,
    questions: cat.questions.filter(
      (q) =>
        q.q.toLowerCase().includes(searchQuery.toLowerCase()) ||
        q.a.toLowerCase().includes(searchQuery.toLowerCase())
    ),
  })).filter((cat) => cat.questions.length > 0)

  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Help Center
          </h1>
          <p className="text-lg text-slate-400 mb-8">
            Answers to common questions about using Paydome.
          </p>
          
          <div className="relative max-w-lg mx-auto">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            <input
              type="text"
              placeholder="Search for answers..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 rounded-xl bg-white/5 border border-white/10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
            />
          </div>
        </div>
      </div>

      {/* Contact Cards */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 pb-12">
        <div className="grid sm:grid-cols-3 gap-4">
          <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02] text-center">
            <Mail className="w-6 h-6 text-emerald-400 mx-auto mb-3" />
            <h3 className="text-sm font-semibold text-white mb-1">Email Support</h3>
            <p className="text-sm text-slate-400">support@paydome.co</p>
            <p className="text-xs text-slate-500 mt-1">Response within 2 hours</p>
          </div>
          <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02] text-center">
            <Phone className="w-6 h-6 text-emerald-400 mx-auto mb-3" />
            <h3 className="text-sm font-semibold text-white mb-1">Phone Support</h3>
            <p className="text-sm text-slate-400">+254 700 123 456</p>
            <p className="text-xs text-slate-500 mt-1">Mon-Sat, 8AM-6PM EAT</p>
          </div>
          <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02] text-center">
            <MessageCircle className="w-6 h-6 text-emerald-400 mx-auto mb-3" />
            <h3 className="text-sm font-semibold text-white mb-1">WhatsApp</h3>
            <p className="text-sm text-slate-400">+254 700 123 457</p>
            <p className="text-xs text-slate-500 mt-1">Quick questions & help</p>
          </div>
        </div>
      </div>

      {/* FAQ */}
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 pb-24">
        {filteredCategories.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-slate-400">No results found. Try a different search term.</p>
          </div>
        ) : (
          filteredCategories.map((category) => (
            <div key={category.name} className="mb-8">
              <div className="flex items-center gap-2 mb-4">
                <category.icon className="w-5 h-5 text-emerald-400" />
                <h2 className="text-lg font-semibold text-white">{category.name}</h2>
              </div>
              <div className="space-y-2">
                {category.questions.map((item) => {
                  const key = `${category.name}-${item.q}`
                  const isOpen = openItems[key]
                  return (
                    <div key={key} className="border border-white/5 rounded-lg overflow-hidden">
                      <button
                        className="w-full flex items-center justify-between p-4 text-left hover:bg-white/[0.02] transition-colors"
                        onClick={() => toggleItem(key)}
                      >
                        <span className="text-sm font-medium text-white pr-4">{item.q}</span>
                        <ChevronDown
                          className={`w-4 h-4 text-slate-500 shrink-0 transition-transform ${isOpen ? 'rotate-180' : ''}`}
                        />
                      </button>
                      {isOpen && (
                        <div className="px-4 pb-4 text-sm text-slate-400 leading-relaxed border-t border-white/5 pt-3">
                          {item.a}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
