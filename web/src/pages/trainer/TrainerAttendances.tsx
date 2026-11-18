import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  QrCode,
  Search,
  Clock,
  UserCheck,
  Edit3,
  MapPin,
  BookOpen,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { attendanceService } from '../../services/attendanceService';
import { workshopService } from '../../services/workshopService';
import { AttendanceRecord, AttendanceStatus, SessionItem } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Card } from '../../components/ui/Card';
import styles from './TrainerAttendances.module.css';

export const TrainerAttendances: React.FC = () => {
  const [sessions, setSessions] = useState<SessionItem[]>([]);
  const [selectedSessionId, setSelectedSessionId] = useState<string>('');
  const [activeSession, setActiveSession] = useState<SessionItem | null>(null);
  const [attendances, setAttendances] = useState<AttendanceRecord[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [isActionLoading, setIsActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const navigate = useNavigate();

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
        setActiveSession(initial);
      }
    } catch (err: any) {
      setError(err?.message || 'Error al cargar sesiones');
    } finally {
      setIsLoading(false);
    }
  };

  const loadAttendances = useCallback(async (sesionId: string) => {
    if (!sesionId) return;
    setIsLoading(true);
    setError(null);
    try {
      const list = await attendanceService.getAttendancesBySession(sesionId);
      setAttendances(list);
    } catch (err: any) {
      setError(err?.message || 'Error al cargar asistencias');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (selectedSessionId) {
      const found = sessions.find(s => s.id === selectedSessionId) || null;
      setActiveSession(found);
      loadAttendances(selectedSessionId);
    }
  }, [selectedSessionId, sessions, loadAttendances]);

  const handleUpdateStatus = async (record: AttendanceRecord, newStatus: AttendanceStatus) => {
    setIsActionLoading(true);
    try {
      await attendanceService.updateAttendanceStatus(
        record.id,
        newStatus,
        'Marcado manual asistido por capacitador',
        record.sesionId,
        record.participanteId
      );
      await loadAttendances(selectedSessionId);
    } catch (err: any) {
      alert(err?.message || 'Error al registrar asistencia manual');
    } finally {
      setIsActionLoading(false);
    }
  };

  const filtered = attendances.filter(a => {
    const matchesSearch =
      a.participanteNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.participanteDni.includes(searchTerm);
    const matchesStatus = statusFilter === 'ALL' || a.estado === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const totalPresent = attendances.filter(a => a.estado === 'PRESENTE').length;
  const totalPending = attendances.filter(a => a.estado === 'PENDIENTE').length;

  const getStatusBadge = (estado: AttendanceStatus) => {
    switch (estado) {
      case 'PRESENTE':
        return <Badge variant="success" withDot>Presente</Badge>;
      case 'PENDIENTE':
        return <Badge variant="warning" withDot>Pendiente</Badge>;
      case 'JUSTIFICADO':
        return <Badge variant="info" withDot>Justificado</Badge>;
      default:
        return <Badge variant="neutral">{estado}</Badge>;
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Lista de Asistencia — Sesión en Campo</h1>
          <p className={styles.subtitle}>
            Verificación presencial de participantes inscritos y registro manual asistido
          </p>
        </div>
        <Button
          variant="primary"
          icon={<QrCode size={16} />}
          onClick={() => navigate('/trainer/qr')}
        >
          Ver Panel QR
        </Button>
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
        </div>
      )}

      {/* Session selector */}
      {sessions.length > 1 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', background: '#FFFFFF', padding: '10px 14px', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#475569' }}>Sesión activa:</span>
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
                {s.tallerNombre} — {s.sedeNombre}
              </option>
            ))}
          </select>
        </div>
      )}

      {activeSession && (
        <Card padding="sm">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 600, color: '#1E293B' }}>
                <BookOpen size={16} color="#176B53" />
                <span>{activeSession.tallerNombre}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#64748B', fontSize: '13px' }}>
                <MapPin size={14} color="#0D9488" />
                <span>{activeSession.sedeNombre}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#64748B', fontSize: '13px' }}>
                <Clock size={14} />
                <span>{activeSession.fecha} • {activeSession.hora}</span>
              </div>
            </div>
            <Badge variant="primary" withDot>
              {activeSession.estado}
            </Badge>
          </div>
        </Card>
      )}

      {/* Summary Cards */}
      <div className={styles.summaryCards}>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#176B53' }}>
            {attendances.length}
          </span>
          <span className={styles.summaryLabel}>Total Inscritos</span>
        </div>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#16A34A' }}>
            {totalPresent}
          </span>
          <span className={styles.summaryLabel}>Asistencias Confirmadas</span>
        </div>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#D97706' }}>
            {totalPending}
          </span>
          <span className={styles.summaryLabel}>Pendientes de Ingreso</span>
        </div>
      </div>

      {/* Search and Filters */}
      <div className={styles.filterBar}>
        <div className={styles.searchBox}>
          <Input
            placeholder="Buscar por DNI o nombres..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            icon={<Search size={16} />}
            style={{ marginBottom: 0 }}
          />
        </div>

        <div style={{ minWidth: '160px' }}>
          <Select
            value={statusFilter}
            onChange={e => setStatusFilter(e.target.value)}
            style={{ marginBottom: 0 }}
          >
            <option value="ALL">Todos los estados</option>
            <option value="PRESENTE">Presentes</option>
            <option value="PENDIENTE">Pendientes</option>
          </Select>
        </div>
      </div>

      {/* Attendances Table */}
      <Table
        headers={[
          'DNI',
          'Participante',
          'Categoría',
          'Hora Marcado',
          'Método',
          'Estado',
          'Acción Manual',
        ]}
        isEmpty={!isLoading && filtered.length === 0}
      >
        {filtered.map(record => (
          <tr key={record.id}>
            <td style={{ fontFamily: 'monospace', fontWeight: 600 }}>{record.participanteDni}</td>
            <td>
              <div style={{ fontWeight: 600, color: '#1E293B' }}>{record.participanteNombre}</div>
            </td>
            <td>
              <Badge variant="primary">{record.participanteCategoria}</Badge>
            </td>
            <td style={{ color: '#475569', fontSize: '13px' }}>{record.horaMarcado}</td>
            <td>
              <span style={{ fontSize: '12px', display: 'flex', alignItems: 'center', gap: '4px', color: '#475569' }}>
                {record.metodo === 'QR_GPS' ? (
                  <>
                    <QrCode size={13} color="#176B53" /> QR + GPS {record.distanciaMetros ? `(${record.distanciaMetros}m)` : ''}
                  </>
                ) : (
                  <>
                    <Edit3 size={13} color="#D97706" /> Manual
                  </>
                )}
              </span>
            </td>
            <td>{getStatusBadge(record.estado)}</td>
            <td>
              {record.estado === 'PENDIENTE' ? (
                <Button
                  size="sm"
                  variant="primary"
                  icon={isActionLoading ? <Loader2 size={13} className="animate-spin" /> : <UserCheck size={13} />}
                  onClick={() => handleUpdateStatus(record, 'PRESENTE')}
                  disabled={isActionLoading}
                >
                  Marcar Presente
                </Button>
              ) : (
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => handleUpdateStatus(record, 'PENDIENTE')}
                  disabled={isActionLoading}
                  title="Revertir asistencia"
                >
                  Revertir
                </Button>
              )}
            </td>
          </tr>
        ))}
      </Table>
    </div>
  );
};
