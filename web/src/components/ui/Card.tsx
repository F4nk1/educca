import React from 'react';
import styles from './Card.module.css';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  padding?: 'sm' | 'md' | 'lg' | 'none';
  header?: React.ReactNode;
  action?: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({
  children,
  padding = 'md',
  header,
  action,
  className = '',
  ...props
}) => {
  const paddingClass = padding !== 'none' ? styles[`padding${padding.charAt(0).toUpperCase() + padding.slice(1)}`] : '';

  return (
    <div className={`${styles.card} ${paddingClass} ${className}`} {...props}>
      {(header || action) && (
        <div className={styles.cardHeader}>
          <div>{header}</div>
          {action && <div>{action}</div>}
        </div>
      )}
      {children}
    </div>
  );
};
