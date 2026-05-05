import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Home from './pages/Home'
import Pricing from './pages/Pricing'
import Features from './pages/Features'
import About from './pages/About'
import Help from './pages/Help'
import Contact from './pages/Contact'
import PrivacyPolicy from './pages/PrivacyPolicy'
import DeleteMe from './pages/DeleteMe'
import PaymentSuccess from './pages/PaymentSuccess'

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<Home />} />
        <Route path="/marketing" element={<Home />} />
        <Route path="/pricing" element={<Pricing />} />
        <Route path="/features" element={<Features />} />
        <Route path="/about" element={<About />} />
        <Route path="/help" element={<Help />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/paydome/privacy_policy" element={<PrivacyPolicy />} />
        <Route path="/deleteme" element={<DeleteMe />} />
        <Route path="/subscription/success" element={<PaymentSuccess />} />
        {/* Stripe redirects here after checkout — matches backend success_url */}
        <Route path="/payments/subscriptions/success" element={<PaymentSuccess />} />
      </Route>
    </Routes>
  )
}
