import { Navigate, Route, Routes, useLocation } from "react-router-dom";
import { MirrorFrame } from "./components/MirrorFrame";

const knownRoutes = new Set([
  "/",
  "/work",
  "/sales-platform",
  "/contact",
  "/404",
  "/work/website-prototyping",
  "/work/ai-receptionist",
  "/work/system-integration",
  "/article/clive-willow",
  "/article/raven-claw",
  "/article/clay-nicolas",
  "/article/gregory-lalle",
]);

function MirrorRoute() {
  const location = useLocation();
  const currentPath = location.pathname || "/";
  const routePath = knownRoutes.has(currentPath) ? currentPath : "/404";
  return <MirrorFrame routePath={routePath} />;
}

export function App() {
  return (
    <Routes>
      <Route path="/" element={<MirrorRoute />} />
      <Route path="/work" element={<MirrorRoute />} />
      <Route path="/sales-platform" element={<MirrorRoute />} />
      <Route path="/contact" element={<MirrorRoute />} />
      <Route path="/404" element={<MirrorRoute />} />
      <Route path="/work/website-prototyping" element={<MirrorRoute />} />
      <Route path="/work/ai-receptionist" element={<MirrorRoute />} />
      <Route path="/work/system-integration" element={<MirrorRoute />} />
      <Route path="/article/clive-willow" element={<MirrorRoute />} />
      <Route path="/article/raven-claw" element={<MirrorRoute />} />
      <Route path="/article/clay-nicolas" element={<MirrorRoute />} />
      <Route path="/article/gregory-lalle" element={<MirrorRoute />} />
      <Route path="*" element={<Navigate to="/404" replace />} />
    </Routes>
  );
}
