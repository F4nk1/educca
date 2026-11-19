import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Download,
  Search,
  CheckCircle2,
  QrCode,
  Edit3,
  Calendar,
  FileSpreadsheet,
  Printer,
  ShieldCheck,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { attendanceService } from '../../services/attendanceService';
import { workshopService } from '../../services/workshopService';
import {
  AttendanceRecord,
  AttendanceStatus,
  AttendanceParticipation,
  SessionItem,
} from '../../models/types';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Card } from '../../components/ui/Card';
import { Modal } from '../../components/ui/Modal';
import styles from './GlobalAttendances.module.css';

export const GlobalAttendances: React.FC = () => {
  const [attendances, setAttendances] = useState<AttendanceRecord[]>([]);
  const [sessions, setSessions] = useState<SessionItem[]>([]);
  const [selectedRecordId, setSelectedRecordId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [sessionFilter, setSessionFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Selected record editable fields
  const [editParticipacion, setEditParticipacion] =
    useState<AttendanceParticipation>('ASISTENTE');
  const [editCalificacion, setEditCalificacion] = useState<string>('');

  // Export modal state
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [exportSuccess, setExportSuccess] = useState(false);

  const [searchParams, setSearchParams] = useSearchParams();
  const urlSesionId = searchParams.get('sesionId');

  const { isReadOnly } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (urlSesionId) {
      setSessionFilter(urlSesionId.replace('ses-', '').replace('ws-', ''));
    }
  }, [urlSesionId]);

  useEffect(() => {
    loadAttendances();
  }, []);

  const loadAttendances = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [list, loadedSessions] = await Promise.all([
        attendanceService.getAttendances(),
        workshopService.getSessions().catch(() => [] as SessionItem[]),
      ]);
      setAttendances(list);
      setSessions(loadedSessions);
      if (list.length > 0 && !selectedRecordId) {
        setSelectedRecordId(list[0].id);
      }
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Error al consultar las asistencias consolidadas'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const filteredAttendances = attendances.filter(a => {
    const cleanSesionId = a.sesionId.replace('ses-', '').replace('ws-', '');
    const cleanFilterId = sessionFilter.replace('ses-', '').replace('ws-', '');
    const matchesSession = sessionFilter === 'ALL' || cleanSesionId === cleanFilterId;

    const matchesSearch =
      a.participanteNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.participanteDni.includes(searchTerm) ||
      a.tallerNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || a.estado === statusFilter;
    const matchesCategory =
      categoryFilter === 'ALL' || a.participanteCategoria === categoryFilter;
    return matchesSession && matchesSearch && matchesStatus && matchesCategory;
  });

  const selectedRecord =
    filteredAttendances.find(r => r.id === selectedRecordId) ||
    filteredAttendances[0] ||
    null;

  useEffect(() => {
    if (selectedRecord) {
      setEditParticipacion(selectedRecord.participacion || 'ASISTENTE');
      setEditCalificacion(
        selectedRecord.calificacion !== undefined ? selectedRecord.calificacion.toString() : ''
      );
    }
  }, [selectedRecord?.id]);

  const handleUpdateStatus = async (record: AttendanceRecord, newStatus: AttendanceStatus) => {
    setIsUpdating(true);
    setError(null);
    try {
      const calNum = editCalificacion.trim() !== '' ? parseFloat(editCalificacion) : undefined;
      if (calNum !== undefined && (isNaN(calNum) || calNum < 0 || calNum > 20)) {
        setError('La calificación debe estar entre 0 y 20');
        setIsUpdating(false);
        return;
      }

      const updated = await attendanceService.updateAttendanceStatus(
        record.id,
        newStatus,
        'Actualización por coordinador',
        record.sesionId,
        record.participanteId,
        {
          participacion: editParticipacion,
          calificacion: calNum,
        }
      );
      await loadAttendances();
      if (updated) {
        setSelectedRecordId(updated.id);
      }
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Error al actualizar el estado de asistencia'
      );
    } finally {
      setIsUpdating(false);
    }
  };

  const handleExportCSV = () => {
    const csvData = attendanceService.exportToCSV(filteredAttendances);
    const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute(
      'download',
      `asistencias-educca-cusco-${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
    setExportSuccess(true);
  };

  const totalPresent = filteredAttendances.filter(a => a.estado === 'PRESENTE').length;
  const totalPending = filteredAttendances.filter(a => a.estado === 'PENDIENTE').length;
  const totalQRVerified = filteredAttendances.filter(
    a => a.estado === 'PRESENTE' && a.metodo === 'QR_GPS'
  ).length;

  const getStatusBadge = (estado: AttendanceStatus) => {
    switch (estado) {
      case 'PRESENTE':
        return (
          <Badge variant="success" withDot>
            Presente
          </Badge>
        );
      case 'PENDIENTE':
        return (
          <Badge variant="warning" withDot>
            Pendiente
          </Badge>
        );
      default:
        return <Badge variant="neutral">{estado}</Badge>;
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Consulta Global de Asistencias</h1>
          <p className={styles.subtitle}>
            Seguimiento de concurrencia ciudadana, verificación de geocerca (80 m) y conciliación
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <Button
            variant="outline"
            icon={<Calendar size={16} />}
            onClick={() => navigate('/coordinator/sessions')}
          >
            Ver Sesiones
          </Button>
          <Button
            variant="outline"
            icon={<Printer size={16} />}
            onClick={() => window.print()}
          >
            Imprimir Acta
          </Button>
          <Button
            variant="primary"
            icon={<Download size={16} />}
            onClick={() => {
              setIsExportOpen(true);
              setExportSuccess(false);
            }}
          >
            Exportar CSV
          </Button>
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
          <Button
            size="sm"
            variant="outline"
            onClick={loadAttendances}
            style={{ marginLeft: 'auto' }}
          >
            Reintentar
          </Button>
        </div>
      )}

      {/* Brief operational summary metrics */}
      <div className={styles.summaryCards}>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#176B53' }}>
            {isLoading ? (
              <Loader2 size={20} className="animate-spin" />
            ) : (
              filteredAttendances.length
            )}
          </span>
          <span className={styles.summaryLabel}>Total Registros (Filtro)</span>
        </div>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#16A34A' }}>
            {isLoading ? <Loader2 size={20} className="animate-spin" /> : totalPresent}
          </span>
          <span className={styles.summaryLabel}>Asistencias Confirmadas</span>
        </div>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#D97706' }}>
            {isLoading ? <Loader2 size={20} className="animate-spin" /> : totalPending}
          </span>
          <span className={styles.summaryLabel}>Inscritos Pendientes</span>
        </div>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#0284C7' }}>
            {isLoading ? <Loader2 size={20} className="animate-spin" /> : totalQRVerified}
          </span>
          <span className={styles.summaryLabel}>Verificados con QR + GPS</span>
        </div>
      </div>

      <div className={styles.mainLayout}>
        {/* Left Column: Filter and Main Attendances Table */}
        <div>
          <div className={styles.filterBar}>
            <div className={styles.searchBox}>
              <Input
                placeholder="Buscar por DNI, participante, taller o sede..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                icon={<Search size={16} />}
                style={{ marginBottom: 0 }}
              />
            </div>

            <div style={{ minWidth: '170px' }}>
              <Select
                value={sessionFilter}
                onChange={e => {
                  const val = e.target.value;
                  setSessionFilter(val);
                  if (val === 'ALL') {
                    searchParams.delete('sesionId');
                  } else {
                    searchParams.set('sesionId', val);
                  }
                  setSearchParams(searchParams);
                }}
                style={{ marginBottom: 0 }}
              >
                <option value="ALL">Todas las sesiones</option>
                {sessions.map(s => {
                  const cleanId = s.id.replace('ses-', '');
                  return (
                    <option key={s.id} value={cleanId}>
                      {s.tallerNombre} ({s.fecha})
                    </option>
                  );
                })}
              </Select>
            </div>

            <div style={{ minWidth: '140px' }}>
              <Select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                style={{ marginBottom: 0 }}
              >
                <option value="ALL">Todos los estados</option>
                <option value="PRESENTE">Presente</option>
                <option value="PENDIENTE">Pendiente</option>
              </Select>
            </div>

            <div style={{ minWidth: '150px' }}>
              <Select
                value={categoryFilter}
                onChange={e => setCategoryFilter(e.target.value)}
                style={{ marginBottom: 0 }}
              >
                <option value="ALL">Todas las categorías</option>
                <option value="PAJ">PAJ (Juvenil)</option>
                <option value="PAC">PAC (Comunitario)</option>
                <option value="COMERCIANTE">Comerciante</option>
                <option value="RECICLADOR">Reciclador</option>
              </Select>
            </div>
          </div>

          <Table
            headers={['DNI', 'Participante', 'Taller / Sede', 'Hora / Nota', 'Estado']}
            isLoading={isLoading}
            isEmpty={!isLoading && filteredAttendances.length === 0}
          >
            {filteredAttendances.map(record => {
              const isSelected = selectedRecord?.id === record.id;
              return (
                <tr
                  key={record.id}
                  tabIndex={0}
                  aria-selected={isSelected}
                  onClick={() => setSelectedRecordId(record.id)}
                  onKeyDown={e => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      setSelectedRecordId(record.id);
                    }
                  }}
                  style={{
                    cursor: 'pointer',
                    backgroundColor: isSelected ? '#F0F7F4' : undefined,
                  }}
                >
                  <td style={{ fontFamily: 'monospace', fontWeight: 500 }}>
                    {record.participanteDni}
                  </td>
                  <td>
                    <div style={{ fontWeight: 600, color: '#1E293B' }}>
                      {record.participanteNombre}
                    </div>
                    <div style={{ fontSize: '11px', color: '#64748B' }}>
                      {record.participanteCategoria} • {record.participacion}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '13px', color: '#1E293B' }}>{record.tallerNombre}</div>
                    <div style={{ fontSize: '11px', color: '#64748B' }}>{record.sedeNombre}</div>
                  </td>
                  <td style={{ color: '#475569', fontSize: '12px' }}>
                    <div>{record.horaMarcado}</div>
                    {record.calificacion !== undefined && (
                      <div style={{ fontSize: '11px', color: '#176B53', fontWeight: 600 }}>
                        Nota: {record.calificacion}/20
                      </div>
                    )}
                  </td>
                  <td>{getStatusBadge(record.estado)}</td>
                </tr>
              );
            })}
          </Table>
        </div>

        {/* Right Column: Contextual Inspection Panel for Selected Record */}
        {selectedRecord ? (
          <div className={styles.detailPanel}>
            <Card header={<span style={{ fontWeight: 600 }}>Detalle de Asistencia</span>}>
              <div className={styles.detailSection}>
                <div className={styles.detailTitle}>Participante</div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Nombres:</span>
                  <span className={styles.detailValue}>{selectedRecord.participanteNombre}</span>
                </div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>DNI:</span>
                  <span className={styles.detailValue} style={{ fontFamily: 'monospace' }}>
                    {selectedRecord.participanteDni}
                  </span>
                </div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Categoría:</span>
                  <span className={styles.detailValue}>
                    <Badge variant="primary">{selectedRecord.participanteCategoria}</Badge>
                  </span>
                </div>
              </div>

              <div className={styles.detailSection}>
                <div className={styles.detailTitle}>Sesión y Sede</div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Taller:</span>
                  <span className={styles.detailValue}>{selectedRecord.tallerNombre}</span>
                </div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Sede:</span>
                  <span className={styles.detailValue}>{selectedRecord.sedeNombre}</span>
                </div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Fecha:</span>
                  <span className={styles.detailValue}>{selectedRecord.fecha}</span>
                </div>
              </div>

              <div className={styles.detailSection}>
                <div className={styles.detailTitle}>Verificación de Marcado</div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Hora:</span>
                  <span className={styles.detailValue}>{selectedRecord.horaMarcado}</span>
                </div>
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Método:</span>
                  <span
                    className={styles.detailValue}
                    style={{ display: 'flex', alignItems: 'center', gap: '4px' }}
                  >
                    {selectedRecord.metodo === 'QR_GPS' ? (
                      <>
                        <QrCode size={13} color="#176B53" /> QR Dinámico + GPS
                      </>
                    ) : (
                      <>
                        <Edit3 size={13} color="#D97706" /> Registro Manual
                      </>
                    )}
                  </span>
                </div>
                {selectedRecord.distanciaMetros !== undefined && (
                  <div className={styles.detailRow}>
                    <span className={styles.detailLabel}>Distancia Sede:</span>
                    <span
                      className={styles.detailValue}
                      style={{ color: '#16A34A', fontWeight: 600 }}
                    >
                      {selectedRecord.distanciaMetros} m (Geocerca: 80 m)
                    </span>
                  </div>
                )}
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Estado:</span>
                  <span className={styles.detailValue}>
                    {getStatusBadge(selectedRecord.estado)}
                  </span>
                </div>

                {selectedRecord.observaciones && (
                  <div
                    style={{
                      marginTop: '8px',
                      fontSize: '12px',
                      color: '#64748B',
                      fontStyle: 'italic',
                    }}
                  >
                    &ldquo;{selectedRecord.observaciones}&rdquo;
                  </div>
                )}

                {selectedRecord.validado && (
                  <div className={styles.geoAlert}>
                    <ShieldCheck size={16} />
                    <span>Conforme a validación de geocerca Haversine y LPDP</span>
                  </div>
                )}
              </div>

              {/* Conciliation & Evaluation Controls */}
              {!isReadOnly && (
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '10px',
                    marginTop: '16px',
                  }}
                >
                  <span
                    style={{
                      fontSize: '11px',
                      color: '#64748B',
                      fontWeight: 600,
                      textTransform: 'uppercase',
                    }}
                  >
                    Conciliación y Calificación
                  </span>

                  <Select
                    label="Tipo de participación"
                    value={editParticipacion}
                    onChange={e =>
                      setEditParticipacion(e.target.value as AttendanceParticipation)
                    }
                  >
                    <option value="ASISTENTE">ASISTENTE</option>
                    <option value="VOLUNTARIO_REPLICA">VOLUNTARIO_REPLICA</option>
                    <option value="PONENTE">PONENTE</option>
                  </Select>

                  <Input
                    label="Calificación (0 a 20, opcional)"
                    type="number"
                    min="0"
                    max="20"
                    step="0.5"
                    value={editCalificacion}
                    onChange={e => setEditCalificacion(e.target.value)}
                    placeholder="Ej. 18"
                  />

                  <div style={{ display: 'flex', gap: '6px' }}>
                    <Button
                      size="sm"
                      variant="primary"
                      disabled={isUpdating}
                      onClick={() => handleUpdateStatus(selectedRecord, 'PRESENTE')}
                      style={{ flex: 1 }}
                    >
                      {selectedRecord.estado === 'PRESENTE'
                        ? 'Guardar Nota / Rol'
                        : 'Confirmar Presente'}
                    </Button>
                    {selectedRecord.estado === 'PRESENTE' && (
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={isUpdating}
                        onClick={() => handleUpdateStatus(selectedRecord, 'PENDIENTE')}
                      >
                        Revertir
                      </Button>
                    )}
                  </div>
                </div>
              )}
            </Card>
          </div>
        ) : null}
      </div>

      {/* Export Dialog Modal */}
      <Modal
        isOpen={isExportOpen}
        onClose={() => setIsExportOpen(false)}
        title="Exportar Padrón de Asistencias (CSV)"
        footer={
          exportSuccess ? (
            <Button onClick={() => setIsExportOpen(false)}>Cerrar</Button>
          ) : (
            <>
              <Button variant="outline" onClick={() => setIsExportOpen(false)}>
                Cancelar
              </Button>
              <Button onClick={handleExportCSV} icon={<Download size={14} />}>
                Generar y Descargar CSV
              </Button>
            </>
          )
        }
      >
        {exportSuccess ? (
          <div style={{ textAlign: 'center', padding: '16px 0' }}>
            <CheckCircle2 size={48} color="#16A34A" style={{ margin: '0 auto 12px' }} />
            <h4 style={{ marginBottom: '8px' }}>Archivo Exportado con Éxito</h4>
            <p style={{ color: '#64748B', fontSize: '13px' }}>
              Se ha descargado el archivo CSV con {filteredAttendances.length} registros listos
              para auditoría municipal.
            </p>
          </div>
        ) : (
          <div>
            <p style={{ fontSize: '13px', color: '#64748B', marginBottom: '16px' }}>
              Se generará el archivo CSV oficial con sanitización de fórmulas para Excel y hojas de
              cálculo municipales.
            </p>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '12px',
                border: '1px solid #176B53',
                borderRadius: '8px',
                backgroundColor: '#F0F7F4',
                marginBottom: '16px',
              }}
            >
              <FileSpreadsheet size={24} color="#176B53" />
              <div>
                <div style={{ fontWeight: 600 }}>CSV (Valores separados por comas)</div>
                <div style={{ fontSize: '11px', color: '#64748B' }}>
                  Incluye DNI, participante, categoría, participación, calificación, método QR/GPS,
                  distancia en metros y fecha/hora.
                </div>
              </div>
            </div>

            <div
              style={{
                fontSize: '12px',
                color: '#64748B',
                background: '#F8FAFC',
                padding: '10px',
                borderRadius: '6px',
              }}
            >
              Se exportarán <strong>{filteredAttendances.length}</strong> registros
              correspondientes a los filtros actuales.
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
