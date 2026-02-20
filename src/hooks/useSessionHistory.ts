import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export interface SessionChange {
  id: string;
  reservation_id: string;
  changed_by: string;
  change_type: string;
  old_value: Record<string, any> | null;
  new_value: Record<string, any> | null;
  description: string | null;
  created_at: string;
  admin_name?: string;
}

export function useSessionHistory(reservationId?: string) {
  return useQuery({
    queryKey: ['session-history', reservationId],
    queryFn: async (): Promise<SessionChange[]> => {
      let query = supabase
        .from('session_changes_history')
        .select(`
          *,
          profiles!session_changes_history_changed_by_fkey(full_name)
        `)
        .order('created_at', { ascending: false });

      if (reservationId) {
        query = query.eq('reservation_id', reservationId);
      }

      const { data, error } = await query.limit(100);

      if (error) {
        console.error('Error fetching session history:', error);
        return [];
      }

      return (data || []).map((item: any) => ({
        id: item.id,
        reservation_id: item.reservation_id,
        changed_by: item.changed_by,
        change_type: item.change_type,
        old_value: item.old_value,
        new_value: item.new_value,
        description: item.description,
        created_at: item.created_at,
        admin_name: item.profiles?.full_name || 'Administrador',
      }));
    },
    enabled: true,
  });
}
