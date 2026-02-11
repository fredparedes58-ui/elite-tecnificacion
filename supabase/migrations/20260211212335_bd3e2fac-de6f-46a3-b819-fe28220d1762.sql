
-- Disable user triggers on reservations for cleanup
ALTER TABLE public.reservations DISABLE TRIGGER on_reservation_approval;
ALTER TABLE public.reservations DISABLE TRIGGER on_reservation_status_notify;
ALTER TABLE public.reservations DISABLE TRIGGER on_session_change_log;
ALTER TABLE public.reservations DISABLE TRIGGER on_session_changes;
ALTER TABLE public.reservations DISABLE TRIGGER update_reservations_updated_at;

-- Reassign reservations from duplicate trainers
UPDATE public.reservations SET trainer_id = '117f2bdd-fd73-4f8f-9149-a7c506a0732e' WHERE trainer_id = 'd7dff7c7-0acd-45ae-8d17-b0c654e3f679';
UPDATE public.reservations SET trainer_id = '268f601d-e13e-4225-834c-09cc715a95f4' WHERE trainer_id = '2e276598-5dcd-4ee7-a075-87c05e36456b';
UPDATE public.reservations SET trainer_id = 'dcd0f677-8200-4960-827b-4a51bf675631' WHERE trainer_id = 'b2eb2f77-6de4-4840-96d5-2f46d4b86649';
UPDATE public.reservations SET trainer_id = '2e8965dc-362d-48fd-aae1-aedfc0ad5394' WHERE trainer_id = '41f962b0-9e21-4f0a-b830-977597009bab';

-- Re-enable triggers
ALTER TABLE public.reservations ENABLE TRIGGER on_reservation_approval;
ALTER TABLE public.reservations ENABLE TRIGGER on_reservation_status_notify;
ALTER TABLE public.reservations ENABLE TRIGGER on_session_change_log;
ALTER TABLE public.reservations ENABLE TRIGGER on_session_changes;
ALTER TABLE public.reservations ENABLE TRIGGER update_reservations_updated_at;

-- Delete duplicate trainers
DELETE FROM public.trainers WHERE id IN (
  'd7dff7c7-0acd-45ae-8d17-b0c654e3f679',
  '2e276598-5dcd-4ee7-a075-87c05e36456b',
  'b2eb2f77-6de4-4840-96d5-2f46d4b86649',
  '41f962b0-9e21-4f0a-b830-977597009bab'
);

-- Assign unique colors to remaining inactive trainers
UPDATE public.trainers SET color = '#ef4444' WHERE id = '117f2bdd-fd73-4f8f-9149-a7c506a0732e';
UPDATE public.trainers SET color = '#22c55e' WHERE id = '268f601d-e13e-4225-834c-09cc715a95f4';
UPDATE public.trainers SET color = '#3b82f6' WHERE id = 'dcd0f677-8200-4960-827b-4a51bf675631';
UPDATE public.trainers SET color = '#ec4899' WHERE id = '2e8965dc-362d-48fd-aae1-aedfc0ad5394';
UPDATE public.trainers SET color = '#14b8a6' WHERE id = '08562c55-1198-41e6-b443-6df2ca16dbf2';
