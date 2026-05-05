import {
  Smartphone, Shield, FileText, Clock, Bell, BarChart3,
  Users, Receipt, Calculator, Download, MessageSquare, Headphones
} from 'lucide-react'

const featureGroups = [
  {
    title: 'M-Pesa Payments',
    description: 'Send salaries instantly, anywhere',
    icon: Smartphone,
    color: 'from-emerald-500/20 to-emerald-600/10',
    borderColor: 'border-emerald-500/20',
    iconColor: 'text-emerald-400',
    features: [
      { icon: Smartphone, title: 'Direct M-Pesa Transfer', desc: 'Send salary straight to your worker\'s M-Pesa. They receive it in seconds with an SMS confirmation.' },
      { icon: Clock, title: 'Instant or Scheduled', desc: 'Pay immediately or set up automatic monthly/weekly salary payments. Never miss payday again.' },
      { icon: Receipt, title: 'Transaction Receipts', desc: 'Both you and your worker get a detailed receipt for every payment. No more disputes.' },
      { icon: Bell, title: 'Payment Reminders', desc: 'Get notified before payday. Your worker also gets an alert when salary is on its way.' },
    ],
  },
  {
    title: 'Compliance & Deductions',
    description: 'Stay on the right side of the law',
    icon: Shield,
    color: 'from-blue-500/20 to-blue-600/10',
    borderColor: 'border-blue-500/20',
    iconColor: 'text-blue-400',
    features: [
      { icon: Calculator, title: 'Auto NHIF Deductions', desc: 'National Hospital Insurance Fund contributions calculated and recorded automatically per KRA guidelines.' },
      { icon: Calculator, title: 'Auto NSSF Deductions', desc: 'National Social Security Fund contributions computed and tracked for every pay period.' },
      { icon: Calculator, title: 'PAYE Tax Calculation', desc: 'Pay As You Earn tax computed based on current KRA tax brackets. No more guesswork.' },
      { icon: FileText, title: 'KRA-Ready Reports', desc: 'Generate monthly and annual reports ready for iTax filing. Export in PDF or Excel format.' },
    ],
  },
  {
    title: 'Payslips & Records',
    description: 'Professional documentation for your staff',
    icon: FileText,
    color: 'from-violet-500/20 to-violet-600/10',
    borderColor: 'border-violet-500/20',
    iconColor: 'text-violet-400',
    features: [
      { icon: FileText, title: 'Auto-Generated Payslips', desc: 'Beautiful, professional payslips created automatically every pay period. KRA-compliant format.' },
      { icon: MessageSquare, title: 'Send via SMS/WhatsApp', desc: 'Deliver payslips directly to your worker\'s phone. No printing, no paper, no hassle.' },
      { icon: Download, title: 'Export Anytime', desc: 'Download payslips as PDF for your records or to share with your accountant.' },
      { icon: BarChart3, title: 'Yearly Summary', desc: 'View total annual pay, deductions, and contributions for each worker at a glance.' },
    ],
  },
  {
    title: 'Support',
    description: 'Help when you need it',
    icon: Headphones,
    color: 'from-amber-500/20 to-amber-600/10',
    borderColor: 'border-amber-500/20',
    iconColor: 'text-amber-400',
    features: [
      { icon: Users, title: 'Add Multiple Workers', desc: 'Manage your house help, gardener, driver, and security — all from one account.' },
      { icon: Headphones, title: 'Local Support Team', desc: 'Our Nairobi-based support team understands the Kenyan payroll landscape.' },
      { icon: MessageSquare, title: 'In-App Chat Support', desc: 'Get help directly within the app. Business plans include priority response.' },
      { icon: Shield, title: 'Secure & Private', desc: 'Your data and your worker\'s data are encrypted and never shared with third parties.' },
    ],
  },
]

export default function Features() {
  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Built for{' '}
            <span className="text-gradient">Kenyan households</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Every feature is designed around how Kenyan employers actually pay their domestic staff.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-24 space-y-24">
        {featureGroups.map((group) => (
          <div key={group.title}>
            <div className="flex items-center gap-3 mb-8">
              <div className={`w-11 h-11 rounded-lg bg-gradient-to-br ${group.color} border ${group.borderColor} flex items-center justify-center`}>
                <group.icon className={`w-5 h-5 ${group.iconColor}`} />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white">{group.title}</h2>
                <p className="text-sm text-slate-400">{group.description}</p>
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4">
              {group.features.map((feature) => (
                <div
                  key={feature.title}
                  className="p-5 rounded-xl border border-white/5 bg-white/[0.02] hover:border-white/10 transition-colors"
                >
                  <div className="flex items-start gap-4">
                    <div className="w-9 h-9 rounded-lg bg-emerald-500/10 flex items-center justify-center shrink-0">
                      <feature.icon className="w-4.5 h-4.5 text-emerald-400" />
                    </div>
                    <div>
                      <h3 className="text-base font-semibold text-white mb-1">{feature.title}</h3>
                      <p className="text-sm text-slate-400 leading-relaxed">{feature.desc}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
