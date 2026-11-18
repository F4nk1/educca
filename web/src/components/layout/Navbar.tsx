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
  Server,
  Database,
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import styles from './Navbar.module.css';

export const Navbar: React.FC = () => {
  const { user, role, switchRole, logout, isDemoMode, toggleDemoMode } = useAuth();
  const navigate = useNavigate();

  const handleRoleChange = (newRole: 'coordinador' | 'capacitador') => {
    if (isDemoMode) {
      switchRole(newRole);
    }
    if (newRole === 'coordinador') {
      navigate('/coordinator');
    } else {
      navigate('/trainer/qr');
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isCoordinator = role === 'coordinador' || (user?.roles && (user.roles.includes('admin') || user.roles.includes('coordinador')));

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
          {/* Data Mode Indicator */}
          <button
            onClick={() => toggleDemoMode(!isDemoMode)}
            title={isDemoMode ? 'Modo Demo (Click para cambiar a Backend API)' : 'Modo API Real (Click para cambiar a Demo)'}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '5px',
              padding: '3px 8px',
              fontSize: '11px',
              fontWeight: 600,
              borderRadius: '9999px',
              backgroundColor: isDemoMode ? '#FEF3C7' : '#DCFCE7',
              color: isDemoMode ? '#92400E' : '#166534',
              border: `1px solid ${isDemoMode ? '#FDE68A' : '#BBF7D0'}`,
              cursor: 'pointer',
            }}
          >
            {isDemoMode ? <Database size={12} /> : <Server size={12} />}
            <span>{isDemoMode ? 'Demo' : 'API Real'}</span>
          </button>

          {/* Quick role switcher for testing view transitions */}
          <div className={styles.roleSelector} title="Cambiar rol activo para demostración">
            <button
              className={`${styles.roleButton} ${isCoordinator ? styles.roleButtonActive : ''}`}
              onClick={() => handleRoleChange('coordinador')}
            >
              Coordinador
            </button>
            <button
              className={`${styles.roleButton} ${!isCoordinator ? styles.roleButtonActive : ''}`}
              onClick={() => handleRoleChange('capacitador')}
            >
              Capacitador
            </button>
          </div>

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
