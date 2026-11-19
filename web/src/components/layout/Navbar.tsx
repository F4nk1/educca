import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  MapPin,
  BookOpen,
  CalendarDays,
  Users,
  ClipboardCheck,
  QrCode,
  LogOut,
  Leaf,
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import styles from './Navbar.module.css';

export const Navbar: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isCoordinator =
    user &&
    (user.rol === 'coordinador' ||
      user.rol === 'admin' ||
      (user.roles && (user.roles.includes('admin') || user.roles.includes('coordinador'))));

  return (
    <header className={styles.header}>
      <div className={styles.topBar}>
        <div className={styles.brandGroup}>
          <NavLink to={isCoordinator ? '/coordinator' : '/trainer/qr'} className={styles.brand}>
            <div className={styles.logoIcon}>
              <Leaf size={18} />
            </div>
            <div className={styles.brandText}>
              <span className={styles.brandTitle}>EDUCCA Cusco</span>
              <span className={styles.brandSubtitle}>Gestión Ambiental</span>
            </div>
          </NavLink>

          {/* Horizontal Top Navigation */}
          <nav className={styles.navLinks}>
            {isCoordinator ? (
              <>
                <NavLink
                  to="/coordinator"
                  end
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <LayoutDashboard size={16} />
                  <span>Inicio</span>
                </NavLink>

                <NavLink
                  to="/coordinator/venues"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <MapPin size={16} />
                  <span>Sedes</span>
                </NavLink>

                <NavLink
                  to="/coordinator/workshops"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <BookOpen size={16} />
                  <span>Talleres</span>
                </NavLink>

                <NavLink
                  to="/coordinator/sessions"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <CalendarDays size={16} />
                  <span>Sesiones</span>
                </NavLink>

                <NavLink
                  to="/coordinator/attendances"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <ClipboardCheck size={16} />
                  <span>Asistencias</span>
                </NavLink>

                <NavLink
                  to="/coordinator/users"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <Users size={16} />
                  <span>Usuarios</span>
                </NavLink>
              </>
            ) : (
              <>
                <NavLink
                  to="/trainer/qr"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <QrCode size={16} />
                  <span>Panel QR</span>
                </NavLink>

                <NavLink
                  to="/trainer/attendances"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <ClipboardCheck size={16} />
                  <span>Asistencias</span>
                </NavLink>
              </>
            )}
          </nav>
        </div>

        <div className={styles.actionsGroup}>
          {user && (
            <div className={styles.userProfile}>
              <div className={styles.avatar}>
                {user.nombres ? user.nombres.charAt(0) : 'U'}
                {user.apellidos ? user.apellidos.charAt(0) : ''}
              </div>
              <div className={styles.userInfo}>
                <span className={styles.userName}>
                  {user.nombres.split(' ')[0]} {user.apellidos.split(' ')[0]}
                </span>
                <span className={styles.userRole}>
                  {user.roles && user.roles.length > 0 ? user.roles.join(', ') : user.rol}
                </span>
              </div>
              <button
                onClick={handleLogout}
                className={styles.navLink}
                title="Cerrar sesión"
                style={{ padding: '6px', marginLeft: '4px' }}
              >
                <LogOut size={16} />
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
