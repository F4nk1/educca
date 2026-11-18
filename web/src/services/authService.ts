import { User, UserRole, GoToken, GoMeResponse } from '../models/types';
import { apiClient } from './apiClient';
import { MOCK_USERS } from '../data/mock/users';

const DATA_MODE_KEY = 'educca_data_mode';

export class AuthService {
  private currentUser: User | null = null;
  private isDemoMode: boolean = false;

  constructor() {
    const savedMode = localStorage.getItem(DATA_MODE_KEY);
    this.isDemoMode = savedMode === 'demo';

    // Restore cached user from session if available
    const cachedUser = sessionStorage.getItem('educca_current_user');
    if (cachedUser) {
      try {
        this.currentUser = JSON.parse(cachedUser);
      } catch {
        this.currentUser = null;
      }
    }
  }

  isDemo(): boolean {
    return this.isDemoMode;
  }

  setDemoMode(demo: boolean) {
    this.isDemoMode = demo;
    localStorage.setItem(DATA_MODE_KEY, demo ? 'demo' : 'api');
    if (demo && !this.currentUser) {
      this.currentUser = MOCK_USERS[0];
      sessionStorage.setItem('educca_current_user', JSON.stringify(this.currentUser));
    }
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  async initSession(): Promise<User | null> {
    if (this.isDemoMode) {
      if (!this.currentUser) {
        this.currentUser = MOCK_USERS[0];
      }
      return this.currentUser;
    }

    const token = apiClient.getAccessToken();
    if (!token) {
      this.currentUser = null;
      return null;
    }

    try {
      const meResponse = await apiClient.get<GoMeResponse>('/me');
      const user = this.mapGoMeToUser(meResponse);
      this.currentUser = user;
      sessionStorage.setItem('educca_current_user', JSON.stringify(user));
      return user;
    } catch {
      this.logout();
      return null;
    }
  }

  async login(identificador: string, password?: string, demoRole?: UserRole): Promise<User> {
    if (this.isDemoMode) {
      const role = demoRole || 'coordinador';
      const user = MOCK_USERS.find(u => u.rol === role) || MOCK_USERS[0];
      this.currentUser = user;
      sessionStorage.setItem('educca_current_user', JSON.stringify(user));
      return user;
    }

    // Real Go REST API Authentication
    const tokens = await apiClient.post<GoToken>('/login', {
      identificador: identificador.trim(),
      password: password || '',
    });

    apiClient.setTokens(tokens.access_token, tokens.refresh_token);

    const meResponse = await apiClient.get<GoMeResponse>('/me');
    const user = this.mapGoMeToUser(meResponse);

    this.currentUser = user;
    sessionStorage.setItem('educca_current_user', JSON.stringify(user));
    return user;
  }

  logout(): void {
    this.currentUser = null;
    apiClient.clearTokens();
    sessionStorage.removeItem('educca_current_user');
  }

  switchDemoRole(role: UserRole): User {
    const user = MOCK_USERS.find(u => u.rol === role) || MOCK_USERS[0];
    this.currentUser = user;
    sessionStorage.setItem('educca_current_user', JSON.stringify(user));
    return user;
  }

  private mapGoMeToUser(me: GoMeResponse): User {
    const p = me.persona;
    const roles = me.roles || [];

    // Map highest priority role for navigation
    let primaryRole: UserRole = 'capacitando';
    if (roles.includes('admin') || roles.includes('coordinador')) {
      primaryRole = 'coordinador';
    } else if (roles.includes('capacitador')) {
      primaryRole = 'capacitador';
    } else if (roles.includes('consulta')) {
      primaryRole = 'consulta';
    } else if (roles.includes('capacitando')) {
      primaryRole = 'promotor';
    }

    return {
      id: p.id.toString(),
      dni: p.dni,
      nombres: p.nombres,
      apellidos: p.apellidos,
      email: p.email || '',
      telefono: p.telefono || '',
      rol: primaryRole,
      roles: roles,
      permisos: me.permisos || [],
      categoria: p.categoria,
      activo: p.activo,
    };
  }
}

export const authService = new AuthService();
