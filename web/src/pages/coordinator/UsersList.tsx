import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  Edit2,
  CheckCircle2,
  XCircle,
  Mail,
  Phone,
  AlertCircle,
  Loader2,
} from 'lucide-react';
import { userService } from '../../services/userService';
import { User, UserRole, PromoterCategory } from '../../models/types';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Modal } from '../../components/ui/Modal';
import styles from './UsersList.module.css';

export const UsersList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form state
  const [formDni, setFormDni] = useState('');
  const [formNombres, setFormNombres] = useState('');
  const [formApellidos, setFormApellidos] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formTelefono, setFormTelefono] = useState('');
  const [formRol, setFormRol] = useState<UserRole>('capacitador');
  const [formCategoria, setFormCategoria] = useState<PromoterCategory>('PAC');
  const [formPassword, setFormPassword] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await userService.getUsers();
      setUsers(data);
    } catch (err: any) {
      setError(err?.message || 'Error al cargar usuarios desde el servidor');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenCreateModal = () => {
    setEditingUser(null);
    setFormDni('');
    setFormNombres('');
    setFormApellidos('');
    setFormEmail('');
    setFormTelefono('');
    setFormRol('capacitador');
    setFormCategoria('PAC');
    setFormPassword('Educca2026*');
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (user: User) => {
    setEditingUser(user);
    setFormDni(user.dni);
    setFormNombres(user.nombres);
    setFormApellidos(user.apellidos);
    setFormEmail(user.email);
    setFormTelefono(user.telefono);
    setFormRol(user.rol);
    if (user.categoria) setFormCategoria(user.categoria as PromoterCategory);
    setFormPassword('');
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleSaveUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formDni.trim() || formDni.length !== 8) {
      setFormError('El DNI debe contener exactamente 8 dígitos numéricos');
      return;
    }
    if (!formNombres.trim() || !formApellidos.trim()) {
      setFormError('Nombres y apellidos son obligatorios');
      return;
    }
    if (!formEmail.trim()) {
      setFormError('El correo electrónico es obligatorio');
      return;
    }

    setIsSubmitting(true);
    setFormError(null);
    try {
      if (editingUser) {
        await userService.updateUser(editingUser.id, {
          dni: formDni,
          nombres: formNombres,
          apellidos: formApellidos,
          email: formEmail,
          telefono: formTelefono,
          rol: formRol,
          categoria: formRol === 'promotor' ? formCategoria : undefined,
        });
      } else {
        await userService.createUser({
          dni: formDni,
          nombres: formNombres,
          apellidos: formApellidos,
          email: formEmail,
          telefono: formTelefono,
          rol: formRol,
          categoria: formRol === 'promotor' ? formCategoria : undefined,
          password: formPassword || 'Educca2026*',
        });
      }

      setIsModalOpen(false);
      await loadUsers();
    } catch (err: any) {
      setFormError(err?.message || 'Error al registrar el usuario en el backend');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (id: string) => {
    try {
      await userService.toggleUserStatus(id);
      await loadUsers();
    } catch (err: any) {
      alert(err?.message || 'Error al cambiar estado del usuario');
    }
  };

  const filteredUsers = users.filter(u => {
    const matchesSearch =
      u.dni.includes(searchTerm) ||
      u.nombres.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.apellidos.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = roleFilter === 'ALL' || u.rol === roleFilter;
    return matchesSearch && matchesRole;
  });

  const getRoleBadge = (rol: UserRole, categoria?: string) => {
    switch (rol) {
      case 'coordinador':
      case 'admin':
        return <Badge variant="primary">{rol.toUpperCase()}</Badge>;
      case 'capacitador':
        return <Badge variant="info">Capacitador</Badge>;
      case 'promotor':
      case 'capacitando':
        return <Badge variant="warning">{categoria || 'Promotor'}</Badge>;
      default:
        return <Badge variant="neutral">{rol}</Badge>;
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Directorio de Usuarios</h1>
          <p className={styles.subtitle}>
            Gestión de personas, coordinadores y promotores registrados en la base de datos
          </p>
        </div>
        <Button
          variant="primary"
          icon={<Plus size={16} />}
          onClick={handleOpenCreateModal}
        >
          Nuevo Usuario
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
          <Button size="sm" variant="outline" onClick={loadUsers} style={{ marginLeft: 'auto' }}>
            Reintentar
          </Button>
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className={styles.filterBar}>
        <div className={styles.searchBox}>
          <Input
            placeholder="Buscar por DNI, nombre o correo..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            icon={<Search size={16} />}
            style={{ marginBottom: 0 }}
          />
        </div>

        <div className={styles.filterSelect}>
          <Select
            value={roleFilter}
            onChange={e => setRoleFilter(e.target.value)}
            style={{ marginBottom: 0 }}
          >
            <option value="ALL">Todos los roles</option>
            <option value="coordinador">Coordinadores / Admin</option>
            <option value="capacitador">Capacitadores</option>
            <option value="promotor">Promotores</option>
          </Select>
        </div>
      </div>

      {/* Users Table */}
      <Table
        headers={[
          'DNI / Documento',
          'Nombres y Apellidos',
          'Contacto',
          'Rol / Perfil',
          'Estado',
          'Acciones',
        ]}
        isEmpty={!isLoading && filteredUsers.length === 0}
      >
        {filteredUsers.map(user => (
          <tr key={user.id}>
            <td>
              <span style={{ fontFamily: 'monospace', fontWeight: 600 }}>{user.dni}</span>
            </td>
            <td>
              <div style={{ fontWeight: 600, color: '#1E293B' }}>
                {user.nombres} {user.apellidos}
              </div>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: '#475569' }}>
                <Mail size={12} />
                <span>{user.email || 'Sin correo'}</span>
              </div>
              {user.telefono && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '11px', color: '#94A3B8' }}>
                  <Phone size={11} />
                  <span>{user.telefono}</span>
                </div>
              )}
            </td>
            <td>{getRoleBadge(user.rol, user.categoria)}</td>
            <td>
              <Badge variant={user.activo ? 'success' : 'neutral'} withDot>
                {user.activo ? 'Activo' : 'Inactivo'}
              </Badge>
            </td>
            <td>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleOpenEditModal(user)}
                  title="Editar usuario"
                >
                  <Edit2 size={13} />
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => handleToggleStatus(user.id)}
                  title={user.activo ? 'Inactivar usuario' : 'Activar usuario'}
                >
                  {user.activo ? (
                    <XCircle size={15} color="#DC2626" />
                  ) : (
                    <CheckCircle2 size={15} color="#16A34A" />
                  )}
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
        title={editingUser ? 'Editar Persona' : 'Registrar Nueva Persona'}
        footer={
          <>
            <Button variant="outline" onClick={() => setIsModalOpen(false)} disabled={isSubmitting}>
              Cancelar
            </Button>
            <Button onClick={handleSaveUser} disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 size={14} className="animate-spin" /> Guardando...
                </>
              ) : editingUser ? (
                'Guardar Cambios'
              ) : (
                'Registrar Persona'
              )}
            </Button>
          </>
        }
      >
        <form onSubmit={handleSaveUser}>
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '12px' }}>
            <Input
              label="DNI"
              value={formDni}
              onChange={e => setFormDni(e.target.value.replace(/\D/g, '').slice(0, 8))}
              placeholder="8 dígitos"
              required
            />
            <Input
              label="Nombres"
              value={formNombres}
              onChange={e => setFormNombres(e.target.value)}
              placeholder="Ej. Juan Carlos"
              required
            />
          </div>

          <Input
            label="Apellidos"
            value={formApellidos}
            onChange={e => setFormApellidos(e.target.value)}
            placeholder="Ej. Quispe Huamán"
            required
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Input
              label="Correo electrónico"
              type="email"
              value={formEmail}
              onChange={e => setFormEmail(e.target.value)}
              placeholder="usuario@educca.gob.pe"
              required
            />
            <Input
              label="Teléfono / Celular"
              value={formTelefono}
              onChange={e => setFormTelefono(e.target.value)}
              placeholder="984123456"
            />
          </div>

          {!editingUser && (
            <Input
              label="Contraseña inicial"
              type="password"
              value={formPassword}
              onChange={e => setFormPassword(e.target.value)}
              placeholder="Mínimo 8 caracteres"
              helper="Por defecto: Educca2026*"
            />
          )}

          <div style={{ display: 'grid', gridTemplateColumns: formRol === 'promotor' ? '1fr 1fr' : '1fr', gap: '12px' }}>
            <Select
              label="Perfil asignado"
              value={formRol}
              onChange={e => setFormRol(e.target.value as UserRole)}
            >
              <option value="capacitador">Capacitador Ambiental</option>
              <option value="coordinador">Coordinador</option>
              <option value="promotor">Promotor / Participante</option>
            </Select>

            {formRol === 'promotor' && (
              <Select
                label="Categoría promotor"
                value={formCategoria}
                onChange={e => setFormCategoria(e.target.value as PromoterCategory)}
              >
                <option value="PAJ">PAJ (Promotor Ambiental Juvenil)</option>
                <option value="PAC">PAC (Promotor Ambiental Comunitario)</option>
                <option value="COMERCIANTE">Comerciante de Mercado</option>
                <option value="RECICLADOR">Reciclador Formalizado</option>
              </Select>
            )}
          </div>
        </form>
      </Modal>
    </div>
  );
};
