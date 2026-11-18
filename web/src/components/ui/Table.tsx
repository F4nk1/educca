import React from 'react';
import { Inbox } from 'lucide-react';
import styles from './Table.module.css';

interface TableProps {
  headers: React.ReactNode[];
  children: React.ReactNode;
  emptyMessage?: string;
  isEmpty?: boolean;
}

export const Table: React.FC<TableProps> = ({
  headers,
  children,
  emptyMessage = 'No se encontraron registros',
  isEmpty = false,
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
          {isEmpty ? (
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
