# Nile Youth Task Tracker

A free tracker for the Nile Youth Network committee: tasks, meetings and minutes, weekly goals, media posts, training, finance, and a work area for each committee position. Every section accepts files, photos, videos and links.

The page is plain HTML. **GitHub Pages** hosts it, and **Supabase** stores the data, the logins and the files.

---

## 1. What is in this folder

| File | What it is |
|---|---|
| `index.html` | The whole app. You paste two Supabase values into it. |
| `supabase-setup.sql` | Creates every table, permission and the file storage in Supabase. Run once. |
| `assets/` | Put `logo.jpg` and `nile-dam.jpg` here (see step 8). |
| `.github/workflows/keep-alive.yml` | Optional. Pings Supabase twice a week. |
| `.nojekyll` | Tells GitHub Pages to serve the files as they are. |
| `README.md` | This guide. |

Until you paste the two Supabase values, `index.html` runs in **demo mode** on sample data. Open it and use the **View as** menu to preview each role. Nothing is saved in demo mode.

---

## 2. How the pieces connect

```
 People's browsers ──► GitHub Pages  (hosts index.html, free)
        │
        └──────────► Supabase  (login, database, files, live updates)
```

- GitHub only serves the page. It stores no data.
- The page talks straight to Supabase with the two values you paste in (the project URL and the public "anon" key). These two values are **meant to be public**. Your data is protected by the access rules in `supabase-setup.sql`: only people you approve can read or change anything.
- **Never paste the `service_role` (secret) key anywhere in this project.**

---

## 3. Go live, step by step (about 20 minutes)

### Step 1. Create the Supabase project
1. Go to supabase.com, sign up, and click **New project**.
2. Choose a name, a strong database password (save it), and the region closest to your team. Wait until it finishes setting up.

### Step 2. Create the tables, permissions and file storage
1. In Supabase open **SQL Editor** → **New query**.
2. Open `supabase-setup.sql` in a text editor, copy **everything**, paste it into the query, and click **Run**.
3. You should see "Success". Run it only once. If you see an error, copy the message and ask for help before running it again.
4. Check: **Storage** now shows a bucket called `attachments`.

### Step 3. Set the sign-in options
1. Open **Authentication** → **Sign In / Providers** (or **Providers**) → **Email**.
2. Turn **Confirm email** **off**. People then sign in with email and password and **no emails are sent**.
   Why: Supabase's built-in email sender is for testing only. It allows about 2 emails per hour and only delivers to addresses on your Supabase team, so confirmation emails and "email me a login link" would not reach your members. If you want email links later, connect your own email provider under **Authentication → SMTP Settings** first.
3. Leave **Allow new users to sign up** **on**. New people see nothing until you approve them.

### Step 3b. Check the file size limit
Open **Storage** → **Settings**. The free plan allows files up to **50 MB**. The page uses the same 50 MB limit.

### Step 4. Copy your two Supabase values
1. Open **Project Settings** → **API** (or **API Keys**).
2. Copy the **Project URL** (looks like `https://abcdxyz.supabase.co`).
3. Copy the **anon / public** key. If your dashboard shows a "publishable" key (starts with `sb_publishable_`), copy that instead. Either works.

### Step 5. Paste them into `index.html`
1. Open `index.html` in a text editor (or on GitHub with the pencil button after step 6).
2. Search for `PASTE_YOUR_SUPABASE_URL_HERE`. You will see:
   ```js
   const SUPABASE_URL = 'PASTE_YOUR_SUPABASE_URL_HERE';
   const SUPABASE_ANON_KEY = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';
   ```
3. Replace the text between the quotes with your two values. Keep the quotes. Save.
4. The demo switches off automatically. The page now uses real login and shared data.

### Step 6. Publish on GitHub Pages
1. Sign in at github.com and click **New repository**. Name it, for example, `nile-youth-task-tracker`. Choose **Public**.
2. Click **uploading an existing file**, drag in these files and folders, and click **Commit changes**: `index.html`, `supabase-setup.sql`, `README.md`, `.nojekyll`, and the `assets` folder.
3. Optional keep-alive file: click **Add file → Create new file**, type `.github/workflows/keep-alive.yml` as the name, paste the file's contents, and commit.
4. Open **Settings** → **Pages**. Under **Build and deployment**, choose **Deploy from a branch**, branch **main**, folder **/ (root)**, and click **Save**.
5. After 1 to 2 minutes your site is live at `https://YOUR-USERNAME.github.io/nile-youth-task-tracker/`.

### Step 7. Tell Supabase your website address
1. In Supabase open **Authentication** → **URL Configuration**.
2. Set **Site URL** to your GitHub Pages address, for example `https://YOUR-USERNAME.github.io/nile-youth-task-tracker/`.
3. Add the same address under **Redirect URLs** and save.

