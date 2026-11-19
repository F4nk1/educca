import { User, UserRole, PromoterCategory, GoPersona, GoRol } from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { MOCK_USERS } from '../data/mock/users';

// Seed role IDs from database/data/01_rol.sql
const SEED_ROLE_IDS: Record<string, number> = {
  admin: 1,
  coordinador: 2,
  capacitador: 3,
  capacitando: 4,
  promotor: 4,
  consulta: 5,
};

class UserService {
  private mockUsers: User[] = [...MOCK_USERS];
  private cachedRolesMap: Record<string, number> | null = null;

  private async resolveRoleId(roleName: UserRole): Promise<number> {
    const backendName = roleName === 'promotor' ? 'capacitando' : roleName;
    if (!this.cachedRolesMap) {
      try {
        const roles = await apiClient.get<GoRol[]>('/roles');
        const map: Record<string, number> = { ...SEED_ROLE_IDS };
        roles.forEach(r => {
          map[r.nombre] = r.id;
        });
        this.cachedRolesMap = map;
      } catch {
        this.cachedRolesMap = { ...SEED_ROLE_IDS };
      }
    }
    return this.cachedRolesMap[backendName] || SEED_ROLE_IDS[backendName] || 3;
  }

  async getUsers(): Promise<User[]> {
    if (authService.isDemo()) {
      return [...this.mockUsers];
    }

    const personas = await apiClient.get<GoPersona[]>('/personas');
    const usersWithRoles = await Promise.all(
      personas.map(async p => {
        const roles = await apiClient
          .get<GoRol[]>(`/personas/${p.id}/roles`)
          .then(list => list.map(r => r.nombre))
          .catch(() => [] as string[]);
        return this.mapGoPersonaToUser(p, roles);
      })
    );
    return usersWithRoles;
  }

