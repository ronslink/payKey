import { Check, HelpCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";

interface Plan {
  name: string;
  description: string;
  price: string;
  yearlyPrice: string;
  period: string;
  features: string[];
  cta: string;
  highlighted: boolean;
}

const definePlan = (
  name: string,
  description: string,
  price: string,
  yearlyPrice: string,
  features: string[],
  cta: string,
  highlighted = false,
): Plan => ({
  name,
  description,
  price,
  yearlyPrice,
  period: "/month",
  features,
  cta,
  highlighted,
});

const plans = [
  definePlan(
    "Free",
    "Start with one worker and core payroll tools",
    "0",
    "0",
    [
      "Up to 1 worker",
      "Basic worker management",
      "Automatic tax calculations",
    ],
    "Get Started",
  ),
  definePlan(
    "Basic",
    "For households ready to pay through Paydome",
    "1,300",
    "13,000",
    [
      "Up to 5 workers",
      "Automatic tax calculations",
      "M-Pesa payments",
      "P9 supporting summaries",
    ],
    "Choose Basic",
    true,
  ),
  definePlan(
    "Gold",
    "For larger households that need reporting and imports",
    "3,900",
    "39,000",
    [
      "Up to 10 workers",
      "Automatic tax calculations",
      "M-Pesa payments",
      "P9 supporting summaries",
      "Advanced reporting",
      "Accounting exports",
      "Priority support",
      "Excel worker import",
    ],
    "Choose Gold",
  ),
  definePlan(
    "Platinum",
    "For multi-property households and advanced operations",
    "6,500",
    "65,000",
    [
      "Up to 20 workers",
      "Automatic tax calculations",
      "M-Pesa payments",
      "Leave tracking",
      "Time tracking (clock in/out)",
      "Geofencing",
      "Advanced reporting",
      "Accounting exports",
      "Priority support",
      "Statutory contribution schedules",
      "Multi-property management",
      "Excel worker import",
    ],
    "Choose Platinum",
  ),
];

const faqItems = [
  {
    q: "Can I change plans anytime?",
    a: "Contact our team to change an existing paid plan. Card subscriptions renew automatically unless you turn renewal off. M-Pesa renewals require your approval for each payment.",
  },
  {
    q: "Is there a setup fee?",
    a: "No setup fees. Just download the app, add your staff, and start paying.",
  },
  {
    q: "Can I pay for my subscription with M-Pesa?",
    a: "Yes. Choose M-Pesa at checkout, review the exact KES price, and approve the prompt on your phone. Each renewal needs your approval; your M-Pesa account is not debited automatically.",
  },
  {
    q: "How can I get started?",
    a: "Visit Get started for available app access or contact our team. We can confirm which plans and purchase options are currently available for your device.",
  },
];

export default function Pricing() {
  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Simple pricing for every{" "}
            <span className="text-gradient">household</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Start free, then upgrade when you need more workers or advanced
            payroll tools. All prices are in Kenyan Shillings.
          </p>
          <p className="text-sm text-slate-400 max-w-2xl mx-auto mt-3">
            Pay for your subscription with M-Pesa in KES or by card in USD.
            Review the server-confirmed amount before paying. M-Pesa needs your
            approval each period; card subscriptions renew automatically.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-24">
        <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-6 lg:gap-8">
          {plans.map((plan) => (
            <div
              key={plan.name}
              className={`relative rounded-2xl p-6 lg:p-8 ${
                plan.highlighted
                  ? "border-2 border-emerald-500 bg-emerald-500/5 shadow-xl shadow-emerald-500/10"
                  : "border border-white/5 bg-white/[0.02]"
              }`}
            >
              {plan.highlighted && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-emerald-500 text-white text-xs font-semibold">
                  Most Popular
                </div>
              )}

              <div className="mb-6">
                <h3 className="text-xl font-bold text-white mb-1">
                  {plan.name}
                </h3>
                <p className="text-sm text-slate-400">{plan.description}</p>
              </div>

              <div className="mb-6">
                <span className="text-lg text-slate-400">KES </span>
                <span className="text-4xl font-bold text-white">
                  {plan.price}
                </span>
                <span className="text-slate-400">{plan.period}</span>
                <p className="text-xs text-slate-500 mt-2">
                  KES {plan.yearlyPrice} yearly
                </p>
              </div>

              <ul className="space-y-3 mb-8">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-3">
                    <Check className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
                    <span className="text-sm text-slate-300">{feature}</span>
                  </li>
                ))}
              </ul>

              <Button
                asChild
                className={`w-full font-semibold ${
                  plan.highlighted
                    ? "bg-emerald-500 hover:bg-emerald-600 text-white shadow-lg shadow-emerald-500/20"
                    : "bg-white/5 hover:bg-white/10 text-white border border-white/10"
                }`}
              >
                <Link to={`/account?plan=${plan.name.toLowerCase()}`}>{plan.cta}</Link>
              </Button>
            </div>
          ))}
        </div>

        {/* FAQ */}
        <div className="mt-24 max-w-3xl mx-auto">
          <h2 className="text-2xl font-bold text-white text-center mb-8">
            Frequently asked questions
          </h2>
          <TooltipProvider>
            <div className="space-y-4">
              {faqItems.map((item) => (
                <div
                  key={item.q}
                  className="p-4 rounded-xl border border-white/5 bg-white/[0.02]"
                >
                  <div className="flex items-start gap-3">
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <HelpCircle className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5 cursor-help" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Click to learn more</p>
                      </TooltipContent>
                    </Tooltip>
                    <div>
                      <h4 className="text-sm font-semibold text-white mb-1">
                        {item.q}
                      </h4>
                      <p className="text-sm text-slate-400">{item.a}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </TooltipProvider>
        </div>
      </div>
    </div>
  );
}
