import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock, LogIn, AlertCircle, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import paisajeSvg from '../../assets/paisaje_andino.svg';
import styles from './Login.module.css';

export const Login: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [identificador, setIdentificador] = useState('admin@educca.gob.pe');
  const [password, setPassword] = useState('password123');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Forgot password modal
  const [forgotModalOpen, setForgotModalOpen] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotSubmitted, setForgotSubmitted] = useState(false);

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
      const isCoordinator =
        loggedUser.rol === 'coordinador' ||
        loggedUser.rol === 'admin' ||
        (loggedUser.roles && (loggedUser.roles.includes('admin') || loggedUser.roles.includes('coordinador')));

      if (isCoordinator) {
        navigate('/coordinator');
      } else {
        navigate('/trainer/qr');
      }
    } catch (err: any) {
      setError(err?.message || 'Error al iniciar sesión. Verifique sus credenciales.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleForgotSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (forgotEmail) {
      setForgotSubmitted(true);
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

            <div className={styles.formActionsRow}>
              <button
                type="button"
                className={styles.forgotLink}
                onClick={() => {
                  setForgotModalOpen(true);
                  setForgotSubmitted(false);
                  setForgotEmail(identificador.includes('@') ? identificador : '');
                }}
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
          </form>

          <footer className={styles.formFooter}>
            <p>Programa Municipal de Educación, Cultura y Ciudadanía Ambiental</p>
            <p className={styles.copyright}>© Municipalidad Provincial del Cusco — Gerencia de Medio Ambiente</p>
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
            Fortaleciendo la cultura ambiental y el desarrollo sostenible en la Ciudad Imperial del Cusco a través de capacitaciones y participación ciudadana.
          </p>
          <div className={styles.illustrationFooterBadge}>
            Gestión Operativa • Sedes • Talleres • Asistencias
          </div>
        </div>
      </div>

      {/* Forgot Password Modal */}
      <Modal
        isOpen={forgotModalOpen}
        onClose={() => setForgotModalOpen(false)}
        title="Recuperar Contraseña"
        footer={
          forgotSubmitted ? (
            <Button onClick={() => setForgotModalOpen(false)}>Entendido</Button>
          ) : (
            <>
              <Button variant="outline" onClick={() => setForgotModalOpen(false)}>
                Cancelar
              </Button>
              <Button onClick={handleForgotSubmit}>Enviar Enlace</Button>
            </>
          )
        }
      >
        {forgotSubmitted ? (
          <div style={{ textAlign: 'center', padding: '16px 0' }}>
            <CheckCircle2 size={48} color="#16A34A" style={{ margin: '0 auto 12px' }} />
            <h4 style={{ marginBottom: '8px', fontSize: '16px', fontWeight: 600 }}>Solicitud Registrada</h4>
            <p style={{ color: '#64748B', fontSize: '13px' }}>
              Se ha enviado un enlace de restablecimiento al correo institucional{' '}
              <strong>{forgotEmail}</strong>.
            </p>
          </div>
        ) : (
          <form onSubmit={handleForgotSubmit}>
            <p style={{ color: '#64748B', fontSize: '13px', marginBottom: '16px' }}>
              Ingrese su correo electrónico registrado para recibir las instrucciones de restablecimiento de contraseña.
            </p>
            <Input
              label="Correo institucional"
              type="email"
              value={forgotEmail}
              onChange={e => setForgotEmail(e.target.value)}
              placeholder="usuario@educca.gob.pe"
              required
            />
          </form>
        )}
      </Modal>
    </div>
  );
};
