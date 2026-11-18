import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Download,
  Search,
  CheckCircle2,
  QrCode,
  Edit3,
  Calendar,
  FileSpreadsheet,
  FileText,
  ShieldCheck,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { attendanceService } from '../../services/attendanceService';
import { AttendanceRecord, AttendanceStatus } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Card } from '../../components/ui/Card';
import { Modal } from '../../components/ui/Modal';
import styles from './GlobalAttendances.module.css';

export const GlobalAttendances: React.FC = () => {
  const [attendances, setAttendances] = useState<AttendanceRecord[]>([]);
  const [selectedRecord, setSelectedRecord] = useState<AttendanceRecord | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Export modal state
  const [isExportOpen, setIsExportOpen] = useState(false);
  const [exportFormat, setExportFormat] = useState<'csv' | 'pdf'>('csv');
  const [exportSuccess, setExportSuccess] = useState(false);

  const navigate = useNavigate();

  useEffect(() => {
    loadAttendances();
  }, []);

  const loadAttendances = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const list = await attendanceService.getAttendances();
      setAttendances(list);
      if (list.length > 0 && !selectedRecord) {
        setSelectedRecord(list[0]);
      }
    } catch (err: any) {
      setError(err?.message || 'Error al consultar las asistencias consolidadas');
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateStatus = async (record: AttendanceRecord, newStatus: AttendanceStatus) => {
    try {
      const updated = await attendanceService.updateAttendanceStatus(
        record.id,
        newStatus,
        'Actualización por coordinador',
        record.sesionId,
        record.participanteId
      );
      if (updated) {
        setSelectedRecord(updated);
      }
      await loadAttendances();
    } catch (err: any) {
      alert(err?.message || 'Error al actualizar el estado de asistencia');
    }
  };

  const handleExport = () => {
    const csvData = attendanceService.exportToCSV(filteredAttendances);
    const blob = new Blob([csvData], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `asistencias-educca-cusco-${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setExportSuccess(true);
  };

  const filteredAttendances = attendances.filter(a => {
    const matchesSearch =
      a.participanteNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.participanteDni.includes(searchTerm) ||
      a.tallerNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || a.estado === statusFilter;
    const matchesCategory = categoryFilter === 'ALL' || a.participanteCategoria === categoryFilter;
    return matchesSearch && matchesStatus && matchesCategory;
  });

  const totalPresent = attendances.filter(a => a.estado === 'PRESENTE').length;
  const totalPending = attendances.filter(a => a.estado === 'PENDIENTE').length;
  const totalExcused = attendances.filter(a => a.estado === 'JUSTIFICADO').length;

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
          <h1 className={styles.title}>Consulta Global de Asistencias</h1>
          <p className={styles.subtitle}>
            Seguimiento de concurrencia ciudadana, verificación de geocerca (80 m) y conciliación
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button
            variant="outline"
            icon={<Calendar size={16} />}
            onClick={() => navigate('/coordinator/sessions')}
          >
            Ver Sesiones
          </Button>
          <Button
            variant="primary"
            icon={<Download size={16} />}
            onClick={() => {
              setIsExportOpen(true);
              setExportSuccess(false);
            }}
          >
            Exportar Asistencias
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
          <Button size="sm" variant="outline" onClick={loadAttendances} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Brief operational summary metrics */}
      <div className={styles.summaryCards}>
        <div className={styles.summaryCard}>
          <span className={styles.summaryNumber} style={{ color: '#176B53' }}>
            {isLoading ? <Loader2 size={20} className="animate-spin" /> : attendances.length}
          </span>
          <span className={styles.summaryLabel}>Total Registros</span>
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
            {isLoading ? <Loader2 size={20} className="animate-spin" /> : totalExcused}
          </span>
          <span className={styles.summaryLabel}>Inasistencias Justificadas</span>
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

            <div style={{ minWidth: '150px' }}>
              <Select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                style={{ marginBottom: 0 }}
              >
                <option value="ALL">Todos los estados</option>
                <option value="PRESENTE">Presente</option>
                <option value="PENDIENTE">Pendiente</option>
                <option value="JUSTIFICADO">Justificado</option>
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
            headers={['DNI', 'Participante', 'Taller / Sede', 'Hora', 'Estado']}
            isEmpty={!isLoading && filteredAttendances.length === 0}
          >
            {filteredAttendances.map(record => {
              const isSelected = selectedRecord?.id === record.id;
              return (
                <tr
                  key={record.id}
                  onClick={() => setSelectedRecord(record)}
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
                      {record.participanteCategoria}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '13px', color: '#1E293B' }}>{record.tallerNombre}</div>
                    <div style={{ fontSize: '11px', color: '#64748B' }}>{record.sedeNombre}</div>
                  </td>
                  <td style={{ color: '#475569', fontSize: '12px' }}>{record.horaMarcado}</td>
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
                  <span className={styles.detailValue} style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
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
                    <span className={styles.detailValue} style={{ color: '#16A34A', fontWeight: 600 }}>
                      {selectedRecord.distanciaMetros} m (Geocerca: 80 m)
                    </span>
                  </div>
                )}
                <div className={styles.detailRow}>
                  <span className={styles.detailLabel}>Estado:</span>
                  <span className={styles.detailValue}>{getStatusBadge(selectedRecord.estado)}</span>
                </div>

                {selectedRecord.observaciones && (
                  <div style={{ marginTop: '8px', fontSize: '12px', color: '#64748B', fontStyle: 'italic' }}>
                    "{selectedRecord.observaciones}"
                  </div>
                )}

                {selectedRecord.validado && (
                  <div className={styles.geoAlert}>
                    <ShieldCheck size={16} />
                    <span>Conforme a validación de geocerca Haversine y LPDP</span>
                  </div>
                )}
              </div>

              {/* Status Change Buttons */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '16px' }}>
                <span style={{ fontSize: '11px', color: '#64748B', fontWeight: 600, textTransform: 'uppercase' }}>
                  Acción de Conciliación
                </span>
                <div style={{ display: 'flex', gap: '6px' }}>
                  <Button
                    size="sm"
                    variant={selectedRecord.estado === 'PRESENTE' ? 'secondary' : 'primary'}
                    onClick={() => handleUpdateStatus(selectedRecord, 'PRESENTE')}
                    style={{ flex: 1 }}
                  >
                    Confirmar Presente
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleUpdateStatus(selectedRecord, 'PENDIENTE')}
                    style={{ flex: 1 }}
                  >
                    Revertir
                  </Button>
                </div>
              </div>
            </Card>
          </div>
        ) : null}
      </div>

      {/* Export Dialog Modal */}
      <Modal
        isOpen={isExportOpen}
        onClose={() => setIsExportOpen(false)}
        title="Exportar Registro de Asistencias"
        footer={
          exportSuccess ? (
            <Button onClick={() => setIsExportOpen(false)}>Cerrar</Button>
          ) : (
            <>
              <Button variant="outline" onClick={() => setIsExportOpen(false)}>
                Cancelar
              </Button>
              <Button onClick={handleExport} icon={<Download size={14} />}>
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
              Se ha descargado el archivo CSV con {filteredAttendances.length} registros listos para auditoría municipal.
            </p>
          </div>
        ) : (
          <div>
            <p style={{ fontSize: '13px', color: '#64748B', marginBottom: '16px' }}>
              Seleccione el formato para exportar el consolidado de asistencias de los participantes del Programa EDUCCA Cusco.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px',
                  border: `1px solid ${exportFormat === 'csv' ? '#176B53' : '#E2E8F0'}`,
                  borderRadius: '8px',
                  backgroundColor: exportFormat === 'csv' ? '#F0F7F4' : '#FFFFFF',
                  cursor: 'pointer',
                }}
              >
                <input
                  type="radio"
                  name="format"
                  value="csv"
                  checked={exportFormat === 'csv'}
                  onChange={() => setExportFormat('csv')}
                />
                <FileSpreadsheet size={24} color="#176B53" />
                <div>
                  <div style={{ fontWeight: 600 }}>CSV (Valores separados por comas)</div>
                  <div style={{ fontSize: '11px', color: '#64748B' }}>
                    Compatible con Excel, hojas de cálculo y procesamiento estadístico municipal.
                  </div>
                </div>
              </label>

              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px',
                  border: `1px solid ${exportFormat === 'pdf' ? '#176B53' : '#E2E8F0'}`,
                  borderRadius: '8px',
                  backgroundColor: exportFormat === 'pdf' ? '#F0F7F4' : '#FFFFFF',
                  cursor: 'pointer',
                }}
              >
                <input
                  type="radio"
                  name="format"
                  value="pdf"
                  checked={exportFormat === 'pdf'}
                  onChange={() => setExportFormat('pdf')}
                />
                <FileText size={24} color="#D97706" />
                <div>
                  <div style={{ fontWeight: 600 }}>PDF Oficial (Formato de Actas)</div>
                  <div style={{ fontSize: '11px', color: '#64748B' }}>
                    Descargará en formato CSV estructurado para auditoría.
                  </div>
                </div>
              </label>
            </div>

            <div style={{ fontSize: '12px', color: '#64748B', background: '#F8FAFC', padding: '10px', borderRadius: '6px' }}>
              Se exportarán <strong>{filteredAttendances.length}</strong> registros correspondientes a los filtros actuales.
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
