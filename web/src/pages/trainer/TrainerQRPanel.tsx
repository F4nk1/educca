import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { QRCodeSVG } from 'qrcode.react';
import {
  QrCode,
  Play,
  Square,
  Clock,
  MapPin,
  BookOpen,
  ClipboardList,
  AlertTriangle,
  RotateCw,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { SessionItem, GoQRResponse, GoSesionMonitoreo } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Card } from '../../components/ui/Card';
import styles from './TrainerQRPanel.module.css';

export const TrainerQRPanel: React.FC = () => {
  const [sessions, setSessions] = useState<SessionItem[]>([]);
  const [selectedSessionId, setSelectedSessionId] = useState<string>('');
  const [activeSession, setActiveSession] = useState<SessionItem | null>(null);
  const [qrData, setQrData] = useState<GoQRResponse | null>(null);
  const [monitoreo, setMonitoreo] = useState<GoSesionMonitoreo | null>(null);
  const [secondsRemaining, setSecondsRemaining] = useState<number>(0);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isActionLoading, setIsActionLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const navigate = useNavigate();
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  // Load available sessions for trainer
  useEffect(() => {
    loadSessions();
  }, []);

  const loadSessions = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const list = await workshopService.getSessions();
      setSessions(list);
      if (list.length > 0) {
        const initial = list.find(s => s.estado === 'EN_CURSO' || s.estado === 'EJECUTADA') || list[0];
        setSelectedSessionId(initial.id);
      }
    } catch (err: any) {
      setError(err?.message || 'Error al cargar las sesiones');
    } finally {
      setIsLoading(false);
    }
  };

  const syncQRAndMonitoreo = useCallback(async (sessionId: string) => {
    if (!sessionId) return;
    try {
      const [mon, qr] = await Promise.all([
        workshopService.getMonitoreo(sessionId).catch(() => null),
        workshopService.getActiveQR(sessionId).catch(() => null),
      ]);

      setMonitoreo(mon);
      if (qr && qr.qr_token) {
        setQrData(qr);
        setSecondsRemaining(qr.segundos_restantes);
      } else {
        setQrData(null);
        setSecondsRemaining(0);
      }
    } catch {
      setQrData(null);
      setSecondsRemaining(0);
    }
  }, []);

  // Sync session details when selected session changes
  useEffect(() => {
    if (!selectedSessionId) return;
    const session = sessions.find(s => s.id === selectedSessionId) || null;
    setActiveSession(session);
    syncQRAndMonitoreo(selectedSessionId);

    // Periodic monitoring poll every 10 seconds
    const interval = setInterval(() => {
      syncQRAndMonitoreo(selectedSessionId);
    }, 10000);

    return () => clearInterval(interval);
  }, [selectedSessionId, sessions, syncQRAndMonitoreo]);

  // Local seconds countdown synced to server expiration
  useEffect(() => {
    if (secondsRemaining <= 0) {
      if (timerRef.current) clearInterval(timerRef.current);
      return;
    }

    timerRef.current = setInterval(() => {
      setSecondsRemaining(prev => {
        if (prev <= 1) {
          // Re-sync with server when countdown reaches 0
          if (selectedSessionId) syncQRAndMonitoreo(selectedSessionId);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [secondsRemaining, selectedSessionId, syncQRAndMonitoreo]);

  // Handle generating/activating real QR token on server
  const handleGenerateQR = async () => {
    if (!selectedSessionId) return;
    setIsActionLoading(true);
    setError(null);
    try {
      const res = await workshopService.generateQR(selectedSessionId, 300);
      setQrData(res);
      setSecondsRemaining(res.segundos_restantes);
      await syncQRAndMonitoreo(selectedSessionId);
    } catch (err: any) {
      setError(err?.message || 'Error al emitir código QR en el servidor Go');
    } finally {
      setIsActionLoading(false);
    }
  };

  // Handle revoking QR on server
  const handleRevokeQR = async () => {
    if (!selectedSessionId) return;
    setIsActionLoading(true);
    setError(null);
    try {
      await workshopService.revokeQR(selectedSessionId);
      setQrData(null);
      setSecondsRemaining(0);
      await syncQRAndMonitoreo(selectedSessionId);
    } catch (err: any) {
      setError(err?.message || 'Error al revocar el código QR');
    } finally {
      setIsActionLoading(false);
    }
  };

  const handleFinishSession = async () => {
    if (!selectedSessionId) return;
    if (!window.confirm('¿Está seguro de concluir esta sesión operativa?')) return;
    setIsActionLoading(true);
    try {
      await workshopService.updateSessionStatus(selectedSessionId, 'FINALIZADA');
      await handleRevokeQR();
      await loadSessions();
    } catch (err: any) {
      setError(err?.message || 'Error al finalizar la sesión');
    } finally {
      setIsActionLoading(false);
    }
  };

  const formatTimer = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const s = secs % 60;
    return `${mins}:${s < 10 ? '0' : ''}${s}`;
  };

  const attendeesCount = monitoreo?.total_asistentes ?? (monitoreo?.asistencias?.length ?? 0);
  const enrolledCount = monitoreo?.total_inscritos ?? (activeSession?.totalInscritos ?? 0);

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Panel de Control del Capacitador</h1>
          <p className={styles.subtitle}>
            Generación y emisión de token QR dinámico para registro presencial con geocerca (80 m)
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button
            variant="outline"
            icon={<ClipboardList size={16} />}
            onClick={() => navigate('/trainer/attendances')}
          >
            Ver Asistencias ({attendeesCount})
          </Button>
        </div>
      </div>

      {error && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '12px 16px',
            backgroundColor: '#FEE2E2',
            border: '1px solid #FECACA',
            borderRadius: '8px',
            color: '#DC2626',
            fontSize: '13px',
          }}
        >
          <AlertCircle size={18} style={{ flexShrink: 0 }} />
          <span>{error}</span>
        </div>
      )}

      {/* Session selector if multiple exist */}
      {sessions.length > 1 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', background: '#FFFFFF', padding: '10px 14px', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#475569' }}>Seleccionar Sesión:</span>
          <select
            value={selectedSessionId}
            onChange={e => setSelectedSessionId(e.target.value)}
            style={{
              padding: '6px 12px',
              borderRadius: '6px',
              border: '1px solid #CBD5E1',
              fontSize: '13px',
              fontWeight: 500,
              flex: 1,
            }}
          >
            {sessions.map(s => (
              <option key={s.id} value={s.id}>
                {s.tallerNombre} — {s.sedeNombre} ({s.fecha})
              </option>
            ))}
          </select>
        </div>
      )}

      {activeSession ? (
        <div className={styles.contentGrid}>
          {/* Left Column: Session Information & Operational Controls */}
          <div className={styles.sessionDetails}>
            <Card
              header={
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span style={{ fontWeight: 600, fontSize: '15px' }}>Datos de la Sesión</span>
                  <Badge
                    variant={
                      qrData
                        ? 'warning'
                        : activeSession.estado === 'FINALIZADA' || activeSession.estado === 'VALIDADA'
                        ? 'success'
                        : 'primary'
                    }
                    withDot
                  >
                    {qrData ? 'EN EJECUCIÓN (QR ACTIVO)' : activeSession.estado}
                  </Badge>
                </div>
              }
            >
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div className={styles.detailRow}>
                  <BookOpen size={18} className={styles.detailIcon} />
                  <div className={styles.detailText}>
                    <span className={styles.detailTitle}>Taller Ambiental</span>
                    <span className={styles.detailValue}>{activeSession.tallerNombre}</span>
                  </div>
                </div>

                <div className={styles.detailRow}>
                  <MapPin size={18} className={styles.detailIcon} />
                  <div className={styles.detailText}>
                    <span className={styles.detailTitle}>Sede Georreferenciada</span>
                    <span className={styles.detailValue}>{activeSession.sedeNombre}</span>
                  </div>
                </div>

                <div className={styles.detailRow}>
                  <Clock size={18} className={styles.detailIcon} />
                  <div className={styles.detailText}>
                    <span className={styles.detailTitle}>Fecha y Horario</span>
                    <span className={styles.detailValue}>
                      {activeSession.fecha} • {activeSession.hora}
                    </span>
                  </div>
                </div>

                <div className={styles.statsRow}>
                  <div className={styles.statCard}>
                    <div className={styles.statNumber}>{attendeesCount}</div>
                    <div className={styles.statLabel}>Asistencias Confirmadas</div>
                  </div>
                  <div className={styles.statCard}>
                    <div className={styles.statNumber}>{enrolledCount}</div>
                    <div className={styles.statLabel}>Total Inscritos</div>
                  </div>
                </div>

                {/* Session operational controls */}
                <div style={{ display: 'flex', gap: '10px', marginTop: '12px' }}>
                  {qrData ? (
                    <>
                      <Button
                        variant="danger"
                        icon={isActionLoading ? <Loader2 size={16} className="animate-spin" /> : <Square size={16} />}
                        onClick={handleRevokeQR}
                        disabled={isActionLoading}
                        style={{ flex: 1 }}
                      >
                        Revocar Código QR
                      </Button>
                      <Button
                        variant="outline"
                        icon={<RotateCw size={15} />}
                        onClick={handleGenerateQR}
                        disabled={isActionLoading}
                        title="Rotar / Renovar token QR"
                      >
                        Rotar
                      </Button>
                    </>
                  ) : (
                    <Button
                      variant="primary"
                      icon={isActionLoading ? <Loader2 size={16} className="animate-spin" /> : <Play size={16} />}
                      onClick={handleGenerateQR}
                      disabled={isActionLoading}
                      style={{ flex: 1 }}
                    >
                      Generar Código QR en Servidor
                    </Button>
                  )}

                  <Button
                    variant="outline"
                    icon={<Square size={16} />}
                    onClick={handleFinishSession}
                    disabled={isActionLoading}
                  >
                    Cerrar Sesión
                  </Button>
                </div>
              </div>
            </Card>

            <div
              style={{
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0',
                borderRadius: '8px',
                padding: '14px',
                fontSize: '12px',
                color: '#64748B',
                display: 'flex',
                gap: '10px',
                alignItems: 'flex-start',
              }}
            >
              <AlertTriangle size={18} color="#D97706" style={{ flexShrink: 0, marginTop: '2px' }} />
              <div>
                <strong>Interoperabilidad con la App Flutter</strong>: El código QR renderizado a la derecha contiene el token JWT emitido por el backend Go (`POST /api/v1/sesiones/{'{id}'}/qr`). La aplicación Flutter verificará la firma criptográfica y enviará las coordenadas GPS para validar la geocerca de 80 metros.
              </div>
            </div>
          </div>

          {/* Right Column: Real Visual QR Code Render */}
          <div>
            <Card>
              <div className={styles.qrCard}>
                {qrData && secondsRemaining > 0 ? (
                  <>
                    <div className={styles.timerBadge}>
                      <Clock size={14} />
                      <span>Vigencia en Servidor: {formatTimer(secondsRemaining)}</span>
                    </div>

                    <div className={styles.qrContainer}>
                      {/* REAL QR Code render containing the backend JWT token */}
                      <QRCodeSVG
                        value={qrData.qr_token}
                        size={220}
                        level="M"
                        includeMargin={true}
                        fgColor="#176B53"
                        bgColor="#FFFFFF"
                      />
                    </div>

                    <div className={styles.qrTokenText}>
                      Token: {qrData.qr_token.slice(0, 24)}...{qrData.qr_token.slice(-12)}
                    </div>

                    <p style={{ fontSize: '11px', color: '#64748B', marginTop: '12px' }}>
                      Token dinámico firmado por Go con claim <code>token_use: qr_checkin</code>
                    </p>
                  </>
                ) : (
                  <div className={styles.qrInactive}>
                    <QrCode size={56} color="#CBD5E1" />
                    <div>
                      <div style={{ fontWeight: 600, color: '#1E293B' }}>
                        {qrData && secondsRemaining <= 0 ? 'Código QR Expirado' : 'Código QR No Generado'}
                      </div>
                      <p style={{ fontSize: '12px', color: '#64748B', marginTop: '4px' }}>
                        Haga clic en "Generar Código QR" para solicitar al backend Go un nuevo token dinámico de asistencia.
                      </p>
                    </div>
                    <Button
                      variant="primary"
                      icon={isActionLoading ? <Loader2 size={14} className="animate-spin" /> : <Play size={14} />}
                      onClick={handleGenerateQR}
                      disabled={isActionLoading}
                    >
                      {isActionLoading ? 'Generando...' : 'Generar Código QR'}
                    </Button>
                  </div>
                )}
              </div>
            </Card>
          </div>
        </div>
      ) : (
        <Card>
          <div style={{ textAlign: 'center', padding: '32px' }}>
            <p>{isLoading ? 'Cargando sesiones...' : 'No hay sesiones disponibles para este capacitador.'}</p>
          </div>
        </Card>
      )}
    </div>
  );
};
