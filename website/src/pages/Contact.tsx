import { useState } from 'react'
import { Mail, Phone, MapPin, Clock, Send, CheckCircle, MessageCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'

export default function Contact() {
  const [submitted, setSubmitted] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    message: '',
    interest: 'general',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitted(true)
  }

  return (
    <div className="relative">
      <div className="relative pt-16 pb-12">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[300px] bg-emerald-500/10 rounded-full blur-[100px] pointer-events-none" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Get in <span className="text-gradient">touch</span>
          </h1>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Have questions? Our Nairobi-based team is here to help.
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
              <p className="text-sm text-slate-400">support@paydome.co</p>
              <p className="text-xs text-slate-500 mt-1">Response within 2 hours</p>
            </div>
            <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02]">
              <Phone className="w-5 h-5 text-emerald-400 mb-3" />
              <h3 className="text-sm font-semibold text-white mb-1">Phone</h3>
              <p className="text-sm text-slate-400">+254 700 123 456</p>
              <p className="text-xs text-slate-500 mt-1">Mon-Sat, 8AM-6PM EAT</p>
            </div>
            <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02]">
              <MessageCircle className="w-5 h-5 text-emerald-400 mb-3" />
              <h3 className="text-sm font-semibold text-white mb-1">WhatsApp</h3>
              <p className="text-sm text-slate-400">+254 700 123 457</p>
              <p className="text-xs text-slate-500 mt-1">Quick help & questions</p>
            </div>
            <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02]">
              <MapPin className="w-5 h-5 text-emerald-400 mb-3" />
              <h3 className="text-sm font-semibold text-white mb-1">Office</h3>
              <p className="text-sm text-slate-400">
                Paydome Kenya<br />
                Mirage Towers, Westlands<br />
                Nairobi, Kenya
              </p>
            </div>
            <div className="p-5 rounded-xl border border-white/5 bg-white/[0.02]">
              <Clock className="w-5 h-5 text-emerald-400 mb-3" />
              <h3 className="text-sm font-semibold text-white mb-1">Support Hours</h3>
              <p className="text-sm text-slate-400">
                Monday - Saturday<br />
                8:00 AM - 6:00 PM EAT<br />
                <span className="text-xs text-slate-500">Emergency support available 24/7</span>
              </p>
            </div>
          </div>

          {/* Contact Form */}
          <div className="lg:col-span-2">
            {submitted ? (
              <div className="flex flex-col items-center justify-center h-full text-center p-12 rounded-xl border border-emerald-500/20 bg-emerald-500/5">
                <CheckCircle className="w-16 h-16 text-emerald-400 mb-4" />
                <h2 className="text-2xl font-bold text-white mb-2">Message Sent!</h2>
                <p className="text-slate-400 max-w-md">
                  Thank you for reaching out. Our Nairobi team will get back to you within 2 hours.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="p-6 sm:p-8 rounded-xl border border-white/5 bg-white/[0.02]">
                <h2 className="text-xl font-bold text-white mb-6">Send us a message</h2>
                
                <div className="grid sm:grid-cols-2 gap-4 mb-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">Name *</label>
                    <input
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                      placeholder="Your name"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">Email *</label>
                    <input
                      type="email"
                      required
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                      placeholder="you@email.com"
                    />
                  </div>
                </div>

                <div className="grid sm:grid-cols-2 gap-4 mb-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">Phone Number</label>
                    <input
                      type="tel"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all"
                      placeholder="+254 7XX XXX XXX"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">What do you need help with?</label>
                    <select
                      value={formData.interest}
                      onChange={(e) => setFormData({ ...formData, interest: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all appearance-none"
                    >
                      <option value="general" className="bg-[#0D1525]">General Question</option>
                      <option value="onboarding" className="bg-[#0D1525]">Getting Started</option>
                      <option value="support" className="bg-[#0D1525]">Technical Support</option>
                      <option value="enterprise" className="bg-[#0D1525]">Business / Agency</option>
                    </select>
                  </div>
                </div>

                <div className="mb-6">
                  <label className="block text-sm font-medium text-slate-300 mb-2">Message *</label>
                  <textarea
                    required
                    rows={5}
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg bg-white/5 border border-white/10 text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500/50 transition-all resize-none"
                    placeholder="How can we help you?"
                  />
                </div>

                <Button
                  type="submit"
                  className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-3 shadow-lg shadow-emerald-500/20"
                >
                  <Send className="w-4 h-4 mr-2" />
                  Send Message
                </Button>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
