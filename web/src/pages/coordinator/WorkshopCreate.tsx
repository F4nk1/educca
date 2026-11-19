import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Save,
  X,
  Calendar,
  Clock,
  User,
  BookOpen,
  Plus,
  Loader2,
} from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { venueService } from '../../services/venueService';
import { userService } from '../../services/userService';
import {
  Venue,
  User as UserModel,
  GoMetaAnual,
  SessionModalidad,
} from '../../models/types';
import { getTodayLocalISO, validateTimeRange } from '../../utils/dateUtils';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Modal } from '../../components/ui/Modal';
import styles from './WorkshopCreate.module.css';

export const WorkshopCreate: React.FC = () => {
  const navigate = useNavigate();

  const [venues, setVenues] = useState<Venue[]>([]);
  const [trainers, setTrainers] = useState<UserModel[]>([]);
  const [metas, setMetas] = useState<GoMetaAnual[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form fields
  const [nombre, setNombre] = useState('');
  const [metaAnualId, setMetaAnualId] = useState<string>('');
  const [sedeId, setSedeId] = useState('');
  const [modalidad, setModalidad] = useState<SessionModalidad>('PRESENCIAL');
  const [fecha, setFecha] = useState(() => getTodayLocalISO());
  const [horaInicio, setHoraInicio] = useState('09:00');
  const [horaFin, setHoraFin] = useState('11:30');
  const [capacitadorId, setCapacitadorId] = useState('');
  const [cuposTotales, setCuposTotales] = useState('30');
  const [ejeTematico, setEjeTematico] = useState('SEGREGACION_RECICLA');
  const [error, setError] = useState<string | null>(null);

  // Quick Meta Anual Creation Modal
  const [isMetaModalOpen, setIsMetaModalOpen] = useState(false);
  const [metaAnio, setMetaAnio] = useState(new Date().getFullYear().toString());
  const [metaActividad, setMetaActividad] = useState('PAC');
  const [metaIndicador, setMetaIndicador] = useState(
    'Promotores ambientales capacitados en gestión de residuos'
  );
  const [metaProgramada, setMetaProgramada] = useState('300');
  const [metaPresupuesto, setMetaPresupuesto] = useState('15000');
  const [isCreatingMeta, setIsCreatingMeta] = useState(false);

  useEffect(() => {
    loadDependencies();
  }, []);

  const loadDependencies = async () => {
    setIsLoading(true);
    try {
      const [loadedVenues, loadedUsers, loadedMetas] = await Promise.all([
        venueService.getVenues(),
        userService.getUsers(),
        workshopService.getMetasAnuales().catch(() => [] as GoMetaAnual[]),
      ]);

      setVenues(loadedVenues);
      if (loadedVenues.length > 0) setSedeId(loadedVenues[0].id);

      setMetas(loadedMetas);
      if (loadedMetas.length > 0) setMetaAnualId(loadedMetas[0].id.toString());

      const trainersList = loadedUsers.filter(
        u =>
          (u.rol === 'capacitador' || u.rol === 'coordinador' || u.rol === 'admin') &&
          u.activo
      );
      const effectiveTrainers = trainersList.length > 0 ? trainersList : loadedUsers;
      setTrainers(effectiveTrainers);
      if (effectiveTrainers.length > 0) setCapacitadorId(effectiveTrainers[0].id);
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Error al cargar sedes, metas o capacitadores'
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateMetaAnual = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsCreatingMeta(true);
    try {
      const created = await workshopService.createMetaAnual({
        anio: Math.max(parseInt(metaAnio, 10) || 2026, 2024),
        actividad_minam: metaActividad,
        indicador: metaIndicador.trim() || 'Promotores capacitados',
        meta_programada: Math.max(parseInt(metaProgramada, 10) || 100, 1),
        presupuesto: Math.max(parseFloat(metaPresupuesto) || 0, 0),
      });
      const updatedMetas = [created, ...metas];
      setMetas(updatedMetas);
      setMetaAnualId(created.id.toString());
      setIsMetaModalOpen(false);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al crear la Meta Anual MINAM');
    } finally {
      setIsCreatingMeta(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nombre.trim()) {
      setError('El nombre del taller es obligatorio');
      return;
    }
    if (modalidad === 'PRESENCIAL' && !sedeId) {
      setError('Debe seleccionar una sede georreferenciada para sesiones presenciales');
      return;
    }
    if (!capacitadorId) {
      setError('Debe asignar un capacitador responsable');
      return;
    }
    if (!fecha || !horaInicio || !horaFin) {
      setError('Complete la fecha y el horario del taller');
      return;
    }

    const timeCheck = validateTimeRange(horaInicio, horaFin);
    if (!timeCheck.valid) {
      setError(timeCheck.error || 'El horario de la sesión es inválido');
      return;
    }

    const cupos = parseInt(cuposTotales, 10);
    if (isNaN(cupos) || cupos < 1) {
      setError('El cupo máximo debe ser un número entero positivo');
      return;
    }

    const selectedVenue = venues.find(v => v.id === sedeId);
    const selectedTrainer = trainers.find(t => t.id === capacitadorId);

    setIsSubmitting(true);
    setError(null);
    try {
      await workshopService.createWorkshop({
        nombre: nombre.trim(),
        sedeId,
        sedeNombre: selectedVenue ? selectedVenue.nombre : undefined,
        fecha,
        horaInicio,
        horaFin,
        modalidad,
        capacitadorId,
        capacitadorNombre: selectedTrainer
          ? `${selectedTrainer.nombres} ${selectedTrainer.apellidos}`
          : undefined,
        cuposTotales: cupos,
        ejeTematico,
        metaAnualId: metaAnualId ? parseInt(metaAnualId, 10) : undefined,
      });

      navigate('/coordinator/workshops');
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Error al programar la sesión en el servidor Go'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <button
          type="button"
          className={styles.backButton}
          onClick={() => navigate('/coordinator/workshops')}
          aria-label="Volver a la lista de talleres"
        >
          <ArrowLeft size={18} />
        </button>
        <div>
          <h1 className={styles.title}>Programar Nueva Capacitación</h1>
          <p className={styles.subtitle}>
            Planifique una sesión ambiental vinculada a una meta anual MINAM, sede georreferenciada
            y capacitador
          </p>
        </div>
      </div>

      <Card>
        <form onSubmit={handleSubmit}>
          {error && (
            <div
              style={{
                padding: '10px 14px',
                marginBottom: '16px',
                backgroundColor: '#FEE2E2',
                color: '#DC2626',
                borderRadius: '6px',
                fontSize: '13px',
              }}
            >
              {error}
            </div>
          )}

          <div className={styles.formGrid}>
            <div className={styles.fullCol}>
              <Input
                label="Título del taller ambiental / sesión"
                value={nombre}
                onChange={e => setNombre(e.target.value)}
                placeholder="Ej. Segregación de Residuos Sólidos en Mercados de Abastos"
                icon={<BookOpen size={16} />}
                required
              />
            </div>

            <div>
              <div style={{ display: 'flex', alignItems: 'flex-end', gap: '8px' }}>
                <div style={{ flex: 1 }}>
                  <Select
                    label="Meta Anual MINAM"
                    value={metaAnualId}
                    onChange={e => setMetaAnualId(e.target.value)}
                  >
                    {metas.length === 0 ? (
                      <option value="">Se creará meta PAC por defecto</option>
                    ) : (
                      metas.map(m => (
                        <option key={m.id} value={m.id.toString()}>
                          {m.anio} — {m.actividad_minam}: {m.indicador} (Meta: {m.meta_programada})
                        </option>
                      ))
                    )}
                  </Select>
                </div>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  onClick={() => setIsMetaModalOpen(true)}
                  style={{ marginBottom: '16px', height: '38px' }}
                  title="Crear nueva Meta Anual MINAM"
                >
                  <Plus size={14} />
                </Button>
              </div>
            </div>

            <div>
              <Select
                label="Modalidad de la sesión"
                value={modalidad}
                onChange={e => setModalidad(e.target.value as SessionModalidad)}
                required
              >
                <option value="PRESENCIAL">PRESENCIAL (Con QR dinámico y geocerca GPS)</option>
                <option value="VIRTUAL">VIRTUAL</option>
              </Select>
            </div>

            <div>
              <Select
                label="Sede de capacitación (Georreferenciada)"
                value={sedeId}
                onChange={e => setSedeId(e.target.value)}
                required={modalidad === 'PRESENCIAL'}
              >
                {venues.length === 0 ? (
                  <option value="">No hay sedes registradas</option>
                ) : (
                  venues.map(v => (
                    <option key={v.id} value={v.id}>
                      {v.nombre} ({v.tipo})
                    </option>
                  ))
                )}
              </Select>
            </div>

            <div>
              <Select
                label="Capacitador responsable"
                value={capacitadorId}
                onChange={e => setCapacitadorId(e.target.value)}
                required
              >
                {trainers.length === 0 ? (
                  <option value="">No hay capacitadores registrados</option>
                ) : (
                  trainers.map(t => (
                    <option key={t.id} value={t.id}>
                      {t.nombres} {t.apellidos} ({t.rol})
                    </option>
                  ))
                )}
              </Select>
            </div>

            <div>
              <Input
                label="Fecha programada"
                type="date"
                value={fecha}
                onChange={e => setFecha(e.target.value)}
                icon={<Calendar size={16} />}
                required
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
              <Input
                label="Hora inicio"
                type="time"
                value={horaInicio}
                onChange={e => setHoraInicio(e.target.value)}
                icon={<Clock size={16} />}
                required
              />
              <Input
                label="Hora fin"
                type="time"
                value={horaFin}
                onChange={e => setHoraFin(e.target.value)}
                required
              />
            </div>

            <div>
              <Input
                label="Cupos máximos"
                type="number"
                min="5"
                max="500"
                value={cuposTotales}
                onChange={e => setCuposTotales(e.target.value)}
                icon={<User size={16} />}
                required
              />
            </div>

            <div>
              <Select
                label="Eje temático EDUCCA"
                value={ejeTematico}
                onChange={e => setEjeTematico(e.target.value)}
              >
                <option value="SEGREGACION_RECICLA">
                  SEGREGACION_RECICLA (Segregación y Reciclaje)
                </option>
                <option value="COMPOSTAJE">
                  COMPOSTAJE (Compostaje y Valorización Orgánica)
                </option>
                <option value="RECICLAJE_FORMAL">
                  RECICLAJE_FORMAL (Reciclaje Inclusivo Formal)
                </option>
                <option value="ECOEFICIENCIA">
                  ECOEFICIENCIA (Ecoeficiencia y Recursos Hídricos)
                </option>
                <option value="GESTION_RESIDUOS">
                  GESTION_RESIDUOS (Gestión Integral de Residuos)
                </option>
              </Select>
            </div>
          </div>

          <div className={styles.actions}>
            <Button
              type="button"
              variant="outline"
              icon={<X size={16} />}
              onClick={() => navigate('/coordinator/workshops')}
              disabled={isSubmitting}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              variant="primary"
              disabled={isSubmitting || isLoading}
              icon={
                isSubmitting ? (
                  <Loader2 size={16} className="animate-spin" />
                ) : (
                  <Save size={16} />
                )
              }
            >
              {isSubmitting ? 'Guardando en Servidor...' : 'Guardar y Programar Taller'}
            </Button>
          </div>
        </form>
      </Card>

      {/* Create Meta Anual MINAM Modal */}
      <Modal
        isOpen={isMetaModalOpen}
        onClose={() => setIsMetaModalOpen(false)}
        title="Registrar Meta Anual MINAM"
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsMetaModalOpen(false)}
              disabled={isCreatingMeta}
            >
              Cancelar
            </Button>
            <Button type="submit" form="create-meta-form" disabled={isCreatingMeta}>
              {isCreatingMeta ? 'Guardando...' : 'Crear Meta Anual'}
            </Button>
          </>
        }
      >
        <form id="create-meta-form" onSubmit={handleCreateMetaAnual}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input
              label="Año fiscal (>= 2024)"
              type="number"
              min="2024"
              max="2035"
              value={metaAnio}
              onChange={e => setMetaAnio(e.target.value)}
              required
            />
            <Select
              label="Actividad MINAM"
              value={metaActividad}
              onChange={e => setMetaActividad(e.target.value)}
            >
              <option value="PAC">PAC (Promotor Ambiental Comunitario)</option>
              <option value="PAJ">PAJ (Promotor Ambiental Juvenil)</option>
              <option value="PAE">PAE (Promotor Ambiental Escolar)</option>
              <option value="EPEA">EPEA (Espacio Público Educativo)</option>
              <option value="CAMPANA">CAMPANA (Campaña Ambiental)</option>
            </Select>
          </div>

          <Input
            label="Indicador de desempeño"
            value={metaIndicador}
            onChange={e => setMetaIndicador(e.target.value)}
            required
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input
              label="Meta programada (personas)"
              type="number"
              min="1"
              value={metaProgramada}
              onChange={e => setMetaProgramada(e.target.value)}
              required
            />
            <Input
              label="Presupuesto asignado (S/)"
              type="number"
              min="0"
              step="0.01"
              value={metaPresupuesto}
              onChange={e => setMetaPresupuesto(e.target.value)}
              required
            />
          </div>
        </form>
      </Modal>
    </div>
  );
};
