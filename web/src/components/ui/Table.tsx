import React from 'react';
import { Inbox, Loader2 } from 'lucide-react';
import styles from './Table.module.css';

interface TableProps {
  headers: React.ReactNode[];
  children: React.ReactNode;
  emptyMessage?: string;
  loadingMessage?: string;
  isEmpty?: boolean;
  isLoading?: boolean;
}

export const Table: React.FC<TableProps> = ({
  headers,
  children,
  emptyMessage = 'No se encontraron registros',
  loadingMessage = 'Cargando registros...',
  isEmpty = false,
  isLoading = false,
}) => {
  return (
    <div className={styles.tableContainer}>
      <table className={styles.table}>
        <thead>
          <tr>
            {headers.map((header, idx) => (
              <th key={idx}>{header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {isLoading ? (
            <tr>
              <td colSpan={headers.length}>
                <div className={styles.emptyState}>
                  <Loader2 size={28} className={`${styles.emptyIcon} animate-spin`} />
                  <span>{loadingMessage}</span>
                </div>
              </td>
            </tr>
          ) : isEmpty ? (
            <tr>
              <td colSpan={headers.length}>
                <div className={styles.emptyState}>
                  <Inbox size={32} className={styles.emptyIcon} />
                  <span>{emptyMessage}</span>
                </div>
              </td>
            </tr>
          ) : (
            children
          )}
        </tbody>
      </table>
    </div>
  );
};
