import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import IOSHelp from './pages/iOSHelp';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/marketing" element={<Home />} />
        <Route path="/help" element={<IOSHelp />} />
      </Routes>
    </Router>
  );
}

export default App;
