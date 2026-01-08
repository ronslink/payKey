import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import IOSHelp from './pages/iOSHelp';
import PrivacyPolicy from './pages/PrivacyPolicy';
import DeleteMe from './pages/DeleteMe';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/marketing" element={<Home />} />
        <Route path="/paydome/privacy_policy" element={<PrivacyPolicy />} />
        <Route path="/help" element={<IOSHelp />} />
        <Route path="/deleteme" element={<DeleteMe />} />
      </Routes>
    </Router>
  );
}

export default App;

