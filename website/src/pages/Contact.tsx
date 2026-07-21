import { useState } from "react";
import { Mail, Send } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function Contact() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    message: "",
    interest: "general",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const subject = `Paydome ${formData.interest} enquiry from ${formData.name}`;
    const body = [
      `Name: ${formData.name}`,
      `Email: ${formData.email}`,
      formData.phone ? `Phone: ${formData.phone}` : "",
      `Topic: ${formData.interest}`,
      "",
      formData.message,
    ]
      .filter(Boolean)
      .join("\n");

    window.location.href = `mailto:support@paydome.co?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  };

  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Get in <span className="text-gradient">touch</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Have a question about setup, payroll, or payments? Contact Paydome
            support by email.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-24">
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Contact Info Sidebar */}
          <div className="space-y-4">
            <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02]">
              <Mail className="w-5 h-5 text-emerald-400 mb-3" />
              <h3 className="text-sm font-semibold text-white mb-1">Email</h3>
              <a
                href="mailto:support@paydome.co"
                className="text-sm text-slate-400 hover:text-emerald-400 transition-colors"
              >
                support@paydome.co
              </a>
              <p className="text-xs text-slate-500 mt-1">
                We will reply as soon as possible.
              </p>
            </div>
          </div>

          {/* Contact Form */}
          <div className="lg:col-span-2">
            <form
              onSubmit={handleSubmit}
              className="p-6 sm:p-8 rounded-xl border border-white/5 bg-white/[0.02]"
            >
              <h2 className="text-xl font-bold text-white mb-2">
                Prepare an email
              </h2>
              <p className="text-sm text-slate-400 mb-6">
                Submitting this form opens your email app with the details
                filled in. You can review the message before sending it.
              </p>

              <div className="grid sm:grid-cols-2 gap-4 mb-4">
                <div>
                  <label
                    htmlFor="contact-name"
                    className="block text-sm font-medium text-slate-300 mb-2"
                  >
                    Name *
                  </label>
                  <input
                    id="contact-name"
                    name="name"
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                    placeholder="Your name"
                  />
                </div>
                <div>
                  <label
                    htmlFor="contact-email"
                    className="block text-sm font-medium text-slate-300 mb-2"
                  >
                    Email *
                  </label>
                  <input
                    id="contact-email"
                    name="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) =>
                      setFormData({ ...formData, email: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                    placeholder="you@email.com"
                  />
                </div>
              </div>

              <div className="grid sm:grid-cols-2 gap-4 mb-4">
                <div>
                  <label
                    htmlFor="contact-phone"
                    className="block text-sm font-medium text-slate-300 mb-2"
                  >
                    Phone Number
                  </label>
                  <input
                    id="contact-phone"
                    name="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={(e) =>
                      setFormData({ ...formData, phone: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                    placeholder="+254 7XX XXX XXX"
                  />
                </div>
                <div>
                  <label
                    htmlFor="contact-interest"
                    className="block text-sm font-medium text-slate-300 mb-2"
                  >
                    What do you need help with?
                  </label>
                  <select
                    id="contact-interest"
                    name="interest"
                    value={formData.interest}
                    onChange={(e) =>
                      setFormData({ ...formData, interest: e.target.value })
                    }
                    className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all appearance-none"
                  >
                    <option value="general" className="bg-[#0D1525]">
                      General Question
                    </option>
                    <option value="onboarding" className="bg-[#0D1525]">
                      Getting Started
                    </option>
                    <option value="support" className="bg-[#0D1525]">
                      Technical Support
                    </option>
                    <option value="enterprise" className="bg-[#0D1525]">
                      Business / Agency
                    </option>
                  </select>
                </div>
              </div>

              <div className="mb-6">
                <label
                  htmlFor="contact-message"
                  className="block text-sm font-medium text-slate-300 mb-2"
                >
                  Message *
                </label>
                <textarea
                  id="contact-message"
                  name="message"
                  required
                  rows={5}
                  value={formData.message}
                  onChange={(e) =>
                    setFormData({ ...formData, message: e.target.value })
                  }
                  className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all resize-none"
                  placeholder="How can we help you?"
                />
              </div>

              <Button
                type="submit"
                className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-3 shadow-lg shadow-emerald-500/20"
              >
                <Send className="w-4 h-4 mr-2" />
                Open email draft
              </Button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
