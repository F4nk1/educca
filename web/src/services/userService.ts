import { User, UserRole, PromoterCategory, GoPersona } from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { MOCK_USERS } from '../data/mock/users';

class UserService {
  private mockUsers: User[] = [...MOCK_USERS];

  async getUsers(): Promise<User[]> {
    if (authService.isDemo()) {
      return [...this.mockUsers];
    }

    const personas = await apiClient.get<GoPersona[]>('/personas');
    return personas.map(this.mapGoPersonaToUser);
  }

  async getUserById(id: string): Promise<User | undefined> {
    if (authService.isDemo()) {
      return this.mockUsers.find(u => u.id === id);
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const persona = await apiClient.get<GoPersona>(`/personas/${numId}`);
    return this.mapGoPersonaToUser(persona);
  }

  async createUser(userData: {
    dni: string;
    nombres: string;
    apellidos: string;
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
        activo: true,
        fechaCreacion: new Date().toISOString().split('T')[0],
      };
      this.mockUsers.unshift(newUser);
      return newUser;
    }

    // Go Backend Persona Creation
    const payload = {
      dni: userData.dni,
      nombres: userData.nombres,
      apellidos: userData.apellidos,
      sexo: 'M', // Default gender
      fecha_nacimiento: '1995-01-01', // Default adult age
      telefono: userData.telefono || null,
      email: userData.email,
      categoria: userData.rol === 'promotor' ? (userData.categoria || 'PAC') : null,
      password: userData.password || 'Educca2026*',
      activo: true,
    };

    const res = await apiClient.post<{ id: number }>('/personas', payload);

    return {
      id: res.id.toString(),
      dni: userData.dni,
      nombres: userData.nombres,
      apellidos: userData.apellidos,
      email: userData.email,
      telefono: userData.telefono || '',
      rol: userData.rol,
      categoria: userData.categoria,
      activo: true,
      fechaCreacion: new Date().toISOString().split('T')[0],
    };
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User | null> {
    if (authService.isDemo()) {
      const index = this.mockUsers.findIndex(u => u.id === id);
      if (index === -1) return null;
      this.mockUsers[index] = { ...this.mockUsers[index], ...updates };
      return this.mockUsers[index];
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const existing = await apiClient.get<GoPersona>(`/personas/${numId}`);

    const payload = {
      dni: updates.dni ?? existing.dni,
      nombres: updates.nombres ?? existing.nombres,
      apellidos: updates.apellidos ?? existing.apellidos,
      sexo: existing.sexo,
      fecha_nacimiento: existing.fecha_nacimiento.slice(0, 10),
      telefono: updates.telefono ?? existing.telefono,
      email: updates.email ?? existing.email,
      categoria: updates.categoria ?? existing.categoria,
      activo: updates.activo ?? existing.activo,
    };

    await apiClient.put(`/personas/${numId}`, payload);
    return this.mapGoPersonaToUser({ ...existing, ...payload });
  }

  async toggleUserStatus(id: string): Promise<User | null> {
    if (authService.isDemo()) {
      const user = this.mockUsers.find(u => u.id === id);
      if (!user) return null;
      user.activo = !user.activo;
      return user;
    }

    const numId = parseInt(id.replace('usr-', ''), 10) || id;
    const existing = await apiClient.get<GoPersona>(`/personas/${numId}`);
    const newStatus = !existing.activo;

    await apiClient.patch(`/personas/${numId}/activo`, { activo: newStatus });
    return this.mapGoPersonaToUser({ ...existing, activo: newStatus });
  }

  private mapGoPersonaToUser(p: GoPersona): User {
    let rol: UserRole = 'promotor';
    if (p.categoria) {
      rol = 'promotor';
    }

    return {
      id: p.id.toString(),
      dni: p.dni,
      nombres: p.nombres,
      apellidos: p.apellidos,
      email: p.email || '',
      telefono: p.telefono || '',
      rol,
      categoria: p.categoria as PromoterCategory,
      activo: p.activo,
      fechaCreacion: p.consentimiento_at ? p.consentimiento_at.slice(0, 10) : '2026-01-01',
    };
  }
}

export const userService = new UserService();
