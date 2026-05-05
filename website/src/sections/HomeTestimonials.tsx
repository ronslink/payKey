import { Star } from 'lucide-react'

const testimonials = [
  {
    name: 'Wanjiku M.',
    role: 'Homeowner',
    location: 'Lavington, Nairobi',
    content: 'I used to struggle with remembering to pay my house help on time. With Paydome, her salary goes straight to her M-Pesa every month, automatically. The payslips give her peace of mind too.',
    rating: 5,
  },
  {
    name: 'James Ochieng',
    role: 'Business Owner',
    location: 'Westlands, Nairobi',
    content: 'I have a driver, a gardener, and a house help. Paydome handles all three salaries, calculates NHIF and NSSF, and keeps everything organized for my accountant. Game changer.',
    rating: 5,
  },
  {
    name: 'Amina H.',
    role: 'Working Professional',
    location: 'Kilimani, Nairobi',
    content: 'As a busy mom, I don\'t have time to queue at the bank or remember cash for salaries. Paydome does it all from my phone. My nanny gets her pay on time, every single month.',
    rating: 5,
  },
]

export default function HomeTestimonials() {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/5 rounded-full blur-[100px] pointer-events-none" />
      
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Loved by Kenyan{' '}
            <span className="text-gradient">households</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            See why thousands of Kenyan employers trust Paydome to pay their staff.
          </p>
        </div>

        {/* Testimonials */}
        <div className="grid md:grid-cols-3 gap-6">
          {testimonials.map((t) => (
            <div
              key={t.name}
              className="relative p-6 rounded-xl border border-white/5 bg-white/[0.02] backdrop-blur-sm"
            >
              <div className="flex gap-1 mb-4">
                {Array.from({ length: t.rating }).map((_, i) => (
                  <Star key={i} className="w-4 h-4 text-amber-400 fill-amber-400" />
                ))}
              </div>
              
              <p className="text-sm text-slate-300 leading-relaxed mb-6">
                "{t.content}"
              </p>

              <div className="flex items-center gap-3 pt-4 border-t border-white/5">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-emerald-500 to-green-500 flex items-center justify-center text-white font-semibold text-sm">
                  {t.name.split(' ').map(n => n[0]).join('')}
                </div>
                <div>
                  <div className="text-sm font-semibold text-white">{t.name}</div>
                  <div className="text-xs text-slate-400">{t.role} · {t.location}</div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Trust strip */}
        <div className="mt-16 text-center">
          <p className="text-sm text-slate-500 mb-6">Trusted across Nairobi and beyond</p>
          <div className="flex flex-wrap justify-center items-center gap-8 sm:gap-12 opacity-50">
            {['Lavington', 'Kilimani', 'Westlands', 'Karen', 'Runda', 'Muthaiga'].map((name) => (
              <span key={name} className="text-lg font-bold text-slate-600 tracking-tight">{name}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
