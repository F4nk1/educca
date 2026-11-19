import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin,
  BookOpen,
  CalendarDays,
  Users,
  Plus,
  ArrowRight,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { venueService } from '../../services/venueService';
import { userService } from '../../services/userService';
import { Workshop } from '../../models/types';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Card } from '../../components/ui/Card';
import styles from './CoordinatorHome.module.css';

export const CoordinatorHome: React.FC = () => {
  const [workshops, setWorkshops] = useState<Workshop[]>([]);
  const [venuesCount, setVenuesCount] = useState(0);
  const [usersCount, setUsersCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { isReadOnly } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [loadedWorkshops, loadedVenues, loadedUsers] = await Promise.all([
        workshopService.getWorkshops(),
        venueService.getVenues(),
        userService.getUsers().catch(() => []),
      ]);

      setWorkshops(loadedWorkshops);
      setVenuesCount(loadedVenues.length);
      setUsersCount(loadedUsers.length);
    } catch (err: unknown) {
      const msg =
        err instanceof Error ? err.message : 'Error al conectar con los servicios del backend';
      setError(msg);
    } finally {
      setIsLoading(false);
    }
  };

  const activeWorkshops = workshops.filter(
    w => w.estado === 'PROGRAMADA' || w.estado === 'EJECUTADA'
  );

  const getStatusBadge = (estado: string) => {
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

  return (
    <div className={styles.pageContainer}>
      {/* Welcome & Quick Action Header */}
      <div className={styles.welcomeHeader}>
        <div>
          <h1 className={styles.title}>Panel del Coordinador</h1>
          <p className={styles.subtitle}>
            Resumen operativo y seguimiento del Programa EDUCCA Cusco
          </p>
        </div>
        <div className={styles.quickActions}>
          <Button
            variant="outline"
            icon={<MapPin size={16} />}
            onClick={() => navigate('/coordinator/venues')}
          >
            Ver Sedes
          </Button>
          {!isReadOnly && (
            <Button
              variant="primary"
              icon={<Plus size={16} />}
              onClick={() => navigate('/coordinator/workshops/create')}
            >
              Programar Taller
            </Button>
          )}
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
          <Button size="sm" variant="outline" onClick={loadData} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Simple, compact operational summary cards */}
      <div className={styles.summaryGrid}>
        <div className={styles.metricCard}>
          <div
            className={styles.metricIcon}
            style={{ backgroundColor: '#E4F1EB', color: '#176B53' }}
          >
            <BookOpen size={22} />
          </div>
          <div className={styles.metricInfo}>
            <span className={styles.metricValue}>
              {isLoading ? <Loader2 size={20} className="animate-spin" /> : workshops.length}
            </span>
            <span className={styles.metricLabel}>Talleres Registrados</span>
          </div>
        </div>

        <div className={styles.metricCard}>
          <div
            className={styles.metricIcon}
            style={{ backgroundColor: '#FEF3C7', color: '#D97706' }}
          >
            <CalendarDays size={22} />
          </div>
          <div className={styles.metricInfo}>
            <span className={styles.metricValue}>
              {isLoading ? <Loader2 size={20} className="animate-spin" /> : activeWorkshops.length}
            </span>
            <span className={styles.metricLabel}>Talleres Activos</span>
          </div>
        </div>

        <div className={styles.metricCard}>
          <div
            className={styles.metricIcon}
            style={{ backgroundColor: '#E0F2FE', color: '#0284C7' }}
          >
            <MapPin size={22} />
          </div>
          <div className={styles.metricInfo}>
            <span className={styles.metricValue}>
              {isLoading ? <Loader2 size={20} className="animate-spin" /> : venuesCount}
            </span>
            <span className={styles.metricLabel}>Sedes Georreferenciadas</span>
          </div>
        </div>

        <div className={styles.metricCard}>
          <div
            className={styles.metricIcon}
            style={{ backgroundColor: '#F1F5F9', color: '#475569' }}
          >
            <Users size={22} />
          </div>
          <div className={styles.metricInfo}>
            <span className={styles.metricValue}>
              {isLoading ? <Loader2 size={20} className="animate-spin" /> : usersCount}
            </span>
            <span className={styles.metricLabel}>Usuarios en Sistema</span>
          </div>
        </div>
      </div>

      {/* Upcoming / Active Workshops Table */}
      <Card>
        <div className={styles.tableHeaderSection}>
          <div>
            <h2 className={styles.sectionTitle}>Próximas Capacitaciones</h2>
            <p className={styles.subtitle}>
              Talleres planificados en centros de abasto y recintos municipales
            </p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            icon={<ArrowRight size={14} />}
            onClick={() => navigate('/coordinator/workshops')}
          >
            Ver todos los talleres
          </Button>
        </div>

        <Table
          headers={[
            'Taller',
            'Sede',
            'Fecha y Hora',
            'Capacitador',
            'Cupos',
            'Estado',
            'Acción',
          ]}
          isLoading={isLoading}
          isEmpty={!isLoading && workshops.length === 0}
        >
          {workshops.slice(0, 5).map(w => (
            <tr key={w.id}>
              <td>
                <div style={{ fontWeight: 500, color: '#1E293B' }}>{w.nombre}</div>
                <div style={{ fontSize: '11px', color: '#64748B' }}>{w.ejeTematico}</div>
              </td>
              <td>{w.sedeNombre}</td>
              <td>
                <div>{w.fecha}</div>
                <div style={{ fontSize: '12px', color: '#64748B' }}>
                  {w.horaInicio} - {w.horaFin}
                </div>
              </td>
              <td>{w.capacitadorNombre}</td>
              <td>
                <span style={{ fontWeight: 500 }}>{w.inscritos}</span> / {w.cuposTotales}
              </td>
              <td>{getStatusBadge(w.estado)}</td>
              <td>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() =>
                    navigate(`/coordinator/sessions?sesionId=${encodeURIComponent(w.id)}`)
                  }
                >
                  Ver Sesión
                </Button>
              </td>
            </tr>
          ))}
        </Table>
      </Card>
    </div>
  );
};
