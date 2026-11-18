import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from '../components/layout/Layout';
import { Login } from '../pages/auth/Login';
import { CoordinatorHome } from '../pages/coordinator/CoordinatorHome';
import { VenuesList } from '../pages/coordinator/VenuesList';
import { WorkshopsList } from '../pages/coordinator/WorkshopsList';
import { WorkshopCreate } from '../pages/coordinator/WorkshopCreate';
import { UsersList } from '../pages/coordinator/UsersList';
import { SessionsList } from '../pages/coordinator/SessionsList';
import { GlobalAttendances } from '../pages/coordinator/GlobalAttendances';
import { TrainerQRPanel } from '../pages/trainer/TrainerQRPanel';
import { TrainerAttendances } from '../pages/trainer/TrainerAttendances';
import { useAuth } from '../hooks/useAuth';

export const AppRouter: React.FC = () => {
  const { user, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#F8FAFC' }}>
        <div style={{ textAlign: 'center', color: '#176B53', fontWeight: 600 }}>
          <span>Iniciando plataforma EDUCCA Cusco...</span>
        </div>
      </div>
    );
  }

  const isCoordinator = user && (user.rol === 'coordinador' || user.rol === 'admin' || (user.roles && (user.roles.includes('admin') || user.roles.includes('coordinador'))));

  return (
    <BrowserRouter>
      <Routes>
        {/* Auth Route (W01) */}
        <Route path="/login" element={user ? <Navigate to={isCoordinator ? '/coordinator' : '/trainer/qr'} replace /> : <Login />} />

        {/* Protected Application Routes */}
        <Route element={user ? <Layout /> : <Navigate to="/login" replace />}>
          {/* Coordinator Routes */}
          <Route path="/coordinator" element={<CoordinatorHome />} />
          <Route path="/coordinator/venues" element={<VenuesList />} />
          <Route path="/coordinator/workshops" element={<WorkshopsList />} />
          <Route path="/coordinator/workshops/create" element={<WorkshopCreate />} />
          <Route path="/coordinator/sessions" element={<SessionsList />} />
          <Route path="/coordinator/attendances" element={<GlobalAttendances />} />
          <Route path="/coordinator/users" element={<UsersList />} />

          {/* Trainer Routes */}
          <Route path="/trainer/qr" element={<TrainerQRPanel />} />
          <Route path="/trainer/attendances" element={<TrainerAttendances />} />
        </Route>

        {/* Fallback route */}
        <Route
          path="*"
          element={<Navigate to={user ? (isCoordinator ? '/coordinator' : '/trainer/qr') : '/login'} replace />}
        />
      </Routes>
    </BrowserRouter>
  );
};