  async getUserById(id: string): Promise<User | undefined> {
    if (authService.isDemo()) {
      return this.mockUsers.find(u => u.id === id);
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const [persona, roles] = await Promise.all([
      apiClient.get<GoPersona>(`/personas/${numId}`),
      apiClient
        .get<GoRol[]>(`/personas/${numId}/roles`)
        .then(list => list.map(r => r.nombre))
        .catch(() => [] as string[]),
    ]);
    return this.mapGoPersonaToUser(persona, roles);
  }

  async createUser(userData: {
    dni: string;
    nombres: string;
    apellidos: string;
    sexo: 'M' | 'F';
    fechaNacimiento: string;
    email: string;
    telefono?: string;
    rol: UserRole;
    categoria?: PromoterCategory;
    password?: string;
  }): Promise<User> {
    if (authService.isDemo()) {
      const newUser: User = {
        ...userData,
        id: `usr-${Date.now()}`,
        telefono: userData.telefono || '',
        roles: [userData.rol === 'promotor' ? 'capacitando' : userData.rol],
        activo: true,
        fechaCreacion: new Date().toISOString().split('T')[0],
      };
      this.mockUsers.unshift(newUser);
      return newUser;
    }

    const isPromoter = userData.rol === 'promotor' || userData.rol === 'capacitando';

    const payload = {
      dni: userData.dni.trim(),
      nombres: userData.nombres.trim(),
      apellidos: userData.apellidos.trim(),
      sexo: userData.sexo || 'M',
      fecha_nacimiento: userData.fechaNacimiento || '1995-01-01',
      telefono: userData.telefono?.trim() || null,
      email: userData.email.trim(),
      categoria: isPromoter ? userData.categoria || 'PAC' : null,
      password: userData.password || 'Educca2026*',
      activo: true,
    };

    const res = await apiClient.post<{ id: number }>('/personas', payload);

    // Assign selected RBAC role in backend
    const targetRolId = await this.resolveRoleId(userData.rol);
    await apiClient
      .post(`/personas/${res.id}/roles`, { rol_id: targetRolId })
      .catch(() => {
        // Fallback if current user lacks roles:gestionar permission
      });

    return {
      id: res.id.toString(),
      dni: payload.dni,
      nombres: payload.nombres,
      apellidos: payload.apellidos,
      sexo: userData.sexo,
      fechaNacimiento: userData.fechaNacimiento,
      email: payload.email,
      telefono: userData.telefono || '',
      rol: userData.rol,
      roles: [isPromoter ? 'capacitando' : userData.rol],
      categoria: isPromoter ? userData.categoria : undefined,
      activo: true,
      fechaCreacion: new Date().toISOString().split('T')[0],
    };
  }

  async updateUser(
    id: string,
    updates: Partial<User> & { password?: string }
  ): Promise<User | null> {
    if (authService.isDemo()) {
      const index = this.mockUsers.findIndex(u => u.id === id);
      if (index === -1) return null;
      this.mockUsers[index] = { ...this.mockUsers[index], ...updates };
      return this.mockUsers[index];
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const existing = await apiClient.get<GoPersona>(`/personas/${numId}`);
    const isPromoter = updates.rol === 'promotor' || updates.rol === 'capacitando';

    const payload = {
      dni: (updates.dni ?? existing.dni).trim(),
      nombres: (updates.nombres ?? existing.nombres).trim(),
      apellidos: (updates.apellidos ?? existing.apellidos).trim(),
      sexo: updates.sexo ?? (existing.sexo === 'F' ? 'F' : 'M'),
      fecha_nacimiento: updates.fechaNacimiento ?? existing.fecha_nacimiento.slice(0, 10),
      telefono: (updates.telefono ?? existing.telefono)?.trim() || null,
      email: (updates.email ?? existing.email)?.trim() || null,
      categoria: isPromoter
        ? updates.categoria ?? existing.categoria ?? 'PAC'
        : existing.categoria ?? null,
    };

    await apiClient.put(`/personas/${numId}`, payload);

    // Optional password update if provided
    if (updates.password && updates.password.trim().length >= 8) {
      await apiClient.patch(`/personas/${numId}/password`, {
        password: updates.password.trim(),
      });
    }

    // Sync RBAC role if changed
    if (updates.rol) {
      try {
        const currentRoles = await apiClient.get<GoRol[]>(`/personas/${numId}/roles`);
        const targetRolId = await this.resolveRoleId(updates.rol);
        const alreadyHasRole = currentRoles.some(r => r.id === targetRolId);
        if (!alreadyHasRole) {
          await apiClient.post(`/personas/${numId}/roles`, { rol_id: targetRolId });
          for (const oldRole of currentRoles) {
            if (oldRole.id !== targetRolId) {
              await apiClient.delete(`/personas/${numId}/roles/${oldRole.id}`).catch(() => {});
            }
          }
        }
      } catch {
        // Ignore if current user cannot manage roles
      }
    }

    const updatedRoles = await apiClient
      .get<GoRol[]>(`/personas/${numId}/roles`)
      .then(list => list.map(r => r.nombre))
      .catch(() => (updates.rol ? [updates.rol] : []));

    return this.mapGoPersonaToUser(
      {
        ...existing,
        dni: payload.dni,
        nombres: payload.nombres,
        apellidos: payload.apellidos,
        sexo: payload.sexo,
        fecha_nacimiento: payload.fecha_nacimiento,
        telefono: payload.telefono || undefined,
        email: payload.email || undefined,
        categoria: payload.categoria || undefined,
      },
      updatedRoles
    );
  }

  async toggleUserStatus(id: string): Promise<User | null> {
    if (authService.isDemo()) {
      const user = this.mockUsers.find(u => u.id === id);
      if (!user) return null;
      user.activo = !user.activo;
      return user;
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const [existing, roles] = await Promise.all([
      apiClient.get<GoPersona>(`/personas/${numId}`),
      apiClient
        .get<GoRol[]>(`/personas/${numId}/roles`)
        .then(list => list.map(r => r.nombre))
        .catch(() => [] as string[]),
    ]);
    const newStatus = !existing.activo;

    await apiClient.patch(`/personas/${numId}/activo`, { activo: newStatus });
    return this.mapGoPersonaToUser({ ...existing, activo: newStatus }, roles);
  }

  private mapGoPersonaToUser(p: GoPersona, roles: string[] = []): User {
    let rol: UserRole = 'promotor';
    if (roles.includes('admin')) {
      rol = 'admin';
    } else if (roles.includes('coordinador')) {
      rol = 'coordinador';
    } else if (roles.includes('capacitador')) {
      rol = 'capacitador';
    } else if (roles.includes('consulta')) {
      rol = 'consulta';
    } else if (roles.includes('capacitando') || p.categoria) {
      rol = 'promotor';
    } else {
      // Persona created without category and no roles fetched yet
      rol = 'capacitador';
    }

    return {
      id: p.id.toString(),
      dni: p.dni,
      nombres: p.nombres,
      apellidos: p.apellidos,
      sexo: p.sexo === 'F' ? 'F' : 'M',
      fechaNacimiento: p.fecha_nacimiento ? p.fecha_nacimiento.slice(0, 10) : '1995-01-01',
      email: p.email || '',
      telefono: p.telefono || '',
      rol,
      roles,
      categoria: p.categoria as PromoterCategory | undefined,
      activo: p.activo,
      fechaCreacion: p.consentimiento_at ? p.consentimiento_at.slice(0, 10) : '2026-01-01',
    };
  }
}

export const userService = new UserService();
