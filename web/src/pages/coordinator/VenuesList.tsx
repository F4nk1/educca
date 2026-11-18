import React, { useState, useEffect } from 'react';
import {
  MapPin,
  Plus,
  Search,
  Edit2,
  Trash2,
  Navigation,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { venueService } from '../../services/venueService';
import { Venue, VenueType } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Modal } from '../../components/ui/Modal';
import styles from './VenuesList.module.css';

export const VenuesList: React.FC = () => {
  const [venues, setVenues] = useState<Venue[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVenue, setEditingVenue] = useState<Venue | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form state
  const [formNombre, setFormNombre] = useState('');
  const [formDireccion, setFormDireccion] = useState('');
  const [formTipo, setFormTipo] = useState<VenueType>('MERCADO');
  const [formLat, setFormLat] = useState('-13.5186');
  const [formLng, setFormLng] = useState('-71.9839');
  const [formRadio, setFormRadio] = useState('80');
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    loadVenues();
  }, []);

  const loadVenues = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await venueService.getVenues();
      setVenues(data);
    } catch (err: any) {
      setError(err?.message || 'Error al cargar las sedes');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenCreateModal = () => {
    setEditingVenue(null);
    setFormNombre('');
    setFormDireccion('');
    setFormTipo('MERCADO');
    setFormLat('-13.5186');
    setFormLng('-71.9839');
    setFormRadio('80');
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (venue: Venue) => {
    setEditingVenue(venue);
    setFormNombre(venue.nombre);
    setFormDireccion(venue.direccion);
    setFormTipo(venue.tipo);
    setFormLat(venue.latitud.toString());
    setFormLng(venue.longitud.toString());
    setFormRadio(venue.radioMetros.toString());
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleSaveVenue = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formNombre.trim()) {
      setFormError('El nombre de la sede es obligatorio');
      return;
    }
    if (!formDireccion.trim()) {
      setFormError('La dirección es obligatoria');
      return;
    }

    const lat = parseFloat(formLat);
    const lng = parseFloat(formLng);
    const radio = parseInt(formRadio, 10) || 80;

    if (isNaN(lat) || isNaN(lng)) {
      setFormError('Las coordenadas geográficas deben ser números válidos');
      return;
    }

    setIsSubmitting(true);
    setFormError(null);
    try {
      if (editingVenue) {
        await venueService.updateVenue(editingVenue.id, {
          nombre: formNombre,
          direccion: formDireccion,
          tipo: formTipo,
          latitud: lat,
          longitud: lng,
          radioMetros: radio,
        });
      } else {
        await venueService.createVenue({
          nombre: formNombre,
          direccion: formDireccion,
          tipo: formTipo,
          latitud: lat,
          longitud: lng,
          radioMetros: radio,
        });
      }

      setIsModalOpen(false);
      await loadVenues();
    } catch (err: any) {
      setFormError(err?.message || 'Error al guardar la sede en el backend');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteVenue = async (id: string) => {
    if (!window.confirm('¿Está seguro de eliminar esta sede georreferenciada?')) return;
    try {
      await venueService.deleteVenue(id);
      await loadVenues();
    } catch (err: any) {
      alert(err?.message || 'Error al eliminar la sede');
    }
  };

  const filteredVenues = venues.filter(v => {
    const matchesSearch =
      v.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      v.direccion.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = typeFilter === 'ALL' || v.tipo === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Sedes Georreferenciadas</h1>
          <p className={styles.subtitle}>
            Catálogo de mercados, centros de valorización y recintos autorizados en PostgreSQL
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={handleOpenCreateModal}
        >
          Nueva Sede
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
          <Button size="sm" variant="outline" onClick={loadVenues} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className={styles.filterBar}>
        <div className={styles.searchBox}>
          <Input
            placeholder="Buscar por nombre o dirección..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            icon={<Search size={16} />}
            style={{ marginBottom: 0 }}
          />
        </div>

        <div className={styles.filterSelect}>
          <Select
            value={typeFilter}
            onChange={e => setTypeFilter(e.target.value)}
            style={{ marginBottom: 0 }}
          >
            <option value="ALL">Todos los tipos</option>
            <option value="MERCADO">Mercado</option>
            <option value="CENTRO_ACOPIO">Centro de Acopio</option>
            <option value="INSTITUCION_PUBLICA">Institución Pública</option>
            <option value="ESPACIO_PUBLICO_EPEA">Espacio Público EPEA</option>
            <option value="ORGANIZACION_SOCIAL">Organización Social</option>
            <option value="COLEGIO">Colegio</option>
            <option value="EDUCACION_SUPERIOR">Educación Superior</option>
          </Select>
        </div>
      </div>

      {/* Venues Table */}
      <Table
        headers={[
          'Nombre de Sede',
          'Tipo',
          'Dirección / Sector',
          'Geolocalización',
          'Radio Geocerca',
          'Estado',
          'Acciones',
        ]}
        isEmpty={!isLoading && filteredVenues.length === 0}
      >
        {filteredVenues.map(venue => (
          <tr key={venue.id}>
            <td>
              <div style={{ fontWeight: 600, color: '#1E293B', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <MapPin size={16} color="#176B53" />
                {venue.nombre}
              </div>
            </td>
            <td>
              <span style={{ fontSize: '12px', fontWeight: 500, color: '#475569' }}>
                {venue.tipo.replace(/_/g, ' ')}
              </span>
            </td>
            <td style={{ color: '#475569' }}>{venue.direccion}</td>
            <td>
              <span className={styles.geoBadge}>
                <Navigation size={12} color="#0D9488" />
                {venue.latitud.toFixed(4)}, {venue.longitud.toFixed(4)}
              </span>
            </td>
            <td>
              <span style={{ fontWeight: 500 }}>{venue.radioMetros} m</span>
            </td>
            <td>
              <Badge variant="success" withDot>
                Activo
              </Badge>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleOpenEditModal(venue)}
                  title="Editar sede"
                >
                  <Edit2 size={13} />
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => handleDeleteVenue(venue.id)}
                  title="Eliminar sede"
                >
                  <Trash2 size={14} color="#DC2626" />
                </Button>
              </div>
            </td>
          </tr>
        ))}
      </Table>

      {/* Create / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingVenue ? 'Editar Sede' : 'Registrar Nueva Sede'}
        footer={
          <>
            <Button variant="outline" onClick={() => setIsModalOpen(false)} disabled={isSubmitting}>
              Cancelar
            </Button>
            <Button onClick={handleSaveVenue} disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 size={14} className="animate-spin" /> Guardando...
                </>
              ) : editingVenue ? (
                'Guardar Cambios'
              ) : (
                'Registrar Sede'
              )}
            </Button>
          </>
        }
      >
        <form onSubmit={handleSaveVenue}>
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
            label="Nombre de la sede"
            value={formNombre}
            onChange={e => setFormNombre(e.target.value)}
            placeholder="Ej. Mercado Central San Pedro"
            required
          />

          <Input
            label="Dirección / Sector de ubicación"
            value={formDireccion}
            onChange={e => setFormDireccion(e.target.value)}
            placeholder="Ej. Calle Cascaparo s/n, Centro Histórico"
            required
          />

          <Select
            label="Tipo de organización / recinto"
            value={formTipo}
            onChange={e => setFormTipo(e.target.value as VenueType)}
          >
            <option value="MERCADO">MERCADO (Mercado de abastos)</option>
            <option value="CENTRO_ACOPIO">CENTRO_ACOPIO (Planta de valorización)</option>
            <option value="INSTITUCION_PUBLICA">INSTITUCION_PUBLICA (Palacio municipal / auditorio)</option>
            <option value="ESPACIO_PUBLICO_EPEA">ESPACIO_PUBLICO_EPEA (Plaza o parque)</option>
            <option value="ORGANIZACION_SOCIAL">ORGANIZACION_SOCIAL</option>
            <option value="COLEGIO">COLEGIO (Institución educativa)</option>
            <option value="EDUCACION_SUPERIOR">EDUCACION_SUPERIOR (Universidad / Instituto)</option>
          </Select>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input
              label="Latitud"
              value={formLat}
              onChange={e => setFormLat(e.target.value)}
              placeholder="-13.5186"
              required
            />
            <Input
              label="Longitud"
              value={formLng}
              onChange={e => setFormLng(e.target.value)}
              placeholder="-71.9839"
              required
            />
          </div>

          <Input
            label="Radio geocerca (metros)"
            type="number"
            value={formRadio}
            onChange={e => setFormRadio(e.target.value)}
            helper="Estándar EDUCCA para validación Haversine: 80 m"
            required
          />
        </form>
      </Modal>
    </div>
  );
};
