import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, LogIn, AlertCircle, ShieldAlert, Database, Server } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import paisajeSvg from '../../assets/paisaje_andino.svg';
import styles from './Login.module.css';

export const Login: React.FC = () => {
  const { login, isDemoMode, toggleDemoMode } = useAuth();
  const navigate = useNavigate();

  const [identificador, setIdentificador] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Institutional password reset instructions modal
  const [forgotModalOpen, setForgotModalOpen] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!identificador.trim()) {
      setError('Por favor ingrese su identificador (correo institucional o DNI)');
      return;
    }
    if (!password) {
      setError('Por favor ingrese su contraseña');
      return;
    }

    setIsSubmitting(true);
    try {
      const loggedUser = await login(identificador.trim(), password);
      const isCoord =
        loggedUser.rol === 'admin' ||
        loggedUser.rol === 'coordinador' ||
        loggedUser.rol === 'consulta' ||
        loggedUser.roles?.includes('admin') ||
        loggedUser.roles?.includes('coordinador') ||
        loggedUser.roles?.includes('consulta');

      navigate(isCoord ? '/coordinator' : '/trainer/qr', { replace: true });
    } catch (err: unknown) {
      const msg =
        err instanceof Error
          ? err.message
          : 'Error al iniciar sesión. Verifique sus credenciales.';
      setError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className={styles.loginLayout}>
      {/* LEFT COLUMN: Clean Minimalist Login Form */}
      <div className={styles.formSection}>
        <div className={styles.formContainer}>
          <div className={styles.brandHeader}>
            <div className={styles.brandBadge}>MUNICIPALIDAD PROVINCIAL DEL CUSCO</div>
            <h1 className={styles.title}>Iniciar Sesión</h1>
            <p className={styles.subtitle}>
              Ingresa tus credenciales institucionales para acceder al sistema EDUCCA
            </p>
          </div>

          {error && (
            <div className={styles.errorAlert} role="alert">
              <AlertCircle size={18} className={styles.errorIcon} />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className={styles.loginForm}>
            <div className={styles.fieldGroup}>
              <Input
                label="Identificador (Correo institucional o DNI)"
                type="text"
                value={identificador}
                onChange={e => setIdentificador(e.target.value)}
                placeholder="ej. admin@educca.gob.pe o 00000000"
                icon={<Mail size={18} />}
                required
                autoComplete="username"
              />
            </div>

            <div className={styles.fieldGroup}>
              <Input
                label="Contraseña"
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                icon={<Lock size={18} />}
                required
                autoComplete="current-password"
              />
            </div>

            <div className={styles.formActionsRow} style={{ justifyContent: 'space-between' }}>
              {import.meta.env.DEV && (
                <button
                  type="button"
                  className={styles.forgotLink}
                  onClick={() => {
                    setIdentificador('admin@educca.gob.pe');
                    setPassword('password123');
                  }}
                >
                  Autocompletar semilla (Dev)
                </button>
              )}
              <button
                type="button"
                className={styles.forgotLink}
                onClick={() => setForgotModalOpen(true)}
                style={{ marginLeft: 'auto' }}
              >
                ¿Olvidaste tu contraseña?
              </button>
            </div>

            <Button
              type="submit"
              variant="primary"
              size="lg"
              fullWidth
              disabled={isSubmitting}
              icon={<LogIn size={18} />}
            >
              {isSubmitting ? 'Iniciando sesión...' : 'Iniciar Sesión'}
            </Button>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                paddingTop: '8px',
                fontSize: '12px',
                color: '#64748B',
              }}
            >
              <span>Modo de conexión actual:</span>
              <button
                type="button"
                onClick={() => toggleDemoMode(!isDemoMode)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '5px',
                  padding: '3px 10px',
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
                <span>{isDemoMode ? 'Modo Demo (Local)' : 'API Real (Go + PostgreSQL)'}</span>
              </button>
            </div>
          </form>

          <footer className={styles.formFooter}>
            <p>Programa Municipal de Educación, Cultura y Ciudadanía Ambiental</p>
            <p className={styles.copyright}>
              © Municipalidad Provincial del Cusco — Gerencia de Medio Ambiente
            </p>
          </footer>
        </div>
      </div>

      {/* RIGHT COLUMN: Full-Height Environmental Illustration Panel */}
      <div className={styles.illustrationSection}>
        <div className={styles.illustrationBackground}>
          <img
            src={paisajeSvg}
            alt="Paisaje Andino Cusco"
            className={styles.illustrationImage}
          />
        </div>
        <div className={styles.illustrationContent}>
          <div className={styles.illustrationTag}>SISTEMA DE GESTIÓN AMBIENTAL</div>
          <h2 className={styles.illustrationTitle}>EDUCCA Cusco</h2>
          <p className={styles.illustrationText}>
            Fortaleciendo la cultura ambiental y el desarrollo sostenible en la Ciudad Imperial del
            Cusco a través de capacitaciones y participación ciudadana.
          </p>
          <div className={styles.illustrationFooterBadge}>
            Gestión Operativa • Sedes • Talleres • Asistencias
          </div>
        </div>
      </div>

      {/* Institutional Password Reset Instructions Modal */}
      <Modal
        isOpen={forgotModalOpen}
        onClose={() => setForgotModalOpen(false)}
        title="Restablecimiento de Contraseña Institucional"
        footer={<Button onClick={() => setForgotModalOpen(false)}>Entendido</Button>}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-start',
              gap: '10px',
              padding: '12px',
              backgroundColor: '#F0F7F4',
              border: '1px solid #C3DFD3',
              borderRadius: '8px',
              color: '#153B2F',
              fontSize: '13px',
            }}
          >
            <ShieldAlert size={20} style={{ flexShrink: 0, marginTop: '2px' }} />
            <div>
              <strong>Política de Seguridad Municipal (LPDP)</strong>
              <p style={{ marginTop: '4px', color: '#334155' }}>
                Por razones de seguridad y control de acceso basado en roles (RBAC), el cambio o
                restablecimiento de credenciales de Coordinadores y Capacitadores es realizado por
                un <strong>Administrador del Sistema EDUCCA</strong> desde el módulo de{' '}
                <em>Directorio de Usuarios</em>.
              </p>
            </div>
          </div>
          <p style={{ color: '#64748B', fontSize: '12px' }}>
            Comuníquese con la Gerencia de Medio Ambiente de la Municipalidad Provincial del Cusco
            indicando su número de DNI o correo institucional para la asignación de una nueva
            contraseña temporal.
          </p>
        </div>
      </Modal>
    </div>
  );
};
