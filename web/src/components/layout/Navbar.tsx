import React from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
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
  ArrowLeft,
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import styles from './Navbar.module.css';

export const Navbar: React.FC = () => {
  const { user, isCoordinator, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const isTrainerViewActive = location.pathname.startsWith('/trainer');
  const showCoordinatorMenu = isCoordinator && !isTrainerViewActive;

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header className={styles.header}>
      <div className={styles.topBar}>
        <div className={styles.brandGroup}>
          <NavLink
            to={isCoordinator ? '/coordinator' : '/trainer/qr'}
            className={styles.brand}
            title="Ir al inicio de EDUCCA Cusco"
          >
            <div className={styles.logoIcon}>
              <Leaf size={18} />
            </div>
            <div className={styles.brandText}>
              <span className={styles.brandTitle}>EDUCCA Cusco</span>
              <span className={styles.brandSubtitle}>Gestión Ambiental</span>
            </div>
          </NavLink>

          {/* Horizontal Top Navigation */}
          <nav className={styles.navLinks} aria-label="Navegación principal">
            {showCoordinatorMenu ? (
              <>
                <NavLink
                  to="/coordinator"
                  end
                  title="Panel de Inicio"
                  aria-label="Panel de Inicio"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <LayoutDashboard size={16} />
                  <span>Inicio</span>
                </NavLink>

                <NavLink
                  to="/coordinator/venues"
                  title="Sedes Georreferenciadas"
                  aria-label="Sedes Georreferenciadas"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <MapPin size={16} />
                  <span>Sedes</span>
                </NavLink>

                <NavLink
                  to="/coordinator/workshops"
                  title="Catálogo de Talleres"
                  aria-label="Catálogo de Talleres"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <BookOpen size={16} />
                  <span>Talleres</span>
                </NavLink>

                <NavLink
                  to="/coordinator/sessions"
                  title="Sesiones Operativas"
                  aria-label="Sesiones Operativas"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <CalendarDays size={16} />
                  <span>Sesiones</span>
                </NavLink>

                <NavLink
                  to="/coordinator/attendances"
                  title="Consulta Global de Asistencias"
                  aria-label="Consulta Global de Asistencias"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <ClipboardCheck size={16} />
                  <span>Asistencias</span>
                </NavLink>

                <NavLink
                  to="/coordinator/users"
                  title="Directorio de Usuarios"
                  aria-label="Directorio de Usuarios"
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
                {isCoordinator && (
                  <NavLink
                    to="/coordinator/sessions"
                    title="Volver al Panel de Coordinación"
                    aria-label="Volver al Panel de Coordinación"
                    className={styles.navLink}
                  >
                    <ArrowLeft size={16} />
                    <span>Gestión</span>
                  </NavLink>
                )}

                <NavLink
                  to="/trainer/qr"
                  title="Panel de Código QR"
                  aria-label="Panel de Código QR"
                  className={({ isActive }) =>
                    `${styles.navLink} ${isActive ? styles.navLinkActive : ''}`
                  }
                >
                  <QrCode size={16} />
                  <span>Panel QR</span>
                </NavLink>

                <NavLink
                  to="/trainer/attendances"
                  title="Lista de Asistencias de Sesión"
                  aria-label="Lista de Asistencias de Sesión"
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
                type="button"
                onClick={handleLogout}
                className={styles.navLink}
                title="Cerrar sesión"
                aria-label="Cerrar sesión"
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
