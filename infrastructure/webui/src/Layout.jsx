import PropTypes from "prop-types";
import { Link, Outlet, useLocation } from "react-router-dom";
import { getAuth } from "./utils/auth";

const navLinks = [
  { to: "/dashboard", label: "Dashboard" },
  { to: "/metrics", label: "Metrics" },
  { to: "/files", label: "Files" },
];

export default function Layout({ title = "NAS.AI" }) {
  const location = useLocation();
  const { accessToken } = getAuth();

  return (
    <div style={{ display: "flex", minHeight: "100vh", fontFamily: "sans-serif" }}>
      <aside
        style={{
          width: "220px",
          borderRight: "1px solid #ddd",
          padding: "1rem",
          background: "#f8f9fb",
        }}
      >
        <div style={{ fontWeight: 700, marginBottom: "1rem" }}>{title}</div>
        <nav>
          <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "grid", gap: "0.5rem" }}>
            {navLinks.map((link) => {
              const active = location.pathname.startsWith(link.to);
              return (
                <li key={link.to}>
                  <Link
                    to={link.to}
                    style={{
                      textDecoration: "none",
                      color: active ? "#0b5ed7" : "#111",
                      fontWeight: active ? 700 : 500,
                    }}
                  >
                    {link.label}
                  </Link>
                </li>
              );
            })}
            {!accessToken && (
              <li>
                <Link to="/login">Login</Link>
              </li>
            )}
          </ul>
        </nav>
      </aside>
      <main style={{ flex: 1, padding: "1.5rem" }}>
        <Outlet />
      </main>
    </div>
  );
}

Layout.propTypes = {
  title: PropTypes.string,
};
