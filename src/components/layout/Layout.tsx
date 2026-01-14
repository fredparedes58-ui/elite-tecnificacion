import React from 'react';
import Navbar from './Navbar';
import { useNotifications } from '@/hooks/useNotifications';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  // Initialize realtime notifications
  useNotifications();

  return (
    <div className="min-h-screen bg-background cyber-grid">
      <Navbar />
      <main className="pt-16">
        {children}
      </main>
    </div>
  );
};

export default Layout;
