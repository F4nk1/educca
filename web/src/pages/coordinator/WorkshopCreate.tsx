import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Save, X, Calendar, Clock, User, BookOpen, Loader2 } from 'lucide-react';
import { workshopService } from '../../services/workshopService';
import { venueService } from '../../services/venueService';
import { userService } from '../../services/userService';
import { Venue, User as UserModel } from '../../models/types';
import { Card } from '../../components/ui/Card';
import { Button } from '../../components/ui/Button';
import { Input, Select, Textarea } from '../../components/ui/Input';
import styles from './WorkshopCreate.module.css';

export const WorkshopCreate: React.FC = () => {
  const navigate = useNavigate();

  const [venues, setVenues] = useState<Venue[]>([]);
  const [trainers, setTrainers] = useState<UserModel[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form fields
  const [nombre, setNombre] = useState('');
  const [sedeId, setSedeId] = useState('');
  const [fecha, setFecha] = useState('2026-11-28');
  const [horaInicio, setHoraInicio] = useState('09:00');
  const [horaFin, setHoraFin] = useState('11:30');
  const [capacitadorId, setCapacitadorId] = useState('');
  const [cuposTotales, setCuposTotales] = useState('30');
  const [ejeTematico, setEjeTematico] = useState('SEGREGACION_RECICLA');
  const [descripcion, setDescripcion] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDependencies();
  }, []);

  const loadDependencies = async () => {
    setIsLoading(true);
    try {
      const [loadedVenues, loadedUsers] = await Promise.all([
        venueService.getVenues(),
        userService.getUsers(),
      ]);

      setVenues(loadedVenues);
      if (loadedVenues.length > 0) setSedeId(loadedVenues[0].id);

      // Filter capacitadores or coordinators who can lead workshops
      const trainersList = loadedUsers.filter(
        u => u.rol === 'capacitador' || u.rol === 'coordinador' || u.rol === 'admin'
      );
      setTrainers(trainersList.length > 0 ? trainersList : loadedUsers);
      if (trainersList.length > 0) setCapacitadorId(trainersList[0].id);
      else if (loadedUsers.length > 0) setCapacitadorId(loadedUsers[0].id);
    } catch (err: any) {
      setError(err?.message || 'Error al cargar sedes o capacitadores');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nombre.trim()) {
      setError('El nombre del taller es obligatorio');
      return;
    }
    if (!sedeId) {
      setError('Debe seleccionar una sede autorizada');
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

    const selectedVenue = venues.find(v => v.id === sedeId);
    const selectedTrainer = trainers.find(t => t.id === capacitadorId);

    setIsSubmitting(true);
    setError(null);
    try {
      await workshopService.createWorkshop({
        nombre,
        sedeId,
        sedeNombre: selectedVenue ? selectedVenue.nombre : undefined,
        fecha,
        horaInicio,
        horaFin,
        capacitadorId,
        capacitadorNombre: selectedTrainer
          ? `${selectedTrainer.nombres} ${selectedTrainer.apellidos}`
          : undefined,
        cuposTotales: parseInt(cuposTotales, 10) || 30,
        ejeTematico,
        descripcion,
      });

      navigate('/coordinator/workshops');
    } catch (err: any) {
      setError(err?.message || 'Error al programar la sesión en el servidor Go');
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
            Planifique una sesión ambiental con sede georreferenciada y asignación de capacitador
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
              <Select
                label="Sede de capacitación (Georreferenciada)"
                value={sedeId}
                onChange={e => setSedeId(e.target.value)}
                required
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
                      {t.nombres} {t.apellidos}
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
                max="100"
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
                <option value="SEGREGACION_RECICLA">SEGREGACION_RECICLA (Segregación y Reciclaje)</option>
                <option value="COMPOSTAJE">COMPOSTAJE (Compostaje y Valorización Orgánica)</option>
                <option value="RECICLAJE_FORMAL">RECICLAJE_FORMAL (Reciclaje Inclusivo Formal)</option>
                <option value="ECOEFICIENCIA">ECOEFICIENCIA (Ecoeficiencia y Recursos Hídricos)</option>
                <option value="GESTION_RESIDUOS">GESTION_RESIDUOS (Gestión Integral de Residuos)</option>
              </Select>
            </div>

            <div className={styles.fullCol}>
              <Textarea
                label="Descripción y objetivos de la sesión"
                rows={3}
                value={descripcion}
                onChange={e => setDescripcion(e.target.value)}
                placeholder="Detalle los temas a desarrollar y acuerdos a tomar..."
              />
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
              icon={isSubmitting ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
            >
              {isSubmitting ? 'Guardando en Servidor...' : 'Guardar y Programar Taller'}
            </Button>
          </div>
        </form>
      </Card>
    </div>
  );
};
