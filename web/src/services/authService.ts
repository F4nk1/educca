import { User, UserRole, GoToken, GoMeResponse } from '../models/types';
import { apiClient } from './apiClient';
import { MOCK_USERS } from '../data/mock/users';

const DATA_MODE_KEY = 'educca_data_mode';

export class AuthService {
  private currentUser: User | null = null;
  private isDemoMode: boolean = false;

  constructor() {
    const savedMode = localStorage.getItem(DATA_MODE_KEY);
    const defaultMode = import.meta.env.VITE_DEFAULT_DATA_MODE || 'api';
    this.isDemoMode = savedMode ? savedMode === 'demo' : defaultMode === 'demo';

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
    if (demo) {
      this.currentUser = MOCK_USERS[0];
      sessionStorage.setItem('educca_current_user', JSON.stringify(this.currentUser));
    } else {
      // Returning to real API mode: only preserve user if a real JWT exists
      if (!apiClient.getAccessToken()) {
        this.currentUser = null;
        sessionStorage.removeItem('educca_current_user');
      }
    }
  }

  getCurrentUser(): User | null {
    return this.currentUser;
  }

  async initSession(): Promise<User | null> {
    if (this.isDemoMode) {
      if (!this.currentUser || !this.currentUser.id.startsWith('usr-')) {
        this.currentUser = MOCK_USERS[0];
        sessionStorage.setItem('educca_current_user', JSON.stringify(this.currentUser));
      }
      return this.currentUser;
    }

    const token = apiClient.getAccessToken();
    if (!token) {
      this.currentUser = null;
      sessionStorage.removeItem('educca_current_user');
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

    const tokens = await apiClient.post<GoToken>('/login', {
      identificador: identificador.trim(),
      password: password || '',
    });

    apiClient.setTokens(tokens.access_token, tokens.refresh_token);

    const meResponse = await apiClient.get<GoMeResponse>('/me');
    const user = this.mapGoMeToUser(meResponse);

    // Block citizen-only accounts ('capacitando') from administrative web portal
    if (
      user.rol === 'capacitando' ||
      user.rol === 'promotor'
    ) {
      this.logout();
      throw new Error(
        'Su cuenta tiene perfil de Participante/Promotor. Por favor utilice la aplicación móvil EcoCapacita para inscribirse y registrar asistencia.'
      );
    }

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

    let primaryRole: UserRole = 'capacitando';
    if (roles.includes('admin')) {
      primaryRole = 'admin';
    } else if (roles.includes('coordinador')) {
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
      sexo: p.sexo === 'F' ? 'F' : 'M',
      fechaNacimiento: p.fecha_nacimiento ? p.fecha_nacimiento.slice(0, 10) : undefined,
      email: p.email || '',
      telefono: p.telefono || '',
      rol: primaryRole,
      roles,
      permisos: me.permisos || [],
      categoria: p.categoria,
      activo: p.activo,
    };
  }
}

export const authService = new AuthService();
