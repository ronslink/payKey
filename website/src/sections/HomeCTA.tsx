import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { ArrowRight, Calendar } from "lucide-react";

export default function HomeCTA() {
  return (
    <section className="relative py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="relative overflow-hidden rounded-2xl border border-emerald-500/20 bg-gradient-to-br from-emerald-600/20 via-emerald-900/20 to-green-600/10 backdrop-blur-sm p-8 sm:p-12 lg:p-16">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[300px] bg-emerald-500/20 rounded-full blur-[100px] pointer-events-none" />

          <div className="relative flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="text-center lg:text-left">
              <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
                Start paying your staff the right way
              </h2>
              <p className="text-lg text-slate-300 max-w-xl">
                Find out how to access the app and set up your household payroll.
                Our team can help you take the first step.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center gap-4 shrink-0">
                <Button
                  asChild
                  size="lg"
                  className="bg-white hover:bg-slate-100 text-emerald-900 font-semibold px-8 shadow-xl transition-all hover:scale-[1.02]"
                >
                  <Link to="/get-started">Get started <ArrowRight className="w-4 h-4 ml-2" /></Link>
                </Button>
                <Button
                  asChild
                  size="lg"
                  variant="outline"
                  className="border-white/20 bg-white/5 hover:bg-white/10 text-white font-semibold px-8 backdrop-blur-sm"
                >
                  <Link to="/contact"><Calendar className="w-4 h-4 mr-2" /> Book a Demo</Link>
                </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
