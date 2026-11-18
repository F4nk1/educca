import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  CalendarDays,
  Search,
  MapPin,
  Clock,
  Play,
  Square,
  ClipboardList,
  QrCode,
  AlertCircle,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { SessionItem, SessionStatus } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import styles from './SessionsList.module.css';

export const SessionsList: React.FC = () => {
  const [sessions, setSessions] = useState<SessionItem[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
    } catch (err: any) {
      setError(err?.message || 'Error al cargar las sesiones operativas');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateStatus = async (id: string, newStatus: SessionStatus) => {
    try {
      await workshopService.updateSessionStatus(id, newStatus);
      await loadSessions();
    } catch (err: any) {
      alert(err?.message || 'Error al actualizar el estado de la sesión en el servidor');
    }
  };

  const getStatusBadge = (estado: SessionStatus) => {
    switch (estado) {
      case 'EN_CURSO':
      case 'EJECUTADA':
        return <Badge variant="warning" withDot>En Curso / Ejecutada</Badge>;
      case 'PROGRAMADA':
        return <Badge variant="primary" withDot>Programada</Badge>;
      case 'FINALIZADA':
      case 'VALIDADA':
        return <Badge variant="success" withDot>Validada</Badge>;
      case 'CANCELADA':
        return <Badge variant="danger" withDot>Cancelada</Badge>;
      default:
        return <Badge variant="neutral">{estado}</Badge>;
    }
  };

  const filteredSessions = sessions.filter(s => {
    const matchesSearch =
      s.tallerNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      s.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      s.capacitadorNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus =
      statusFilter === 'ALL' ||
      s.estado === statusFilter ||
      (statusFilter === 'EN_CURSO' && s.estado === 'EJECUTADA') ||
      (statusFilter === 'FINALIZADA' && s.estado === 'VALIDADA');
    return matchesSearch && matchesStatus;
  });

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Sesiones Operativas</h1>
          <p className={styles.subtitle}>
            Control de sesiones en campo, estados de apertura y monitoreo de asistencias
          </p>
        </div>
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
            <option value="EN_CURSO">En curso / Ejecutada</option>
            <option value="FINALIZADA">Validada</option>
            <option value="CANCELADA">Cancelada</option>
          </Select>
        </div>
      </div>

      {/* Sessions Table */}
      <Table
        headers={[
          'Sesión / Taller',
          'Sede',
          'Fecha y Horario',
          'Capacitador',
          'Inscritos',
          'Estado',
          'Acciones',
        ]}
        isEmpty={!isLoading && filteredSessions.length === 0}
      >
        {filteredSessions.map(session => (
          <tr key={session.id}>
            <td>
              <div style={{ fontWeight: 600, color: '#1E293B', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <CalendarDays size={16} color="#176B53" />
                {session.tallerNombre}
              </div>
              {session.qrActivo && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px', color: '#16A34A', fontSize: '11px', fontWeight: 500 }}>
                  <QrCode size={12} />
                  <span>Código QR activo</span>
                </div>
              )}
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#475569' }}>
                <MapPin size={13} color="#0D9488" />
                {session.sedeNombre}
              </div>
            </td>
            <td>
              <div style={{ color: '#1E293B', fontWeight: 500 }}>{session.fecha}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: '#64748B' }}>
                <Clock size={11} />
                <span>{session.hora}</span>
              </div>
            </td>
            <td style={{ color: '#334155' }}>{session.capacitadorNombre}</td>
            <td>
              <span style={{ fontWeight: 600, color: '#176B53' }}>{session.totalInscritos}</span> cupos
            </td>
            <td>{getStatusBadge(session.estado)}</td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                {session.estado === 'PROGRAMADA' && (
                  <Button
                    size="sm"
                    variant="secondary"
                    icon={<Play size={12} />}
                    onClick={() => handleUpdateStatus(session.id, 'EN_CURSO')}
                  >
                    Iniciar
                  </Button>
                )}

                {(session.estado === 'EN_CURSO' || session.estado === 'EJECUTADA') && (
                  <Button
                    size="sm"
                    variant="outline"
                    icon={<Square size={12} />}
                    onClick={() => handleUpdateStatus(session.id, 'FINALIZADA')}
                  >
                    Validar
                  </Button>
                )}

                <Button
                  size="sm"
                  variant="outline"
                  icon={<ClipboardList size={13} />}
                  onClick={() => navigate('/coordinator/attendances')}
                  title="Ver registro de asistencias"
                >
                  Asistencias
                </Button>
              </div>
            </td>
          </tr>
        ))}
      </Table>
    </div>
  );
};
