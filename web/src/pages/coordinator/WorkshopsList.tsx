import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  BookOpen,
  Plus,
  Search,
  Calendar,
  Clock,
  MapPin,
  User,
  ArrowRight,
  AlertCircle,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { Workshop } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import styles from './WorkshopsList.module.css';

export const WorkshopsList: React.FC = () => {
  const [workshops, setWorkshops] = useState<Workshop[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const navigate = useNavigate();

  useEffect(() => {
    loadWorkshops();
  }, []);

  const loadWorkshops = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await workshopService.getWorkshops();
      setWorkshops(data);
    } catch (err: any) {
      setError(err?.message || 'Error al cargar los talleres desde el backend');
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (estado: string) => {
    switch (estado) {
      case 'EN_CURSO':
      case 'EJECUTADA':
        return <Badge variant="warning" withDot>En Curso / Ejecutada</Badge>;
      case 'PROGRAMADO':
      case 'PROGRAMADA':
        return <Badge variant="primary" withDot>Programado</Badge>;
      case 'FINALIZADO':
      case 'VALIDADA':
        return <Badge variant="success" withDot>Validado</Badge>;
      case 'CANCELADO':
      case 'CANCELADA':
        return <Badge variant="danger" withDot>Cancelado</Badge>;
      default:
        return <Badge variant="neutral">{estado}</Badge>;
    }
  };

  const filteredWorkshops = workshops.filter(w => {
    const matchesSearch =
      w.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      w.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      w.capacitadorNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus =
      statusFilter === 'ALL' ||
      w.estado === (statusFilter as any) ||
      (statusFilter === 'EN_CURSO' && w.estado === 'EJECUTADA') ||
      (statusFilter === 'FINALIZADO' && w.estado === 'VALIDADA');
    return matchesSearch && matchesStatus;
  });

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Catálogo de Talleres</h1>
          <p className={styles.subtitle}>
            Programación y control de cursos de capacitación ambiental EDUCCA
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={() => navigate('/coordinator/workshops/create')}
        >
          Crear Taller
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
          <Button size="sm" variant="outline" onClick={loadWorkshops} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className={styles.filterBar}>
        <div className={styles.searchBox}>
          <Input
            placeholder="Buscar taller, sede o capacitador..."
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
            <option value="PROGRAMADO">Programado</option>
            <option value="EN_CURSO">En curso / Ejecutada</option>
            <option value="FINALIZADO">Validado</option>
            <option value="CANCELADO">Cancelado</option>
          </Select>
        </div>
      </div>

      {/* Workshops Table */}
      <Table
        headers={[
          'Taller y Eje Temático',
          'Sede',
          'Fecha / Horario',
          'Capacitador',
          'Inscritos / Cupos',
          'Estado',
          'Acción',
        ]}
        isEmpty={!isLoading && filteredWorkshops.length === 0}
      >
        {filteredWorkshops.map(workshop => (
          <tr key={workshop.id}>
            <td>
              <div style={{ fontWeight: 600, color: '#1E293B', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <BookOpen size={16} color="#176B53" />
                {workshop.nombre}
              </div>
              <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                {workshop.ejeTematico}
              </div>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#475569' }}>
                <MapPin size={13} color="#0D9488" />
                {workshop.sedeNombre}
              </div>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Calendar size={13} color="#64748B" />
                <span>{workshop.fecha}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: '#64748B' }}>
                <Clock size={12} />
                <span>
                  {workshop.horaInicio} - {workshop.horaFin}
                </span>
              </div>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#334155' }}>
                <User size={13} color="#64748B" />
                {workshop.capacitadorNombre}
              </div>
            </td>
            <td>
              <span style={{ fontWeight: 600, color: '#176B53' }}>{workshop.inscritos}</span>
              <span style={{ color: '#94A3B8' }}> / {workshop.cuposTotales}</span>
            </td>
            <td>{getStatusBadge(workshop.estado)}</td>
            <td>
              <Button
                size="sm"
                variant="outline"
                icon={<ArrowRight size={13} />}
                onClick={() => navigate('/coordinator/sessions')}
              >
                Ver Sesión
              </Button>
            </td>
          </tr>
        ))}
      </Table>
    </div>
  );
};
