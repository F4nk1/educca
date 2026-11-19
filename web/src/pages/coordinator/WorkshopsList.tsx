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
  Edit2,
  Trash2,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { venueService } from '../../services/venueService';
import { userService } from '../../services/userService';
import { Workshop, Venue, User as UserModel, SessionModalidad } from '../../models/types';
import { validateTimeRange } from '../../utils/dateUtils';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Modal } from '../../components/ui/Modal';
import styles from './WorkshopsList.module.css';

export const WorkshopsList: React.FC = () => {
  const [workshops, setWorkshops] = useState<Workshop[]>([]);
  const [venues, setVenues] = useState<Venue[]>([]);
  const [trainers, setTrainers] = useState<UserModel[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Edit modal state
  const [editingWorkshop, setEditingWorkshop] = useState<Workshop | null>(null);
  const [formNombre, setFormNombre] = useState('');
  const [formSedeId, setFormSedeId] = useState('');
  const [formFecha, setFormFecha] = useState('');
  const [formHoraInicio, setFormHoraInicio] = useState('09:00');
  const [formHoraFin, setFormHoraFin] = useState('11:00');
  const [formModalidad, setFormModalidad] = useState<SessionModalidad>('PRESENCIAL');
  const [formCapacitadorId, setFormCapacitadorId] = useState('');
  const [formCupos, setFormCupos] = useState('30');
  const [formEje, setFormEje] = useState('SEGREGACION_RECICLA');
  const [formError, setFormError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Delete confirmation modal
  const [deletingWorkshop, setDeletingWorkshop] = useState<Workshop | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const { isReadOnly } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    loadWorkshops();
  }, []);

  const loadWorkshops = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [data, loadedVenues, loadedUsers] = await Promise.all([
        workshopService.getWorkshops(),
        venueService.getVenues().catch(() => []),
        userService.getUsers().catch(() => []),
      ]);
      setWorkshops(data);
      setVenues(loadedVenues);
      const validTrainers = loadedUsers.filter(
        u => u.rol === 'capacitador' || u.rol === 'coordinador' || u.rol === 'admin'
      );
      setTrainers(validTrainers.length > 0 ? validTrainers : loadedUsers);
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Error al cargar los talleres desde el backend'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenEdit = (w: Workshop) => {
    setEditingWorkshop(w);
    setFormNombre(w.nombre);
    setFormSedeId(w.sedeId || (venues[0]?.id ?? ''));
    setFormFecha(w.fecha);
    setFormHoraInicio(w.horaInicio);
    setFormHoraFin(w.horaFin);
    setFormModalidad(w.modalidad || 'PRESENCIAL');
    setFormCapacitadorId(w.capacitadorId || (trainers[0]?.id ?? ''));
    setFormCupos(w.cuposTotales.toString());
    setFormEje(w.ejeTematicoCodigo || 'SEGREGACION_RECICLA');
    setFormError(null);
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingWorkshop) return;
    if (!formNombre.trim()) {
      setFormError('El título del taller es obligatorio');
      return;
    }

    const timeCheck = validateTimeRange(formHoraInicio, formHoraFin);
    if (!timeCheck.valid) {
      setFormError(timeCheck.error || 'Horario inválido');
      return;
    }

    const cupos = parseInt(formCupos, 10);
    if (isNaN(cupos) || cupos < Math.max(editingWorkshop.inscritos, 1)) {
      setFormError(
        `El cupo máximo debe ser al menos igual al número actual de inscritos (${editingWorkshop.inscritos})`
      );
      return;
    }

    setIsSubmitting(true);
    setFormError(null);
    try {
      await workshopService.updateWorkshop(editingWorkshop.id, {
        nombre: formNombre.trim(),
        sedeId: formSedeId,
        fecha: formFecha,
        horaInicio: formHoraInicio,
        horaFin: formHoraFin,
        modalidad: formModalidad,
        capacitadorId: formCapacitadorId,
        cuposTotales: cupos,
        ejeTematico: formEje,
        metaAnualId: editingWorkshop.metaAnualId || 1,
      });
      setEditingWorkshop(null);
      await loadWorkshops();
    } catch (err: unknown) {
      setFormError(err instanceof Error ? err.message : 'Error al actualizar el taller');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deletingWorkshop) return;
    setIsDeleting(true);
    try {
      await workshopService.deleteWorkshop(deletingWorkshop.id);
      setDeletingWorkshop(null);
      await loadWorkshops();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al eliminar el taller');
      setDeletingWorkshop(null);
    } finally {
      setIsDeleting(false);
    }
  };

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

  const filteredWorkshops = workshops.filter(w => {
    const matchesSearch =
      w.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      w.sedeNombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      w.capacitadorNombre.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'ALL' || w.estado === statusFilter;
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
        {!isReadOnly && (
          <Button
            variant="primary"
            icon={<Plus size={16} />}
            onClick={() => navigate('/coordinator/workshops/create')}
          >
            Crear Taller
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
            <option value="PROGRAMADA">Programada</option>
            <option value="EJECUTADA">En curso / Ejecutada</option>
            <option value="VALIDADA">Validada</option>
            <option value="CANCELADA">Cancelada</option>
          </Select>
        </div>
      </div>

      {/* Workshops Table */}
      <Table
        headers={[
          'Taller y Eje Temático',
          'Sede / Modalidad',
          'Fecha / Horario',
          'Capacitador',
          'Inscritos / Cupos',
          'Estado',
          'Acciones',
        ]}
        isLoading={isLoading}
        isEmpty={!isLoading && filteredWorkshops.length === 0}
      >
        {filteredWorkshops.map(workshop => {
          const canModify =
            !isReadOnly &&
            workshop.estado !== 'VALIDADA' &&
            workshop.estado !== 'CANCELADA';

          return (
            <tr key={workshop.id}>
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
                  <BookOpen size={16} color="#176B53" />
                  {workshop.nombre}
                </div>
                <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                  {workshop.ejeTematico}
                </div>
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
                  {workshop.sedeNombre}
                </div>
                <div style={{ fontSize: '11px', color: '#64748B', marginTop: '2px' }}>
                  {workshop.modalidad}
                </div>
              </td>
              <td>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Calendar size={13} color="#64748B" />
                  <span>{workshop.fecha}</span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    fontSize: '12px',
                    color: '#64748B',
                  }}
                >
                  <Clock size={12} />
                  <span>
                    {workshop.horaInicio} - {workshop.horaFin}
                  </span>
                </div>
              </td>
              <td>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    color: '#334155',
                  }}
                >
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
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Button
                    size="sm"
                    variant="outline"
                    icon={<ArrowRight size={13} />}
                    onClick={() =>
                      navigate(
                        `/coordinator/sessions?sesionId=${encodeURIComponent(workshop.id)}`
                      )
                    }
                  >
                    Sesión
                  </Button>
                  {canModify && (
                    <>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleOpenEdit(workshop)}
                        title="Editar taller"
                      >
                        <Edit2 size={13} />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => setDeletingWorkshop(workshop)}
                        title="Eliminar taller"
                      >
                        <Trash2 size={14} color="#DC2626" />
                      </Button>
                    </>
                  )}
                </div>
              </td>
            </tr>
          );
        })}
      </Table>

      {/* Edit Workshop Modal */}
      <Modal
        isOpen={Boolean(editingWorkshop)}
        onClose={() => setEditingWorkshop(null)}
        title="Editar Taller / Sesión"
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setEditingWorkshop(null)}
              disabled={isSubmitting}
            >
              Cancelar
            </Button>
            <Button type="submit" form="workshop-edit-form" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 size={14} className="animate-spin" /> Guardando...
                </>
              ) : (
                'Guardar Cambios'
              )}
            </Button>
          </>
        }
      >
        <form id="workshop-edit-form" onSubmit={handleSaveEdit}>
          {formError && (
            <div
              style={{
                padding: '8px 12px',
                marginBottom: '12px',
                backgroundColor: '#FEE2E2',
                color: '#DC2626',
                borderRadius: '6px',
                fontSize: '12px',
              }}
            >
              {formError}
            </div>
          )}

          <Input
            label="Título del taller"
            value={formNombre}
            onChange={e => setFormNombre(e.target.value)}
            required
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Select
              label="Sede Georreferenciada"
              value={formSedeId}
              onChange={e => setFormSedeId(e.target.value)}
            >
              {venues.map(v => (
                <option key={v.id} value={v.id}>
                  {v.nombre}
                </option>
              ))}
            </Select>

            <Select
              label="Modalidad"
              value={formModalidad}
              onChange={e => setFormModalidad(e.target.value as SessionModalidad)}
            >
              <option value="PRESENCIAL">PRESENCIAL</option>
              <option value="VIRTUAL">VIRTUAL</option>
            </Select>
          </div>

          <Select
            label="Capacitador responsable"
            value={formCapacitadorId}
            onChange={e => setFormCapacitadorId(e.target.value)}
          >
            {trainers.map(t => (
              <option key={t.id} value={t.id}>
                {t.nombres} {t.apellidos}
              </option>
            ))}
          </Select>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
            <Input
              label="Fecha"
              type="date"
              value={formFecha}
              onChange={e => setFormFecha(e.target.value)}
              required
            />
            <Input
              label="Hora inicio"
              type="time"
              value={formHoraInicio}
              onChange={e => setFormHoraInicio(e.target.value)}
              required
            />
            <Input
              label="Hora fin"
              type="time"
              value={formHoraFin}
              onChange={e => setFormHoraFin(e.target.value)}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '12px' }}>
            <Input
              label="Cupo máximo"
              type="number"
              min="5"
              max="500"
              value={formCupos}
              onChange={e => setFormCupos(e.target.value)}
              required
            />
            <Select
              label="Eje temático EDUCCA"
              value={formEje}
              onChange={e => setFormEje(e.target.value)}
            >
              <option value="SEGREGACION_RECICLA">SEGREGACION_RECICLA</option>
              <option value="COMPOSTAJE">COMPOSTAJE</option>
              <option value="RECICLAJE_FORMAL">RECICLAJE_FORMAL</option>
              <option value="ECOEFICIENCIA">ECOEFICIENCIA</option>
              <option value="GESTION_RESIDUOS">GESTION_RESIDUOS</option>
            </Select>
          </div>
        </form>
      </Modal>

      {/* Delete Workshop Confirmation Modal */}
      <Modal
        isOpen={Boolean(deletingWorkshop)}
        onClose={() => setDeletingWorkshop(null)}
        title="Confirmar Eliminación de Taller"
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setDeletingWorkshop(null)}
              disabled={isDeleting}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              variant="danger"
              onClick={handleConfirmDelete}
              disabled={isDeleting}
            >
              {isDeleting ? 'Eliminando...' : 'Eliminar Taller'}
            </Button>
          </>
        }
      >
        <p style={{ fontSize: '13px', color: '#334155' }}>
          ¿Está seguro de eliminar el taller <strong>{deletingWorkshop?.nombre}</strong>?
        </p>
      </Modal>
    </div>
  );
};
