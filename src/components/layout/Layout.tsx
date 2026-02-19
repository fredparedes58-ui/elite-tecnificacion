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
    <div className="min-h-screen bg-background cyber-grid overflow-x-hidden">
      <Navbar />
      <main className="pt-[calc(3.5rem+env(safe-area-inset-top,0px))] md:pt-16 pb-20 md:pb-0 max-w-full overflow-x-hidden px-3 md:px-4">
        {children}
      </main>
      <BottomNav />
    </div>
  );
};

export default Layout;
