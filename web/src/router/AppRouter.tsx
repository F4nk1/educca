import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
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

const CoordinatorGuard: React.FC = () => {
  const { isCoordinator } = useAuth();
  if (!isCoordinator) {
    return <Navigate to="/trainer/qr" replace />;
  }
  return <Outlet />;
};

const TrainerGuard: React.FC = () => {
  const { isTrainer } = useAuth();
  if (!isTrainer) {
    return <Navigate to="/coordinator" replace />;
  }
  return <Outlet />;
};

export const AppRouter: React.FC = () => {
  const { user, isLoading, isCoordinator } = useAuth();

  if (isLoading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#F8FAFC',
        }}
      >
        <div style={{ textAlign: 'center', color: '#176B53', fontWeight: 600 }}>
          <span>Iniciando plataforma EDUCCA Cusco...</span>
        </div>
      </div>
    );
  }

  const defaultRoute = isCoordinator ? '/coordinator' : '/trainer/qr';

  return (
    <BrowserRouter>
      <Routes>
        {/* Auth Route (W01) */}
        <Route
          path="/login"
          element={user ? <Navigate to={defaultRoute} replace /> : <Login />}
        />

        {/* Protected Application Routes */}
        <Route element={user ? <Layout /> : <Navigate to="/login" replace />}>
          {/* Coordinator Routes (protected by CoordinatorGuard) */}
          <Route element={<CoordinatorGuard />}>
            <Route path="/coordinator" element={<CoordinatorHome />} />
            <Route path="/coordinator/venues" element={<VenuesList />} />
            <Route path="/coordinator/workshops" element={<WorkshopsList />} />
            <Route path="/coordinator/workshops/create" element={<WorkshopCreate />} />
            <Route path="/coordinator/sessions" element={<SessionsList />} />
            <Route path="/coordinator/attendances" element={<GlobalAttendances />} />
            <Route path="/coordinator/users" element={<UsersList />} />
          </Route>

          {/* Trainer Routes (protected by TrainerGuard) */}
          <Route element={<TrainerGuard />}>
            <Route path="/trainer/qr" element={<TrainerQRPanel />} />
            <Route path="/trainer/attendances" element={<TrainerAttendances />} />
          </Route>
        </Route>

        {/* Fallback route */}
        <Route
          path="*"
          element={<Navigate to={user ? defaultRoute : '/login'} replace />}
        />
      </Routes>
    </BrowserRouter>
  );
};
