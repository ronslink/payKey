import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Shield, Lock, FileCheck, Server } from 'lucide-react'

export default function HomeSecurity() {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-emerald-500/3 to-transparent" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - Content */}
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium mb-6">
              <Lock className="w-3 h-3" />
              Trusted & Secure
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
              Your money and data,{' '}
              <span className="text-gradient">fully protected</span>
            </h2>
            <p className="text-lg text-slate-400 mb-8 leading-relaxed">
              Paydome uses bank-level encryption and is backed by PayGlobus GmbH, 
              a regulated German fintech. Your transactions and staff records are always secure.
            </p>

            <div className="space-y-4 mb-8">
              {[
                { icon: Lock, label: 'Bank-Level Encryption', desc: 'All data protected with AES-256 encryption — the same standard used by banks worldwide' },
                { icon: FileCheck, label: 'KRA & Statutory Compliant', desc: 'Automatic NHIF, NSSF, and PAYE calculations. Reports ready for iTax filing.' },
                { icon: Shield, label: 'M-Pesa Secure Integration', desc: 'Direct, authorized M-Pesa API connection. Your money moves safely, every time.' },
                { icon: Server, label: 'Data Privacy Guaranteed', desc: 'GDPR compliant. Your staff\'s personal data is never shared or sold.' },
              ].map((item) => (
                <div key={item.label} className="flex items-start gap-4 p-4 rounded-xl bg-white/[0.02] border border-white/5">
                  <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center shrink-0">
                    <item.icon className="w-5 h-5 text-emerald-400" />
                  </div>
                  <div>
                    <h4 className="text-sm font-semibold text-white mb-1">{item.label}</h4>
                    <p className="text-sm text-slate-400">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>

            <Link to="/about">
              <Button
                variant="outline"
                className="border-white/10 bg-white/5 hover:bg-white/10 text-white"
              >
                Learn More About Security
              </Button>
            </Link>
          </div>

          {/* Right - Visual */}
          <div className="relative">
            <div className="absolute -inset-4 bg-gradient-to-r from-emerald-500/10 to-green-500/10 rounded-2xl blur-2xl" />
            <div className="relative rounded-xl overflow-hidden border border-white/10 shadow-2xl">
              <img
                src="/employer-worker.jpg"
                alt="Employer and domestic worker connected through Paydome"
                className="w-full h-auto"
              />
            </div>
            {/* Trust badges */}
            <div className="absolute bottom-4 left-4 right-4 flex justify-center gap-3">
              <div className="bg-[#0D1525]/90 backdrop-blur-xl border border-white/10 rounded-lg px-3 py-2 text-center">
                <div className="text-sm font-bold text-white">SOC 2</div>
                <div className="text-[10px] text-slate-400">Certified</div>
              </div>
              <div className="bg-[#0D1525]/90 backdrop-blur-xl border border-white/10 rounded-lg px-3 py-2 text-center">
                <div className="text-sm font-bold text-white">GDPR</div>
                <div className="text-[10px] text-slate-400">Compliant</div>
              </div>
              <div className="bg-[#0D1525]/90 backdrop-blur-xl border border-white/10 rounded-lg px-3 py-2 text-center">
                <div className="text-sm font-bold text-white">M-Pesa</div>
                <div className="text-[10px] text-slate-400">Authorized</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
