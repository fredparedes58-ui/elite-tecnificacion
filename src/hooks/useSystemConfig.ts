import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

interface SystemConfigItem {
  id: string;
  key: string;
  value: Record<string, unknown>;
  description: string | null;
  created_at: string | null;
  updated_at: string | null;
}

interface SystemConfig {
  session_hours: { start: number; end: number };
  max_capacity: { value: number };
  active_days: { days: number[] };
  credit_alert_threshold: { value: number };
  cancellation_window: { hours: number };
}

const defaultConfig: SystemConfig = {
  session_hours: { start: 8, end: 21 },
  max_capacity: { value: 6 },
  active_days: { days: [1, 2, 3, 4, 5, 6] },
  credit_alert_threshold: { value: 3 },
  cancellation_window: { hours: 24 },
};

export const useSystemConfig = () => {
  const [config, setConfig] = useState<SystemConfig>(defaultConfig);
  const [rawConfig, setRawConfig] = useState<SystemConfigItem[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchConfig = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('system_config')
        .select('*');

      if (error) throw error;

      if (data) {
        setRawConfig(data as unknown as SystemConfigItem[]);
        
        const configMap: Partial<SystemConfig> = {};
        for (const item of data) {
          const typedItem = item as { key: string; value: unknown };
          if (typedItem.key in defaultConfig) {
            (configMap as Record<string, unknown>)[typedItem.key] = typedItem.value;
          }
        }
        
        setConfig({ ...defaultConfig, ...configMap } as SystemConfig);
      }
    } catch (err) {
      console.error('Error fetching system config:', err);
    } finally {
      setLoading(false);
    }
  };

  const updateConfig = async (key: keyof SystemConfig, value: SystemConfig[keyof SystemConfig]) => {
    try {
      const { error } = await supabase
        .from('system_config')
        .update({ value, updated_at: new Date().toISOString() })
        .eq('key', key);

      if (error) throw error;
      
      await fetchConfig();
      return true;
    } catch (err) {
      console.error('Error updating system config:', err);
      return false;
    }
  };

  useEffect(() => {
    fetchConfig();
  }, []);

  return {
    config,
    rawConfig,
    loading,
    updateConfig,
    refetch: fetchConfig,
  };
};
