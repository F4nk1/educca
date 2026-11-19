import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { User, UserRole } from '../models/types';
import { authService } from '../services/authService';
import { apiClient } from '../services/apiClient';

interface AuthContextType {
  user: User | null;
  role: UserRole;
  isDemoMode: boolean;
  isLoading: boolean;
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

    // Check existing session
    authService
      .initSession()
      .then(usr => setUser(usr))
      .finally(() => setIsLoading(false));
  }, [logout]);

  const login = async (identificador: string, password?: string, demoRole?: UserRole): Promise<User> => {
    try {
      const loggedUser = await authService.login(identificador, password, demoRole);
      setUser(loggedUser);
      return loggedUser;
    } catch (err) {
      throw err;
    }
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
    setUser(authService.getCurrentUser());
  };

  const role: UserRole = user ? user.rol : 'coordinador';

  return (
    <AuthContext.Provider
      value={{
        user,
        role,
        isDemoMode,
        isLoading,
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
