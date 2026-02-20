import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Demo data arrays
const firstNames = [
  "Carlos", "Miguel", "Andrés", "Santiago", "Mateo", "Sebastián", "Daniel", "Lucas", "Pablo", "Diego",
  "Alejandro", "Gabriel", "Nicolás", "Martín", "David", "Felipe", "Samuel", "Joaquín", "Emilio", "Rafael",
  "Bruno", "Adrián", "Tomás", "Iván", "Hugo", "Óscar", "Álvaro", "Javier", "Manuel", "Francisco",
  "Eduardo", "Rodrigo", "Antonio", "Sergio", "Fernando", "Pedro", "Ricardo", "Mario", "Raúl", "Alberto"
];

const lastNames = [
  "García", "Rodríguez", "Martínez", "López", "González", "Hernández", "Pérez", "Sánchez", "Ramírez", "Torres",
  "Flores", "Rivera", "Gómez", "Díaz", "Cruz", "Morales", "Reyes", "Ortiz", "Gutiérrez", "Chávez",
  "Ramos", "Mendoza", "Ruiz", "Álvarez", "Vargas", "Castillo", "Jiménez", "Romero", "Herrera", "Medina"
];

const positions = ["Portero", "Defensa Central", "Lateral Derecho", "Lateral Izquierdo", "Mediocampista", "Centrocampista Defensivo", "Mediapunta", "Extremo Derecho", "Extremo Izquierdo", "Delantero Centro", "Segundo Delantero"];

const categories: ("U8" | "U10" | "U12" | "U14" | "U16" | "U18")[] = ["U8", "U10", "U12", "U14", "U16", "U18"];
const levels: ("beginner" | "intermediate" | "advanced" | "elite")[] = ["beginner", "intermediate", "advanced", "elite"];

const trainerData = [
  { name: "Roberto Fernández", specialty: "Técnica Individual", bio: "Ex jugador profesional con 15 años de experiencia en formación juvenil.", email: "roberto@elitetraining.com", phone: "+34 612 345 678" },
  { name: "María González", specialty: "Preparación Física", bio: "Licenciada en Ciencias del Deporte, especialista en desarrollo atlético juvenil.", email: "maria@elitetraining.com", phone: "+34 623 456 789" },
  { name: "Carlos Mendoza", specialty: "Táctica y Estrategia", bio: "Entrenador UEFA Pro con experiencia en academias de élite.", email: "carlos@elitetraining.com", phone: "+34 634 567 890" },
  { name: "Ana Martínez", specialty: "Porteros", bio: "Ex portera internacional, especializada en formación de guardametas.", email: "ana@elitetraining.com", phone: "+34 645 678 901" },
  { name: "Javier López", specialty: "Desarrollo Mental", bio: "Psicólogo deportivo con enfoque en rendimiento y mentalidad ganadora.", email: "javier@elitetraining.com", phone: "+34 656 789 012" }
];

const sessionTitles = [
  "Entrenamiento técnico individual",
  "Sesión de velocidad y agilidad",
  "Trabajo táctico posicional",
  "Entrenamiento de finalización",
  "Sesión de pases y control",
  "Trabajo físico específico",
  "Entrenamiento de porteros",
  "Sesión de regates y 1vs1",
  "Preparación mental",
  "Análisis de video y táctica"
];

const chatMessages = [
  "Hola, quisiera saber más sobre los horarios disponibles para mi hijo.",
  "¿Cuándo podemos agendar la próxima sesión?",
  "Mi hijo ha mejorado mucho, gracias por el trabajo.",
  "¿Hay disponibilidad para esta semana?",
  "Necesito cancelar la sesión del viernes.",
  "¿Pueden enviarme el reporte de progreso?",
  "Excelente sesión la de ayer, mi hijo está muy motivado.",
  "¿Cuántos créditos tengo disponibles?",
  "Quisiera agendar 3 sesiones para la próxima semana.",
  "¿Hay algún descuento por paquetes de sesiones?",
  "Mi hijo quiere enfocarse más en la técnica de tiro.",
  "¿Pueden trabajar en la velocidad de mi hijo?",
  "Gracias por todo el apoyo, se nota el progreso.",
  "¿Cuándo es la próxima evaluación?",
  "Me gustaría hablar sobre los objetivos para este mes."
];

