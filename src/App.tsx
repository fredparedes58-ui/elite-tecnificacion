import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import Index from "./pages/Index";
import Auth from "./pages/Auth";
import Scouting from "./pages/Scouting";
import Dashboard from "./pages/Dashboard";
import Players from "./pages/Players";
import Reservations from "./pages/Reservations";
import Chat from "./pages/Chat";
import MyCredits from "./pages/MyCredits";
import Profile from "./pages/Profile";
import AdminUsers from "./pages/AdminUsers";
import AdminReservations from "./pages/AdminReservations";
import AdminChat from "./pages/AdminChat";
import Notifications from "./pages/Notifications";
import AdminNotifications from "./pages/AdminNotifications";
import AdminSettings from "./pages/AdminSettings";
import AdminPlayerApproval from "./pages/AdminPlayerApproval";
import AdminPlayers from "./pages/AdminPlayers";
import ComparePlayers from "./pages/ComparePlayers";
import Settings from "./pages/Settings";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/auth" element={<Auth />} />
            <Route path="/scouting" element={<Scouting />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/players" element={<Players />} />
            <Route path="/reservations" element={<Reservations />} />
            <Route path="/chat" element={<Chat />} />
            <Route path="/my-credits" element={<MyCredits />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/notifications" element={<Notifications />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/admin" element={<Index />} />
            <Route path="/admin/users" element={<AdminUsers />} />
            <Route path="/admin/reservations" element={<AdminReservations />} />
            <Route path="/admin/chat" element={<AdminChat />} />
            <Route path="/admin/notifications" element={<AdminNotifications />} />
            <Route path="/admin/settings" element={<AdminSettings />} />
            <Route path="/admin/player-approval" element={<AdminPlayerApproval />} />
            <Route path="/admin/players" element={<AdminPlayers />} />
            <Route path="/admin/compare-players" element={<ComparePlayers />} />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
