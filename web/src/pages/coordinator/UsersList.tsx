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
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/ui/Button';
import { Input, Select } from '../../components/ui/Input';
import { Badge } from '../../components/ui/Badge';
import { Table } from '../../components/ui/Table';
import { Modal } from '../../components/ui/Modal';
import styles from './UsersList.module.css';

function isAtLeast18YearsOld(birthDateStr: string): boolean {
  const birth = new Date(`${birthDateStr}T00:00:00`);
  if (isNaN(birth.getTime())) return false;
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age >= 18 && birth.getFullYear() >= 1900;
}

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
  const [formSexo, setFormSexo] = useState<'M' | 'F'>('M');
  const [formFechaNacimiento, setFormFechaNacimiento] = useState('1995-01-01');
  const [formEmail, setFormEmail] = useState('');
  const [formTelefono, setFormTelefono] = useState('');
  const [formRol, setFormRol] = useState<UserRole>('capacitador');
  const [formCategoria, setFormCategoria] = useState<PromoterCategory>('PAC');
  const [formPassword, setFormPassword] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  const { isReadOnly } = useAuth();

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await userService.getUsers();
      setUsers(data);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al cargar usuarios desde el servidor');
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenCreateModal = () => {
    setEditingUser(null);
    setFormDni('');
    setFormNombres('');
    setFormApellidos('');
    setFormSexo('M');
    setFormFechaNacimiento('1995-01-01');
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
    setFormSexo(user.sexo || 'M');
    setFormFechaNacimiento(user.fechaNacimiento || '1995-01-01');
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
    if (!formDni.trim() || formDni.trim().length < 8) {
      setFormError('El documento de identidad (DNI) debe contener al menos 8 caracteres');
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
    if (!formFechaNacimiento || !isAtLeast18YearsOld(formFechaNacimiento)) {
      setFormError(
        'La fecha de nacimiento debe corresponder a una persona mayor de edad (>= 18 años) conforme a la LPDP'
      );
      return;
    }
    if (!editingUser && formPassword && formPassword.length < 8) {
      setFormError('La contraseña inicial debe tener al menos 8 caracteres');
      return;
    }
    if (editingUser && formPassword && formPassword.length > 0 && formPassword.length < 8) {
      setFormError('Si desea actualizar la contraseña, debe tener al menos 8 caracteres');
      return;
    }

    setIsSubmitting(true);
    setFormError(null);
    try {
      const isPromoter = formRol === 'promotor' || formRol === 'capacitando';
      if (editingUser) {
        await userService.updateUser(editingUser.id, {
          dni: formDni.trim(),
          nombres: formNombres.trim(),
          apellidos: formApellidos.trim(),
          sexo: formSexo,
          fechaNacimiento: formFechaNacimiento,
          email: formEmail.trim(),
          telefono: formTelefono.trim(),
          rol: formRol,
          categoria: isPromoter ? formCategoria : undefined,
          password: formPassword.trim() || undefined,
        });
      } else {
        await userService.createUser({
          dni: formDni.trim(),
          nombres: formNombres.trim(),
          apellidos: formApellidos.trim(),
          sexo: formSexo,
          fechaNacimiento: formFechaNacimiento,
          email: formEmail.trim(),
          telefono: formTelefono.trim(),
          rol: formRol,
          categoria: isPromoter ? formCategoria : undefined,
          password: formPassword.trim() || 'Educca2026*',
        });
      }

      setIsModalOpen(false);
      await loadUsers();
    } catch (err: unknown) {
      setFormError(
        err instanceof Error ? err.message : 'Error al registrar el usuario en el backend'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (id: string) => {
    setError(null);
    try {
      await userService.toggleUserStatus(id);
      await loadUsers();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al cambiar estado del usuario');
    }
  };

  const filteredUsers = users.filter(u => {
    const matchesSearch =
      u.dni.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.nombres.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.apellidos.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesRole =
      roleFilter === 'ALL' ||
      u.rol === roleFilter ||
      (roleFilter === 'coordinador' && (u.rol === 'admin' || u.roles?.includes('admin') || u.roles?.includes('coordinador'))) ||
      (roleFilter === 'capacitador' && u.roles?.includes('capacitador')) ||
      (roleFilter === 'promotor' && (u.rol === 'capacitando' || u.roles?.includes('capacitando')));

    return matchesSearch && matchesRole;
  });

  const getRoleBadge = (user: User) => {
    switch (user.rol) {
      case 'admin':
        return <Badge variant="primary">ADMIN</Badge>;
      case 'coordinador':
        return <Badge variant="primary">COORDINADOR</Badge>;
      case 'capacitador':
        return <Badge variant="info">Capacitador</Badge>;
      case 'consulta':
        return <Badge variant="neutral">Consulta</Badge>;
      case 'promotor':
      case 'capacitando':
        return <Badge variant="warning">{user.categoria || 'Promotor'}</Badge>;
      default:
        return <Badge variant="neutral">{user.rol}</Badge>;
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Directorio de Usuarios</h1>
          <p className={styles.subtitle}>
            Gestión de personas, coordinadores, capacitadores y promotores registrados en PostgreSQL
          </p>
        </div>
        {!isReadOnly && (
          <Button
            variant="primary"
            icon={<Plus size={16} />}
            onClick={handleOpenCreateModal}
          >
            Nuevo Usuario
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
            <option value="promotor">Promotores / Capacitandos</option>
            <option value="consulta">Consulta</option>
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
          ...(isReadOnly ? [] : ['Acciones']),
        ]}
        isLoading={isLoading}
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
              {user.fechaNacimiento && (
                <div style={{ fontSize: '11px', color: '#94A3B8' }}>
                  Sexo: {user.sexo || 'M'} • Nac: {user.fechaNacimiento}
                </div>
              )}
            </td>
            <td>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  fontSize: '12px',
                  color: '#475569',
                }}
              >
                <Mail size={12} />
                <span>{user.email || 'Sin correo'}</span>
              </div>
              {user.telefono && (
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    fontSize: '11px',
                    color: '#94A3B8',
                  }}
                >
                  <Phone size={11} />
                  <span>{user.telefono}</span>
                </div>
              )}
            </td>
            <td>{getRoleBadge(user)}</td>
            <td>
              <Badge variant={user.activo ? 'success' : 'neutral'} withDot>
                {user.activo ? 'Activo' : 'Inactivo'}
              </Badge>
            </td>
            {!isReadOnly && (
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
            )}
          </tr>
        ))}
      </Table>

      {/* Create / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingUser ? 'Editar Persona y Perfil RBAC' : 'Registrar Nueva Persona'}
        footer={
          <>
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsModalOpen(false)}
              disabled={isSubmitting}
            >
              Cancelar
            </Button>
            <Button type="submit" form="user-form" disabled={isSubmitting}>
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
        <form id="user-form" onSubmit={handleSaveUser}>
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
              label="DNI / Documento"
              value={formDni}
              onChange={e =>
                setFormDni(e.target.value.replace(/[^0-9A-Za-z-]/g, '').slice(0, 15))
              }
              placeholder="8 a 15 caracteres"
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
            <Select
              label="Sexo"
              value={formSexo}
              onChange={e => setFormSexo(e.target.value as 'M' | 'F')}
              required
            >
              <option value="M">Masculino (M)</option>
              <option value="F">Femenino (F)</option>
            </Select>

            <Input
              label="Fecha de nacimiento (>= 18 años)"
              type="date"
              value={formFechaNacimiento}
              onChange={e => setFormFechaNacimiento(e.target.value)}
              required
            />
          </div>

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

          <Input
            label={editingUser ? 'Nueva contraseña (opcional)' : 'Contraseña inicial'}
            type="password"
            value={formPassword}
            onChange={e => setFormPassword(e.target.value)}
            placeholder={
              editingUser ? 'Dejar en blanco para mantener actual' : 'Mínimo 8 caracteres'
            }
            helper={
              editingUser
                ? 'Mínimo 8 caracteres si desea restablecer la contraseña'
                : 'Por defecto: Educca2026*'
            }
          />

          <div
            style={{
              display: 'grid',
              gridTemplateColumns:
                formRol === 'promotor' || formRol === 'capacitando' ? '1fr 1fr' : '1fr',
              gap: '12px',
            }}
          >
            <Select
              label="Perfil / Rol RBAC asignado"
              value={formRol}
              onChange={e => setFormRol(e.target.value as UserRole)}
            >
              <option value="capacitador">Capacitador Ambiental</option>
              <option value="coordinador">Coordinador Municipal</option>
              <option value="promotor">Promotor / Capacitando</option>
              <option value="consulta">Consulta (Solo lectura)</option>
              <option value="admin">Administrador del Sistema</option>
            </Select>

            {(formRol === 'promotor' || formRol === 'capacitando') && (
              <Select
                label="Categoría ciudadana"
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
