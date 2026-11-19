import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  CalendarDays,
  Search,
  MapPin,
  Clock,
  Play,
  CheckCircle2,
  XCircle,
  ClipboardList,
  QrCode,
  AlertCircle,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { SessionItem, SessionStatus } from '../../models/types';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Modal } from '../../components/ui/Modal';
import styles from './SessionsList.module.css';

export const SessionsList: React.FC = () => {
  const [sessions, setSessions] = useState<SessionItem[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Confirm status transition modal
  const [pendingTransition, setPendingTransition] = useState<{
    session: SessionItem;
    newStatus: SessionStatus;
  } | null>(null);
  const [isUpdating, setIsUpdating] = useState(false);

  const [searchParams, setSearchParams] = useSearchParams();
  const focusedSesionId = searchParams.get('sesionId');

  const { isReadOnly } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    loadSessions();
  }, []);

  const loadSessions = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await workshopService.getSessions();
      setSessions(data);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al cargar las sesiones operativas');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateStatus = async (id: string, newStatus: SessionStatus) => {
    setIsUpdating(true);
    setError(null);
    try {
      await workshopService.updateSessionStatus(id, newStatus);
      setPendingTransition(null);
      await loadSessions();
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : 'Error al actualizar el estado de la sesión en el servidor'
      );
      setPendingTransition(null);
    } finally {
      setIsUpdating(false);
    }
  };

  const getStatusBadge = (estado: SessionStatus) => {
    switch (estado) {
      case 'EJECUTADA':
        return (
          <Badge variant="warning" withDot>
            En Curso / Ejecutada
          </Badge>
        );
      case 'PROGRAMADA':
        return (
          <Badge variant="primary" withDot>
            Programada
          </Badge>
        );
      case 'VALIDADA':
        return (
          <Badge variant="success" withDot>
            Validada
          </Badge>
        );
      case 'CANCELADA':
        return (
          <Badge variant="danger" withDot>
            Cancelada
          </Badge>
        );
      default:
        return <Badge variant="neutral">{estado}</Badge>;
    }
  };

  const filteredSessions = sessions.filter(s => {
    if (
      focusedSesionId &&
      s.id !== focusedSesionId &&
      s.tallerId !== focusedSesionId &&
      `ses-${s.id}` !== focusedSesionId &&
      `ws-${s.id}` !== focusedSesionId
    ) {
      return false;
    }
    const matchesSearch =
      s.tallerNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      s.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      s.capacitadorNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || s.estado === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Sesiones Operativas</h1>
          <p className={styles.subtitle}>
            Control de sesiones en campo, estados de ejecución, validación municipal y monitoreo
          </p>
        </div>
        {focusedSesionId && (
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              searchParams.delete('sesionId');
              setSearchParams(searchParams);
            }}
          >
            Mostrar todas las sesiones
          </Button>
        )}
      </div>

      {error && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '12px',
            backgroundColor: '#FEE2E2',
            color: '#DC2626',
            borderRadius: '6px',
            fontSize: '13px',
          }}
        >
          <AlertCircle size={18} />
          <span>{error}</span>
          <Button size="sm" variant="outline" onClick={loadSessions} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className={styles.filterBar}>
        <div className={styles.searchBox}>
          <Input
            placeholder="Buscar por sesión, sede o capacitador..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            icon={<Search size={16} />}
            style={{ marginBottom: 0 }}
          />
        </div>

        <div className={styles.filterSelect}>
          <Select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            style={{ marginBottom: 0 }}
          >
            <option value="ALL">Todos los estados</option>
            <option value="PROGRAMADA">Programada</option>
            <option value="EJECUTADA">En curso / Ejecutada</option>
            <option value="VALIDADA">Validada</option>
            <option value="CANCELADA">Cancelada</option>
          </Select>
        </div>
      </div>

      {/* Sessions Table */}
      <Table
        headers={[
          'Sesión / Taller',
          'Sede / Modalidad',
          'Fecha y Horario',
          'Capacitador',
          'Inscritos',
          'Estado',
          'Acciones',
        ]}
        isLoading={isLoading}
        isEmpty={!isLoading && filteredSessions.length === 0}
      >
        {filteredSessions.map(session => (
          <tr key={session.id}>
            <td>
              <div
                style={{
                  fontWeight: 600,
                  color: '#1E293B',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <CalendarDays size={16} color="#176B53" />
                {session.tallerNombre}
              </div>
              {session.qrActivo && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    marginTop: '2px',
                    color: '#16A34A',
                    fontSize: '11px',
                    fontWeight: 500,
                  }}
                >
                  <QrCode size={12} />
                  <span>Código QR activo</span>
                </div>
              )}
            </td>
            <td>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  color: '#475569',
                }}
              >
                <MapPin size={13} color="#0D9488" />
                {session.sedeNombre}
              </div>
              <div style={{ fontSize: '11px', color: '#64748B' }}>{session.modalidad}</div>
            </td>
            <td>
              <div style={{ color: '#1E293B', fontWeight: 500 }}>{session.fecha}</div>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  fontSize: '12px',
                  color: '#64748B',
                }}
              >
                <Clock size={11} />
                <span>{session.hora}</span>
              </div>
            </td>
            <td style={{ color: '#334155' }}>{session.capacitadorNombre}</td>
            <td>
              <span style={{ fontWeight: 600, color: '#176B53' }}>{session.totalInscritos}</span>{' '}
              inscritos
            </td>
            <td>{getStatusBadge(session.estado)}</td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                {!isReadOnly && session.estado === 'PROGRAMADA' && (
                  <>
                    <Button
                      size="sm"
                      variant="secondary"
                      icon={<Play size={12} />}
                      onClick={() => handleUpdateStatus(session.id, 'EJECUTADA')}
                      disabled={isUpdating}
                      title="Marcar sesión como En Curso / Ejecutada"
                    >
                      Iniciar
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      icon={<XCircle size={13} color="#DC2626" />}
                      onClick={() =>
                        setPendingTransition({ session, newStatus: 'CANCELADA' })
                      }
                      disabled={isUpdating}
                      title="Cancelar sesión"
                    />
                  </>
                )}

                {!isReadOnly && session.estado === 'EJECUTADA' && (
                  <>
                    <Button
                      size="sm"
                      variant="primary"
                      icon={<CheckCircle2 size={12} />}
                      onClick={() =>
                        setPendingTransition({ session, newStatus: 'VALIDADA' })
                      }
                      disabled={isUpdating}
                      title="Validar oficialmente la sesión ejecutada"
                    >
                      Validar
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      icon={<XCircle size={13} color="#DC2626" />}
                      onClick={() =>
                        setPendingTransition({ session, newStatus: 'CANCELADA' })
                      }
                      disabled={isUpdating}
                      title="Cancelar sesión"
                    />
                  </>
                )}

                {!isReadOnly &&
                  session.modalidad === 'PRESENCIAL' &&
                  (session.estado === 'PROGRAMADA' || session.estado === 'EJECUTADA') && (
                    <Button
                      size="sm"
                      variant="outline"
                      icon={<QrCode size={13} />}
                      onClick={() =>
                        navigate(`/trainer/qr?sesionId=${encodeURIComponent(session.id)}`)
                      }
                      title="Abrir Panel de Código QR de esta sesión"
                    >
                      QR
                    </Button>
                  )}

                <Button
                  size="sm"
                  variant="outline"
                  icon={<ClipboardList size={13} />}
                  onClick={() =>
                    navigate(
                      `/coordinator/attendances?sesionId=${encodeURIComponent(session.id)}`
                    )
                  }
                  title="Ver padrón de asistencias de esta sesión"
                >
                  Asistencias
                </Button>
              </div>
            </td>
          </tr>
        ))}
      </Table>

      {/* Confirm Validation or Cancellation Modal */}
      <Modal
        isOpen={Boolean(pendingTransition)}
        onClose={() => setPendingTransition(null)}
        title={
          pendingTransition?.newStatus === 'VALIDADA'
            ? 'Confirmar Validación Oficial de Sesión'
            : 'Confirmar Cancelación de Sesión'
        }
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setPendingTransition(null)}
              disabled={isUpdating}
            >
              Volver
            </Button>
            <Button
              type="button"
              variant={pendingTransition?.newStatus === 'VALIDADA' ? 'primary' : 'danger'}
              onClick={() =>
                pendingTransition &&
                handleUpdateStatus(pendingTransition.session.id, pendingTransition.newStatus)
              }
              disabled={isUpdating}
            >
              {isUpdating
                ? 'Actualizando...'
                : pendingTransition?.newStatus === 'VALIDADA'
                ? 'Confirmar Validación'
                : 'Cancelar Sesión'}
            </Button>
          </>
        }
      >
        <p style={{ fontSize: '13px', color: '#334155' }}>
          {pendingTransition?.newStatus === 'VALIDADA' ? (
            <>
              ¿Confirma la validación municipal de la sesión{' '}
              <strong>{pendingTransition.session.tallerNombre}</strong>? Una vez validada, el
              padrón de asistencias quedará cerrado para cómputo de metas MINAM.
            </>
          ) : (
            <>
              ¿Está seguro de cambiar la sesión{' '}
              <strong>{pendingTransition?.session.tallerNombre}</strong> a estado{' '}
              <strong>CANCELADA</strong>? Esta transición es definitiva.
            </>
          )}
        </p>
      </Modal>
    </div>
  );
};
