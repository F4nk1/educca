import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { User, UserRole } from '../models/types';
import { authService } from '../services/authService';
import { apiClient } from '../services/apiClient';

interface AuthContextType {
  user: User | null;
  role: UserRole;
  isCoordinator: boolean;
  isTrainer: boolean;
  isReadOnly: boolean;
  isDemoMode: boolean;
  isLoading: boolean;
  hasPermission: (permiso: string) => boolean;
  login: (identificador: string, password?: string, demoRole?: UserRole) => Promise<User>;
  logout: () => void;
  switchRole: (role: UserRole) => void;
  toggleDemoMode: (enabled: boolean) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => authService.getCurrentUser());
  const [isDemoMode, setIsDemoMode] = useState<boolean>(() => authService.isDemo());
  const [isLoading, setIsLoading] = useState<boolean>(true);

  const logout = useCallback(() => {
    authService.logout();
    setUser(null);
  }, []);

  useEffect(() => {
    apiClient.setOnUnauthorized(() => {
      logout();
    });

    authService
      .initSession()
      .then(usr => setUser(usr))
      .finally(() => setIsLoading(false));
  }, [logout]);

  const login = async (
    identificador: string,
    password?: string,
    demoRole?: UserRole
  ): Promise<User> => {
    const loggedUser = await authService.login(identificador, password, demoRole);
    setUser(loggedUser);
    return loggedUser;
  };

  const switchRole = (newRole: UserRole) => {
    if (isDemoMode) {
      const switchedUser = authService.switchDemoRole(newRole);
      setUser(switchedUser);
    }
  };

  const toggleDemoMode = (enabled: boolean) => {
    authService.setDemoMode(enabled);
    setIsDemoMode(enabled);
    if (enabled) {
      setUser(authService.getCurrentUser());
    } else {
      authService.initSession().then(usr => setUser(usr));
    }
  };

  const role: UserRole = user ? user.rol : 'consulta';

  const isCoordinator = Boolean(
    user &&
      (user.rol === 'admin' ||
        user.rol === 'coordinador' ||
        user.rol === 'consulta' ||
        (user.roles &&
          (user.roles.includes('admin') ||
            user.roles.includes('coordinador') ||
            user.roles.includes('consulta'))))
  );

  const isTrainer = Boolean(
    user &&
      (user.rol === 'capacitador' ||
        user.rol === 'admin' ||
        user.rol === 'coordinador' ||
        (user.roles &&
          (user.roles.includes('capacitador') ||
            user.roles.includes('admin') ||
            user.roles.includes('coordinador'))))
  );

  const isReadOnly = Boolean(
    user &&
      user.rol === 'consulta' &&
      !user.roles?.includes('admin') &&
      !user.roles?.includes('coordinador')
  );

  const hasPermission = useCallback(
    (permiso: string): boolean => {
      if (!user) return false;
      if (isDemoMode) return !isReadOnly;
      if (user.rol === 'admin' || user.roles?.includes('admin')) return true;
      if (user.permisos && user.permisos.length > 0) {
        return user.permisos.includes(permiso);
      }
      return !isReadOnly;
    },
    [user, isDemoMode, isReadOnly]
  );

  return (
    <AuthContext.Provider
      value={{
        user,
        role,
        isCoordinator,
        isTrainer,
        isReadOnly,
        isDemoMode,
        isLoading,
        hasPermission,
        login,
        logout,
        switchRole,
        toggleDemoMode,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
