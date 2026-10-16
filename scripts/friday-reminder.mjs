import { createClient } from '@supabase/supabase-js';
import nodemailer from 'nodemailer';

const { SUPABASE_URL, SUPABASE_SERVICE_KEY, GMAIL_USER, GMAIL_APP_PASSWORD, APP_URL } = process.env;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

const { data: people, error } = await supabase
  .from('profiles')
  .select('email, full_name')
  .eq('active', true);
if (error) throw error;
const emails = people.map((p) => p.email).filter(Boolean);
if (emails.length === 0) {
  console.log('No active members found, nothing to send.');
  process.exit(0);
}

const today = new Date();
const weekAgo = new Date(today.getTime() - 7 * 864e5).toISOString();
const todayStr = today.toISOString().slice(0, 10);
const nextWeekStr = new Date(today.getTime() + 7 * 864e5).toISOString().slice(0, 10);

const { count: doneCount } = await supabase
  .from('tasks').select('id', { count: 'exact', head: true })
  .eq('status', 'done').gte('completed_at', weekAgo);

const { count: dueCount } = await supabase
  .from('tasks').select('id', { count: 'exact', head: true })
  .neq('status', 'done').gte('due', todayStr).lte('due', nextWeekStr);

const { count: overdueCount } = await supabase
  .from('tasks').select('id', { count: 'exact', head: true })
  .neq('status', 'done').lt('due', todayStr);

const text = `Happy Friday, team!

Do you have a new idea this week? Please post it in the tracker so the whole team can see it and build on it (Leadership, Secretariat, Advocacy or Projects section).

Also tell us:
- What you finished
- What is still in progress
- Anything blocking you or needing help
- Meetings or events coming next week

This week in the tracker:
- Tasks completed in the last 7 days: ${doneCount ?? 0}
- Tasks due in the next 7 days: ${dueCount ?? 0}
- Overdue tasks: ${overdueCount ?? 0}

Please update your tasks here: ${APP_URL}

Nile Youth Network`;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: GMAIL_USER, pass: GMAIL_APP_PASSWORD },
});

await transporter.sendMail({
  from: `"Nile Youth Network" <${GMAIL_USER}>`,
  to: GMAIL_USER,
  bcc: emails.join(','),
  subject: 'Weekly check-in: share your new ideas',
  text,
});

console.log(`Reminder sent to ${emails.length} people.`);
