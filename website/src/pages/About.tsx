import { Shield, Globe, Heart, Users } from "lucide-react";

const stats = [
  { value: "M-Pesa", label: "Salary Payments" },
  { value: "2026", label: "Effective-Dated Rates" },
  { value: "PDF", label: "Payslips & Reports" },
  { value: "KES", label: "Kenya-First Payroll" },
];

const values = [
  {
    icon: Heart,
    title: "Dignity for Workers",
    description:
      "We believe every domestic worker deserves timely pay, proper records, and the dignity of a professional payslip. Paydome makes this the standard.",
    color: "text-rose-400",
    bg: "bg-rose-500/10",
  },
  {
    icon: Shield,
    title: "Trust & Security",
    description:
      "Built with encrypted connections, access controls, and provider-backed payment flows to help protect sensitive payroll records.",
    color: "text-emerald-400",
    bg: "bg-emerald-500/10",
  },
  {
    icon: Users,
    title: "Built for Kenya",
    description:
      "From M-Pesa integration to PAYE, NSSF, SHIF, and Housing Levy records — every feature is designed specifically for how Kenyan households work.",
    color: "text-blue-400",
    bg: "bg-blue-500/10",
  },
  {
    icon: Globe,
    title: "German Precision",
    description:
      "As part of the PayGlobus Group, we bring German engineering standards to a product made for everyday Kenyan life.",
    color: "text-amber-400",
    bg: "bg-amber-500/10",
  },
];

export default function About() {
  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium mb-6">
            <Globe className="w-3 h-3" />
            PayGlobus Group
          </div>
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Built in Kenya, backed by{" "}
            <span className="text-gradient">German precision</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-3xl mx-auto">
            Paydome is a product of PayGlobus GmbH, designed specifically for
            Kenyan households who want to pay their domestic staff fairly, on
            time, and with proper records.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-24">
        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-24">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="p-6 rounded-xl border border-white/5 bg-white/[0.02] text-center"
            >
              <div className="text-2xl font-bold text-white mb-1">
                {stat.value}
              </div>
              <div className="text-sm text-slate-400">{stat.label}</div>
            </div>
          ))}
        </div>

        {/* Story */}
        <div className="grid lg:grid-cols-2 gap-12 items-center mb-24">
          <div>
            <h2 className="text-3xl font-bold text-white mb-6">Our Story</h2>
            <div className="space-y-4 text-slate-400 leading-relaxed">
              <p>
                It started with a simple problem: millions of Kenyan households
                employ domestic workers — house helps, gardeners, drivers,
                nannies — but paying them is often messy. Cash gets forgotten,
                records don't exist, and workers are left without proof of
                income or social security contributions.
              </p>
              <p>
                In 2021, a team at PayGlobus GmbH partnered with Kenyan
                developers and payroll specialists to build Paydome — a simple,
                affordable app that lets any household pay staff via M-Pesa,
                generate proper payslips, and keep the records needed for PAYE,
                NSSF, SHIF, and Housing Levy obligations.
              </p>
              <p>
                We are preparing Paydome for launch with Kenyan households and
                payroll specialists. Our goal is to make fair, well-documented
                household employment practical for more people.
              </p>
            </div>
          </div>
          <div className="relative">
            <div className="absolute -inset-4 bg-gradient-to-r from-emerald-500/10 to-green-500/10 rounded-2xl blur-2xl" />
            <div className="relative rounded-xl overflow-hidden border border-white/10">
              <img
                src="/employer-worker.jpg"
                alt="Kenyan employer and domestic worker using Paydome"
                className="w-full h-auto"
              />
            </div>
          </div>
        </div>

        {/* Values */}
        <div>
          <h2 className="text-3xl font-bold text-white text-center mb-12">
            What We Believe
          </h2>
          <div className="grid sm:grid-cols-2 gap-6">
            {values.map((value) => (
              <div
                key={value.title}
                className="p-6 rounded-xl border border-white/5 bg-white/[0.02]"
              >
                <div
                  className={`w-11 h-11 rounded-lg ${value.bg} flex items-center justify-center mb-4`}
                >
                  <value.icon className={`w-5 h-5 ${value.color}`} />
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">
                  {value.title}
                </h3>
                <p className="text-sm text-slate-400 leading-relaxed">
                  {value.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
