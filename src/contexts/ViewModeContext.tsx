import React, { createContext, useContext, useState, ReactNode } from 'react';

type ViewMode = 'admin' | 'parent';

interface ViewModeContextType {
  viewMode: ViewMode;
  setViewMode: (mode: ViewMode) => void;
  isParentView: boolean;
}

const ViewModeContext = createContext<ViewModeContextType | undefined>(undefined);

export const ViewModeProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [viewMode, setViewMode] = useState<ViewMode>('admin');

  return (
    <ViewModeContext.Provider value={{ 
      viewMode, 
      setViewMode, 
      isParentView: viewMode === 'parent' 
    }}>
      {children}
    </ViewModeContext.Provider>
  );
};

export const useViewMode = () => {
  const context = useContext(ViewModeContext);
  if (context === undefined) {
    throw new Error('useViewMode must be used within a ViewModeProvider');
  }
  return context;
};
