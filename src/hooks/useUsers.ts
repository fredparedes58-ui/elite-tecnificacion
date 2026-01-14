import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';

export interface UserProfile {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  phone: string | null;
  is_approved: boolean;
  created_at: string;
  updated_at: string;
  role?: string;
  credits?: number;
}

export const useUsers = () => {
  const { isAdmin } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchUsers = async () => {
    if (!isAdmin) return;

    try {
      setLoading(true);
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      const usersWithDetails = await Promise.all(
        (profiles || []).map(async (profile) => {
          // Get role
          const { data: roles } = await supabase
            .from('user_roles')
            .select('role')
            .eq('user_id', profile.id);

          // Get credits
          const { data: credits } = await supabase
            .from('user_credits')
            .select('balance')
            .eq('user_id', profile.id)
            .single();

          return {
            id: profile.id,
            email: profile.email,
            full_name: profile.full_name,
            avatar_url: profile.avatar_url,
            phone: profile.phone,
            is_approved: (profile as any).is_approved ?? false,
            created_at: profile.created_at,
            updated_at: profile.updated_at,
            role: roles?.[0]?.role || 'parent',
            credits: credits?.balance || 0,
          } as UserProfile;
        })
      );

      setUsers(usersWithDetails);
    } catch (err) {
      console.error('Error fetching users:', err);
    } finally {
      setLoading(false);
    }
  };

  const approveUser = async (userId: string) => {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ is_approved: true, updated_at: new Date().toISOString() })
        .eq('id', userId);

      if (error) throw error;
      await fetchUsers();
      return true;
    } catch (err) {
      console.error('Error approving user:', err);
      return false;
    }
  };

  const updateUserApproval = async (userId: string, isApproved: boolean) => {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ is_approved: isApproved, updated_at: new Date().toISOString() })
        .eq('id', userId);

      if (error) throw error;
      await fetchUsers();
      return true;
    } catch (err) {
      console.error('Error updating user approval:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [isAdmin]);

  return { users, loading, approveUser, updateUserApproval, refetch: fetchUsers };
};
