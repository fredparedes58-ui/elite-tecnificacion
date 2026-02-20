/**
 * Servicio de Push Notifications usando Capacitor Push Notifications (FCM).
 * Registra el dispositivo y guarda el token en Supabase.
 */
import { PushNotifications } from '@capacitor/push-notifications';
import { Capacitor } from '@capacitor/core';
import { supabase } from '@/integrations/supabase/client';

export interface DeviceToken {
  id: string;
  user_id: string;
  device_token: string;
  platform: 'ios' | 'android' | 'web';
  created_at: string;
  updated_at: string;
}

/**
 * Inicializa las Push Notifications.
 * Debe llamarse al inicio de la app (en App.tsx o main.tsx).
 * Solo funciona en plataformas nativas (iOS/Android), no en web.
 */
export async function initializePushNotifications(): Promise<void> {
  // Solo inicializar en plataformas nativas
  if (Capacitor.getPlatform() === 'web') {
    console.log('Push notifications no disponibles en web');
    return;
  }

  try {
    // Solicitar permisos
    let permStatus = await PushNotifications.checkPermissions();

    if (permStatus.receive === 'prompt') {
      permStatus = await PushNotifications.requestPermissions();
    }

    if (permStatus.receive !== 'granted') {
      console.warn('Permisos de notificaciones denegados');
      return;
    }

    // Registrar para recibir notificaciones
    await PushNotifications.register();

    console.log('Push notifications inicializadas correctamente');
  } catch (error) {
    console.error('Error inicializando push notifications:', error);
    throw error;
  }
}

/**
 * Registra el dispositivo del usuario actual en Supabase.
 * Obtiene el token de FCM y lo guarda en la tabla device_tokens.
 * Debe llamarse después de que el usuario inicie sesión.
 * 
 * IMPORTANTE: Esta función debe llamarse una sola vez y configurará los listeners.
 * Los listeners se ejecutarán automáticamente cuando se reciba el token.
 */
export function setupDeviceTokenRegistration(userId: string): void {
  // Solo funciona en plataformas nativas
  if (Capacitor.getPlatform() === 'web') {
    console.log('Registro de tokens no disponible en web');
    return;
  }

  // Escuchar cuando se recibe el token
  PushNotifications.addListener('registration', async (token) => {
    const deviceToken = token.value;
    
    if (!deviceToken) {
      console.warn('No se pudo obtener el token del dispositivo');
      return;
    }

    try {
      // Detectar la plataforma
      const platform = Capacitor.getPlatform() === 'ios' ? 'ios' : 'android';

      // Verificar si ya existe un token para este usuario y dispositivo
      const { data: existingToken } = await supabase
        .from('device_tokens')
        .select('id')
        .eq('user_id', userId)
        .eq('device_token', deviceToken)
        .maybeSingle();

      if (existingToken) {
        // Actualizar fecha de actualización
        await supabase
          .from('device_tokens')
          .update({ updated_at: new Date().toISOString() })
          .eq('id', existingToken.id);
        console.log('Token de dispositivo actualizado');
        return;
      }

      // Insertar nuevo token
      const { error } = await supabase
        .from('device_tokens')
        .insert({
          user_id: userId,
          device_token: deviceToken,
          platform,
        });

      if (error) {
        console.error('Error guardando token de dispositivo:', error);
        throw error;
      }

      console.log('Token de dispositivo registrado correctamente');
    } catch (error) {
      console.error('Error guardando token:', error);
    }
  });

  // Manejar errores de registro
  PushNotifications.addListener('registrationError', (error) => {
    console.error('Error en registro de push notifications:', error);
  });
}

/**
 * Registra el dispositivo del usuario actual en Supabase.
 * Versión simplificada que configura los listeners automáticamente.
 */
export async function registerDeviceToken(userId: string): Promise<void> {
  setupDeviceTokenRegistration(userId);
}

/**
 * Elimina el token del dispositivo cuando el usuario cierra sesión.
 */
export async function unregisterDeviceToken(userId: string, deviceToken: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('device_tokens')
      .delete()
      .eq('user_id', userId)
      .eq('device_token', deviceToken);

    if (error) {
      console.error('Error eliminando token de dispositivo:', error);
      throw error;
    }

    console.log('Token de dispositivo eliminado');
  } catch (error) {
    console.error('Error eliminando token de dispositivo:', error);
    throw error;
  }
}

/**
 * Configura listeners para recibir notificaciones cuando la app está abierta.
 */
export function setupPushNotificationListeners(
  onNotificationReceived?: (notification: any) => void,
  onNotificationActionPerformed?: (action: any) => void
): void {
  if (Capacitor.getPlatform() === 'web') {
    return;
  }

  // Listener para cuando se recibe una notificación mientras la app está abierta
  PushNotifications.addListener('pushNotificationReceived', (notification) => {
    console.log('Notificación recibida:', notification);
    onNotificationReceived?.(notification);
  });

  // Listener para cuando el usuario toca una notificación
  PushNotifications.addListener('pushNotificationActionPerformed', (action) => {
    console.log('Acción de notificación:', action);
    onNotificationActionPerformed?.(action);
  });
}

/**
 * Obtiene todos los tokens de dispositivo de un usuario.
 */
export async function getUserDeviceTokens(userId: string): Promise<DeviceToken[]> {
  const { data, error } = await supabase
    .from('device_tokens')
    .select('*')
    .eq('user_id', userId);

  if (error) {
    console.error('Error obteniendo tokens de dispositivo:', error);
    throw error;
  }

  return (data || []) as DeviceToken[];
}