const adminResponses = [
  "¡Hola! Claro, tenemos disponibilidad de lunes a viernes de 15:00 a 20:00 y sábados de 9:00 a 14:00.",
  "Podemos agendar para cuando le convenga. ¿Qué día prefiere?",
  "¡Nos alegra mucho escuchar eso! El esfuerzo de su hijo está dando frutos.",
  "Sí, tenemos varios horarios disponibles. Le envío las opciones.",
  "Entendido, queda cancelada. ¿Desea reagendar?",
  "Por supuesto, le preparo el reporte y se lo envío por email.",
  "¡Excelente! Eso nos motiva a seguir trabajando duro.",
  "Puede ver sus créditos en la sección de perfil. Actualmente tiene disponibles.",
  "Perfecto, las agendamos. ¿Prefiere con algún entrenador en específico?",
  "Sí, tenemos paquetes de 10 y 20 sesiones con descuento. Le envío la información.",
  "Claro, podemos enfocar las próximas sesiones en finalización.",
  "Absolutamente, incluiremos ejercicios de velocidad en el plan.",
  "¡Gracias a ustedes por la confianza! Seguimos trabajando.",
  "La próxima evaluación es a fin de mes. Le confirmo la fecha.",
  "Con gusto, podemos coordinar una reunión o llamada cuando prefiera."
];

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomElement<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generateStats(level: string): object {
  const baseStats = {
    beginner: { min: 20, max: 45 },
    intermediate: { min: 40, max: 65 },
    advanced: { min: 60, max: 80 },
    elite: { min: 75, max: 95 }
  };
  const range = baseStats[level as keyof typeof baseStats] || baseStats.beginner;
  
  return {
    speed: randomInt(range.min, range.max),
    technique: randomInt(range.min, range.max),
    physical: randomInt(range.min, range.max),
    tactical: randomInt(range.min, range.max),
    mental: randomInt(range.min, range.max)
  };
}

