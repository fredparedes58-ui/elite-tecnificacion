import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface CreditPackage {
  id: string;
  name: string;
  credits: number;
  price: number;
  description: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export const useCreditPackages = () => {
  const { isAdmin } = useAuth();
  const [packages, setPackages] = useState<CreditPackage[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchPackages = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('credit_packages')
        .select('*')
        .order('credits', { ascending: true });

      if (error) throw error;
      setPackages(data || []);
    } catch (err) {
      console.error('Error fetching credit packages:', err);
    } finally {
      setLoading(false);
    }
  };

  const createPackage = async (packageData: Omit<CreditPackage, 'id' | 'created_at' | 'updated_at'>) => {
    if (!isAdmin) return null;
    
    try {
      const { data, error } = await supabase
        .from('credit_packages')
        .insert(packageData)
        .select()
        .single();

      if (error) throw error;
      await fetchPackages();
      return data;
    } catch (err) {
      console.error('Error creating package:', err);
      return null;
    }
  };

  const updatePackage = async (id: string, updates: Partial<CreditPackage>) => {
    if (!isAdmin) return false;
    
    try {
      const { error } = await supabase
        .from('credit_packages')
        .update(updates)
        .eq('id', id);

      if (error) throw error;
      await fetchPackages();
      return true;
    } catch (err) {
      console.error('Error updating package:', err);
      return false;
    }
  };

  const deletePackage = async (id: string) => {
    if (!isAdmin) return false;
    
    try {
      // Soft delete - set is_active to false
      const { error } = await supabase
        .from('credit_packages')
        .update({ is_active: false })
        .eq('id', id);

      if (error) throw error;
      await fetchPackages();
      return true;
    } catch (err) {
      console.error('Error deleting package:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchPackages();
  }, []);

  return {
    packages,
    activePackages: packages.filter(p => p.is_active),
    loading,
    createPackage,
    updatePackage,
    deletePackage,
    refetch: fetchPackages,
  };
};

export default useCreditPackages;
