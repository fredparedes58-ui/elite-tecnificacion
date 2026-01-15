import React from 'react';
import Navbar from './Navbar';
import BottomNav from './BottomNav';
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
      <main className="pt-16 pb-20 md:pb-0">
        {children}
      </main>
      <BottomNav />
    </div>
  );
};

export default Layout;