function generateBirthDate(category: string): string {
  const currentYear = new Date().getFullYear();
  const categoryYears: Record<string, number> = {
    "U8": currentYear - 7,
    "U10": currentYear - 9,
    "U12": currentYear - 11,
    "U14": currentYear - 13,
    "U16": currentYear - 15,
    "U18": currentYear - 17
  };
  const birthYear = categoryYears[category] || currentYear - 10;
  const month = randomInt(1, 12);
  const day = randomInt(1, 28);
  return `${birthYear}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function generateReservationTimes(baseDate: Date, hour: number): { start: string; end: string } {
  const start = new Date(baseDate);
  start.setHours(hour, 0, 0, 0);
  const end = new Date(start);
  end.setHours(hour + 1, 0, 0, 0);
  return {
    start: start.toISOString(),
    end: end.toISOString()
  };
}

const handler = async (req: Request): Promise<Response> => {
  console.log("generate-demo-data function called");

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });

    const results = {
      trainers: 0,
      parents: 0,
      players: 0,
      reservations: 0,
      conversations: 0,
      messages: 0
    };

    // 1. Create trainers
    console.log("Creating trainers...");
    const { data: trainersData, error: trainersError } = await supabase
      .from("trainers")
      .insert(trainerData.map(t => ({ ...t, is_active: true })))
      .select();
    
    if (trainersError) {
      console.error("Error creating trainers:", trainersError);
      throw trainersError;
    }
    results.trainers = trainersData?.length || 0;
    const trainerIds = trainersData?.map(t => t.id) || [];
    console.log(`Created ${results.trainers} trainers`);

    // 2. Get admin user ID (first admin)
    const { data: adminRole } = await supabase
      .from("user_roles")
      .select("user_id")
      .eq("role", "admin")
      .limit(1)
      .single();
    
    const adminId = adminRole?.user_id;
    console.log("Admin ID:", adminId);

    // 3. Create parent users
    console.log("Creating parent users...");
    const parentIds: string[] = [];
    
    for (let i = 0; i < 40; i++) {
      const firstName = randomElement(firstNames);
      const lastName = randomElement(lastNames);
      const email = `parent${i + 1}.${lastName.toLowerCase()}@demo.elitetraining.com`;
      const isApproved = i < 30; // 30 approved, 10 pending
      
      try {
        // Create user in auth
        const { data: authData, error: authError } = await supabase.auth.admin.createUser({
          email,
          password: "Demo123!",
          email_confirm: true,
          user_metadata: {
            full_name: `${firstName} ${lastName}`
          }
        });

        if (authError) {
          console.error(`Error creating user ${email}:`, authError);
          continue;
        }

        if (authData.user) {
          parentIds.push(authData.user.id);
          
          // Update profile approval status
          await supabase
            .from("profiles")
            .update({ 
              is_approved: isApproved,
              phone: `+34 6${randomInt(10, 99)} ${randomInt(100, 999)} ${randomInt(100, 999)}`
            })
            .eq("id", authData.user.id);

          // Add credits for approved users
          if (isApproved) {
            await supabase
              .from("user_credits")
              .update({ balance: randomInt(5, 50) })
              .eq("user_id", authData.user.id);
          }

          results.parents++;
        }
      } catch (err) {
        console.error(`Error processing user ${i}:`, err);
      }
    }
    console.log(`Created ${results.parents} parent users`);

    // 4. Create players (3 players per parent on average = 120 players)
    console.log("Creating players...");
    const playerIds: { id: string; parentId: string }[] = [];
    
    for (const parentId of parentIds) {
      const numPlayers = randomInt(2, 4); // 2-4 players per parent
      
      for (let j = 0; j < numPlayers && results.players < 120; j++) {
        const category = randomElement(categories);
        const level = randomElement(levels);
        
        const playerData = {
          parent_id: parentId,
          name: `${randomElement(firstNames)} ${randomElement(lastNames)}`,
          position: randomElement(positions),
          category,
          level,
          stats: generateStats(level),
          birth_date: generateBirthDate(category),
          notes: Math.random() > 0.5 ? `Jugador con gran potencial en ${randomElement(["velocidad", "técnica", "visión de juego", "liderazgo", "finalización"])}. ${randomElement(["Muy dedicado", "Excelente actitud", "Gran mentalidad", "Muy competitivo"])}.` : null
        };

        const { data: player, error: playerError } = await supabase
          .from("players")
          .insert(playerData)
          .select()
          .single();

        if (playerError) {
          console.error("Error creating player:", playerError);
          continue;
        }

        if (player) {
          playerIds.push({ id: player.id, parentId });
          results.players++;
        }
      }
    }
    console.log(`Created ${results.players} players`);

    // 5. Create reservations for the last month
    console.log("Creating reservations...");
    const now = new Date();
    const oneMonthAgo = new Date(now);
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);
    
    const statuses: ("pending" | "approved" | "completed" | "rejected" | "no_show")[] = 
      ["pending", "approved", "completed", "rejected", "no_show"];
    const statusWeights = [0.1, 0.2, 0.5, 0.1, 0.1]; // 10% pending, 20% approved, 50% completed, 10% rejected, 10% no_show

    for (let day = 0; day < 30; day++) {
      const date = new Date(oneMonthAgo);
      date.setDate(date.getDate() + day);
      
      // Skip weekends for fewer reservations
      if (date.getDay() === 0) continue;
      
      const numReservations = date.getDay() === 6 ? randomInt(8, 12) : randomInt(5, 10);
      
      for (let r = 0; r < numReservations && results.reservations < 250; r++) {
        const playerInfo = randomElement(playerIds);
        const hour = randomInt(7, 20);
        const times = generateReservationTimes(date, hour);
        
        // Determine status based on weights
        const rand = Math.random();
        let cumulative = 0;
        let status: typeof statuses[number] = "completed";
        for (let s = 0; s < statuses.length; s++) {
          cumulative += statusWeights[s];
          if (rand < cumulative) {
            status = statuses[s];
            break;
          }
        }
        
        // Future dates should be pending or approved
        if (date > now) {
          status = Math.random() > 0.3 ? "approved" : "pending";
        }

        const reservationData = {
          user_id: playerInfo.parentId,
          player_id: playerInfo.id,
          trainer_id: Math.random() > 0.2 ? randomElement(trainerIds) : null,
          title: randomElement(sessionTitles),
          description: Math.random() > 0.5 ? `Enfoque en ${randomElement(["técnica", "velocidad", "táctica", "físico", "mental"])}` : null,
          start_time: times.start,
          end_time: times.end,
          status,
          credit_cost: 1
        };

        const { error: resError } = await supabase
          .from("reservations")
          .insert(reservationData);

        if (!resError) {
          results.reservations++;
        }
      }
    }
    console.log(`Created ${results.reservations} reservations`);

    // 6. Create conversations and messages
    console.log("Creating conversations and messages...");
    const conversationParents = parentIds.slice(0, 20); // 20 parents with conversations
    
    for (const parentId of conversationParents) {
      // Create conversation
      const { data: conversation, error: convError } = await supabase
        .from("conversations")
        .insert({
          participant_id: parentId,
          subject: randomElement([
            "Consulta sobre horarios",
            "Progreso del jugador",
            "Reservas y créditos",
            "Información general",
            "Evaluación mensual"
          ])
        })
        .select()
        .single();

      if (convError || !conversation) {
        console.error("Error creating conversation:", convError);
        continue;
      }

      results.conversations++;

      // Create messages in conversation (5-15 messages each)
      const numMessages = randomInt(5, 15);
      const baseTime = new Date();
      baseTime.setDate(baseTime.getDate() - randomInt(1, 20));

      for (let m = 0; m < numMessages; m++) {
        const isParent = m % 2 === 0;
        const messageTime = new Date(baseTime);
        messageTime.setMinutes(messageTime.getMinutes() + m * randomInt(5, 60));

        const { error: msgError } = await supabase
          .from("messages")
          .insert({
            conversation_id: conversation.id,
            sender_id: isParent ? parentId : adminId,
            content: isParent ? randomElement(chatMessages) : randomElement(adminResponses),
            is_read: m < numMessages - 2,
            created_at: messageTime.toISOString()
          });

        if (!msgError) {
          results.messages++;
        }
      }
    }
    console.log(`Created ${results.conversations} conversations with ${results.messages} messages`);

    console.log("Demo data generation complete!", results);

    return new Response(JSON.stringify({ 
      success: true, 
      message: "Datos de demostración creados exitosamente",
      results 
    }), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });

  } catch (error: any) {
    console.error("Error in generate-demo-data:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
};

serve(handler);
