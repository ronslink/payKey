import { Calculator, FileText, Smartphone } from "lucide-react";

const principles = [
  {
    icon: Calculator,
    title: "One calculation source",
    content:
      "Final statutory deductions come from effective-dated backend rules, so an older phone release cannot silently use stale tax rates.",
  },
  {
    icon: Smartphone,
    title: "Kenya-first payments",
    content:
      "M-Pesa, bank, and cash workflows are designed around how Kenyan households actually pay and document domestic staff.",
  },
  {
    icon: FileText,
    title: "Records both sides can understand",
    content:
      "Itemized payslips and payment history give employers and workers a clearer shared record of every payday.",
  },
];

export default function HomeTestimonials() {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Built around a better <span className="text-gradient">payday</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            These are the product commitments guiding Paydome's Kenya launch.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {principles.map((principle) => (
            <div
              key={principle.title}
              className="relative p-6 rounded-xl border border-white/5 bg-white/[0.02] backdrop-blur-sm"
            >
              <div className="w-11 h-11 rounded-lg bg-emerald-500/10 flex items-center justify-center mb-4">
                <principle.icon className="w-5 h-5 text-emerald-400" />
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">
                {principle.title}
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                {principle.content}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
