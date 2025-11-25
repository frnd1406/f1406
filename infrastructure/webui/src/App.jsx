import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import Layout from "./Layout";
import Files from "./pages/Files";
import Metrics from "./pages/Metrics";

function Dashboard() {
  return <div>Dashboard placeholder</div>;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="files" element={<Files />} />
          <Route path="metrics" element={<Metrics />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
