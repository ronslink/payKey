import { Smartphone, Shield, FileText, Clock, Bell, BarChart3 } from 'lucide-react'

const features = [
  {
    icon: Smartphone,
    title: 'M-Pesa Payments',
    description: 'Send salaries directly to your worker\'s M-Pesa in seconds. No bank queues, no cash handling — just instant, secure mobile money transfers.',
    color: 'from-emerald-500/20 to-emerald-600/10',
    iconColor: 'text-emerald-400',
    borderColor: 'border-emerald-500/20',
  },
  {
    icon: Shield,
    title: 'KRA Compliant',
    description: 'Automatic PAYE tax calculations, NHIF and NSSF deductions. Generate compliant payslips and reports ready for KRA filing.',
    color: 'from-blue-500/20 to-blue-600/10',
    iconColor: 'text-blue-400',
    borderColor: 'border-blue-500/20',
  },
  {
    icon: FileText,
    title: 'Auto Payslips',
    description: 'Beautiful, KRA-compliant payslips generated automatically every pay period. Sent via SMS, WhatsApp, or email to your staff.',
    color: 'from-violet-500/20 to-violet-600/10',
    iconColor: 'text-violet-400',
    borderColor: 'border-violet-500/20',
  },
  {
    icon: Clock,
    title: 'Scheduled Payments',
    description: 'Set up recurring salary payments — weekly, bi-weekly, or monthly. Paydome sends reminders and processes payments automatically.',
    color: 'from-amber-500/20 to-amber-600/10',
    iconColor: 'text-amber-400',
    borderColor: 'border-amber-500/20',
  },
  {
    icon: Bell,
    title: 'Payment Reminders',
    description: 'Never forget payday again. Get smart reminders before salary is due, and instant confirmation when payment is sent.',
    color: 'from-rose-500/20 to-rose-600/10',
    iconColor: 'text-rose-400',
    borderColor: 'border-rose-500/20',
  },
  {
    icon: BarChart3,
    title: 'Payment History',
    description: 'Complete records of every payment made. Export reports for your accountant, track spending, and stay organized at tax time.',
    color: 'from-cyan-500/20 to-cyan-600/10',
    iconColor: 'text-cyan-400',
    borderColor: 'border-cyan-500/20',
  },
]

export default function HomeFeatures() {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-emerald-500/5 rounded-full blur-[100px] pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Everything you need to{' '}
            <span className="text-gradient">pay your staff right</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            From M-Pesa salary payments to KRA-compliant records, Paydome handles it all from your phone.
          </p>
        </div>

        {/* Feature Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => (
            <div
              key={feature.title}
              className={`group relative p-6 rounded-xl border ${feature.borderColor} bg-gradient-to-br ${feature.color} backdrop-blur-sm transition-all duration-300 hover:scale-[1.02] hover:shadow-xl hover:shadow-emerald-500/5`}
            >
              <div className={`w-11 h-11 rounded-lg bg-white/5 flex items-center justify-center mb-4 ${feature.iconColor}`}>
                <feature.icon className="w-5 h-5" strokeWidth={2} />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">{feature.title}</h3>
              <p className="text-sm text-slate-400 leading-relaxed">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
