import React from 'react';
import { Outlet } from 'react-router-dom';
import { Navbar } from './Navbar';
import styles from './Layout.module.css';

export const Layout: React.FC = () => {
  return (
    <div className={styles.layout}>
      <Navbar />
      <main className={styles.main}>
        <Outlet />
      </main>
      <footer className={styles.footer}>
        <div className={styles.footerContent}>
          <span>Programa Municipal EDUCCA — Municipalidad Provincial del Cusco</span>
          <span>Plataforma de Gestión de Capacitaciones Ambientales</span>
        </div>
      </footer>
    </div>
  );
};