### Step 8. Add your logo and Nile picture (optional but recommended)
Save the two pictures into the `assets` folder of your repository as `logo.jpg` and `nile-dam.jpg`. The logo appears at the top left and on the sign-in screen. The dam picture appears blurred behind the left menu and faintly behind the page. Anyone can switch the picture off from their profile. If a file is missing, the page tries the Postimages links and then a built-in placeholder.

### Step 9. Create the first account (you become the admin)
1. Open your live site and click **Create account**. Enter your name, email and a password (6 characters or more).
2. **The very first account becomes the admin**, so do this yourself before sharing the link.

### Step 10. Add the committee
1. Share the link. Each member clicks **Create account** and sees "Waiting for approval".
2. In the **Team** tab, for each person:
   - click **Approve**,
   - choose their **position** (Chair person, Vice chair person, Secretary general, Advocacy, Communication, Treasurer, Project coordinator),
   - tick **Trainer** for the member who works on training.
3. The **Chair person** and **Secretary general** become admins automatically when you assign those positions.

---

## 4. Test checklist (5 minutes)

After step 10, check each line:

- [ ] I can sign in and see the Main board.
- [ ] I created a task with a photo attached, and the photo shows inside the task.
- [ ] A second person (another browser or phone) signed up, and I approved them in the Team tab.
- [ ] That person updated a task and I saw the change without refreshing.
- [ ] I scheduled a meeting with a Google Meet link, and the other person replied "Going".
- [ ] I posted minutes with an attachment and it is visible in the minutes.
- [ ] The treasurer added an expense and the balance changed.

---

## 5. Who can do what

- **Every approved member:** view everything, create and update tasks, reply to meetings, set weekly goals, confirm media posts, and add or edit files in every section.
- **Chair person and Secretary general:** admins (full access, including Admin board and Team).
- **Vice chair and all admins:** schedule meetings and post minutes.
- **Treasurer and admins:** record income, expenses, budgets and currency. Everyone can view finance.
- **Communication lead and admins:** add media posts.
- **Trainer and admins:** schedule trainings.
- **Anyone not approved:** sees nothing.

---

## 6. Free plan limits and how the tool stays inside them

Limits can change, so check supabase.com/pricing when you set up.

| Limit (free plan) | What it means for you | What the tool does |
|---|---|---|
| File storage about 1 GB | Roughly 300 phone photos, or about 20 videos of 50 MB | Photos are shrunk automatically to about 1600 px. The Admin board shows how much is used. Use YouTube or Google Drive **links** for long videos. |
| 50 MB per file | Bigger files are refused | The page blocks them and suggests a link. |
| Data transfer about 5 GB a month | Heavy use could exceed it | The page loads everything once, then only reloads what changed. There is no constant refresh. |
| Database 500 MB | Plenty for text | Not a concern. |
| Paused after about a week without use | The site stops loading until restored | Restore it in the Supabase dashboard (data is kept). The optional keep-alive workflow may help. Add repository secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` to use it. |
| No automatic backups on the free plan | Data is not backed up for you | Use **Export CSV** on the Admin board and Finance page every month. Files are not included in the CSV. |
| Built-in email about 2 per hour | Email links would not work | Use password sign-in (step 3). |

If you outgrow the free plan, the paid Pro plan raises the storage and transfer limits a lot and removes the pause.

---

## 7. Troubleshooting

| What you see | What to do |
|---|---|
| The page shows the demo bar | The two `PASTE_...` values are still in `index.html`. Paste your values (step 5) and commit. |
| "Could not load data… Did you run supabase-setup.sql?" | Run the SQL file (step 2). If you ran it twice, the tables already exist; that error is harmless only if the first run said Success. |
| Yellow notice about missing tables | The SQL ran only partly. Ask for help; do not delete tables. |
| "Waiting for approval" | An admin must approve you in the Team tab. |
| "Invalid API key" or blank data | The URL or key was pasted wrong. Copy them again from Project Settings → API. Make sure there are no spaces inside the quotes. |
| Sign-in link or confirmation email never arrives | Turn Confirm email off and use password sign-in (step 3). |
| "You do not have permission to do that" | That action belongs to another position. See section 5. |
| Upload fails | The file is over 50 MB, or storage is full. Use a link instead. Check Storage in Supabase. |
| Images show an old or placeholder logo | Put `logo.jpg` and `nile-dam.jpg` in the `assets` folder (step 8) and refresh. |
| The site stopped loading after a quiet week | Open Supabase and restore the paused project. |
| Changes to `index.html` are not visible | GitHub Pages takes 1 to 2 minutes. Refresh with Ctrl+Shift+R. |

---

## 8. Good to know

- **WhatsApp and email notifications** open with a ready message. People who add their WhatsApp number in their profile get their own button. Automatic sending to everyone needs an extra service and is not included.
- **Public repository:** the code is public, so do not put private information in `index.html`. Your data is safe because of the access rules, not because the page is hidden.
- **Updating the app:** replace `index.html` on GitHub (keep your two pasted values) and refresh. If a new version also needs database changes, it comes with a new SQL file and instructions.