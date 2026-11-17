// Interface web (SPEC-005, ADR-002). Une seule origine : l'API passe par la passerelle (SPEC-001.8).
// Aucune adresse d'hôte ni de port n'est écrite ici : l'origine courante sert de base à supabase-js.
import { createClient } from '/vendor/supabase.js';

const cfg = window.DEVENV_CONFIG || {};
const sb = createClient(window.location.origin, cfg.anonKey || '', {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, storageKey: 'devenv-taches' },
});

const STATUT = { todo: 'À faire', in_progress: 'En cours', done: 'Terminée' };
const PROPOSITION = { pending: 'En attente', accepted: 'Acceptée', refused: 'Refusée', expired: 'Expirée' };
const MESSAGES = {
  compte_inactif: "Votre compte n'est pas encore activé.",
  non_autorise: 'Cette action ne vous est pas permise.',
  tache_introuvable: "Cette tâche n'existe plus.",
  tache_terminee: 'Cette tâche est terminée.',
  cible_introuvable: "Ce compte n'existe pas.",
  cible_invalide: 'Ce collègue ne peut pas recevoir cette tâche ou cette demande.',
  admin_protege: 'Ce compte ne peut pas être désactivé.',
  doublon: 'Une demande identique est déjà en attente.',
  proposition_introuvable: "Cette proposition n'existe plus.",
  proposition_traitee: 'Cette proposition a déjà reçu une réponse.',
  proposition_non_valable: "Cette proposition n'est plus valable.",
};
const ERREUR_GENERIQUE = "L'opération n'a pas pu être effectuée. Vérifiez la saisie et réessayez.";

const nf = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });
const fmtH = (x) => `${nf.format(Number(x) || 0)} h`;
const fmtDate = (d) => (d ? new Date(d).toLocaleDateString('fr-FR') : '');
const aujourdhui = () => {
  const d = new Date();
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
};

// ------------------------------------------------------------------ DOM : aide minimale, sans innerHTML
function el(tag, props, ...enfants) {
  const n = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k.startsWith('on') && typeof v === 'function') n.addEventListener(k.slice(2), v);
    else n.setAttribute(k, v === true ? '' : String(v));
  }
  for (const c of enfants.flat()) {
    if (c === undefined || c === null || c === false) continue;
    n.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return n;
}
const champ = (id, libelle, controle, aide) =>
  el('div', { class: 'champ' }, el('label', { for: id }, libelle), controle, aide ? el('span', { class: 'aide' }, aide) : null);
const option = (valeur, libelle, courant) => el('option', { value: valeur, selected: valeur === courant }, libelle);

function messageErreur(err) {
  const m = /DNUM:(\w+)/.exec(String((err && err.message) || ''));
  return (m && MESSAGES[m[1]]) || ERREUR_GENERIQUE;
}

function nombreDecimal(saisie) {
  const t = String(saisie || '').trim().replace(',', '.');
  if (!/^\d+(\.\d+)?$/.test(t)) return NaN;
  return Math.round(Number(t) * 100) / 100;
}

// ------------------------------------------------------------------ état et routage
const $main = document.getElementById('contenu');
const $menu = document.getElementById('menu');
let moi = null; // { id, nom, actif, role }

// SPEC-005.7 : message de confirmation, mémoire seule (ni URL ni stockage), affiché une fois sur la page visée.
let annonceEnAttente = null; // { chemin, texte }
const annoncer = (texte) => { annonceEnAttente = { chemin: parseRoute().chemin, texte }; };
function enTeteAnnonce(chemin) {
  const a = annonceEnAttente && annonceEnAttente.chemin === chemin ? annonceEnAttente.texte : null;
  annonceEnAttente = null;
  return a ? el('p', { class: 'info', role: 'status' }, a) : null;
}
// SPEC-005.62 : termes des recherches d'administration, conservés pendant les actions de la page.
let recherche = { attente: '', actifs: '' };

function parseRoute() {
  const h = window.location.hash.replace(/^#\/?/, '');
  const [chemin, requete = ''] = h.split('?');
  return { chemin: chemin.replace(/\/+$/, ''), params: new URLSearchParams(requete) };
}

function aller(chemin, params) {
  const cible = '#/' + chemin + (params ? '?' + params : '');
  if (window.location.hash !== cible) window.location.hash = cible;
  else rafraichir();
}

function afficher(noeud, focus) {
  $main.replaceChildren(noeud);
  if (focus) $main.focus();
}

async function chargerMoi() {
  const { data: { session } } = await sb.auth.getSession();
  if (!session) return null;
  const { data, error } = await sb.rpc('my_status');
  if (error) throw error;
  return { id: session.user.id, nom: data.display_name || '', actif: data.is_active === true, role: data.role };
}

async function rafraichir(focus = false) {
  const r = parseRoute();
  let m;
  try {
    m = await chargerMoi();
  } catch (e) {
    if (e && e.status === 401) m = null;
    else return afficherSansMenu(pageErreur(messageErreur(e)), focus);
  }
  if (!m) {
    $menu.hidden = true;
    return afficherSansMenu(r.chemin === 'inscription' ? pageInscription() : pageConnexion(), focus);
  }
  moi = m;
  if (!m.actif) {
    if (r.chemin !== 'attente') return aller('attente');
    return afficherSansMenu(pageAttente(), focus);
  }
  const c = r.chemin;
  if (annonceEnAttente && annonceEnAttente.chemin !== c) annonceEnAttente = null; // effacé à la navigation suivante
  if (c !== 'admin') recherche = { attente: '', actifs: '' };
  if (c === '' || c === 'connexion' || c === 'inscription' || c === 'attente') return aller('tableau');
  if (c === 'admin' && m.role !== 'admin') return aller('tableau');
  const pages = {
    tableau: () => pageTableau(r.params),
    'mes-taches': () => pageMesTaches(),
    propositions: () => pagePropositions(),
    admin: () => pageAdmin(),
  };
  let fn = pages[c];
  if (!fn && c.startsWith('collegue/')) {
    const id = c.slice('collegue/'.length);
    fn = () => pageCollegue(id);
  }
  if (!fn) return aller('tableau');
  $menu.hidden = false;
  await rendreMenu(c);
  try {
    afficher(await fn(), focus);
  } catch (e) {
    afficher(pageErreur(messageErreur(e)), focus);
  }
}

async function rendreMenu(courant) {
  const { count } = await sb.from('help_proposals')
    .select('id', { count: 'exact', head: true })
    .eq('to_user', moi.id).eq('status', 'pending');
  const lien = (chemin, libelle) => el('li', {}, el('a', {
    href: '#/' + chemin,
    'aria-current': courant === chemin ? 'page' : undefined,
  }, libelle));
  const liens = [
    lien('tableau', 'Tableau de bord'),
    lien('mes-taches', 'Mes tâches'),
    lien('propositions', `Propositions (${count || 0})`),
  ];
  if (moi.role === 'admin') liens.push(lien('admin', 'Administration'));
  $menu.replaceChildren(el('ul', {},
    liens,
    el('li', { class: 'discret' }, moi.nom),
    el('li', {}, el('button', { type: 'button', class: 'secondaire', onclick: deconnexion }, 'Se déconnecter'))));
}

function afficherSansMenu(noeud, focus) {
  $menu.replaceChildren();
  $menu.hidden = true;
  afficher(noeud, focus);
}

async function deconnexion() {
  await sb.auth.signOut();
  moi = null;
  aller('connexion');
}

// ------------------------------------------------------------------ écrans publics
function pageConnexion() {
  const erreur = el('p', { class: 'erreur', role: 'alert' });
  const email = el('input', { id: 'c-email', type: 'email', name: 'email', autocomplete: 'username', required: true });
  const mdp = el('input', { id: 'c-mdp', type: 'password', name: 'mot-de-passe', autocomplete: 'current-password', required: true });
  const form = el('form', {
    class: 'etroit', novalidate: true,
    onsubmit: async (ev) => {
      ev.preventDefault();
      erreur.textContent = '';
      if (!email.value.trim() || !mdp.value) {
        erreur.textContent = 'E-mail et mot de passe sont obligatoires.';
        return;
      }
      const { error } = await sb.auth.signInWithPassword({ email: email.value.trim(), password: mdp.value });
      if (error) {
        erreur.textContent = 'E-mail ou mot de passe incorrect.';
        mdp.value = '';
        return;
      }
      rafraichir();
    },
  }, champ('c-email', 'E-mail', email), champ('c-mdp', 'Mot de passe', mdp), erreur,
  el('button', { type: 'submit' }, 'Se connecter'));
  return el('section', { class: 'centre' }, el('h1', {}, 'Se connecter'), form,
    el('p', {}, el('a', { href: '#/inscription' }, 'Créer un compte')));
}

function pageInscription() {
  const erreur = el('p', { class: 'erreur', role: 'alert' });
  const confirmation = el('p', { class: 'info', role: 'status' });
  const nom = el('input', { id: 'i-nom', name: 'nom', autocomplete: 'name', required: true, maxlength: 80 });
  const email = el('input', { id: 'i-email', type: 'email', name: 'email', autocomplete: 'username', required: true });
  const mdp = el('input', { id: 'i-mdp', type: 'password', name: 'mot-de-passe', autocomplete: 'new-password', required: true });
  const form = el('form', {
    class: 'etroit', novalidate: true,
    onsubmit: async (ev) => {
      ev.preventDefault();
      erreur.textContent = '';
      confirmation.textContent = '';
      if (!nom.value.trim() || !email.value.trim() || !mdp.value) {
        erreur.textContent = 'Tous les champs sont obligatoires.';
        return;
      }
      if (mdp.value.length < 8) {
        erreur.textContent = 'Le mot de passe doit contenir au moins 8 caractères.';
        return;
      }
      const { error } = await sb.auth.signUp({
        email: email.value.trim(),
        password: mdp.value,
        options: { data: { display_name: nom.value.trim() } },
      });
      if (error) {
        const code = String(error.code || '');
        if (code === 'user_already_exists' || /already/i.test(String(error.message))) {
          erreur.textContent = 'Cet e-mail est déjà utilisé.';
        } else if (code === 'weak_password') {
          erreur.textContent = 'Le mot de passe doit contenir au moins 8 caractères.';
        } else {
          erreur.textContent = ERREUR_GENERIQUE;
        }
        return;
      }
      // L'inscription ouvre une session immédiate : on la ferme, le compte doit d'abord être activé.
      await sb.auth.signOut();
      form.reset();
      confirmation.textContent = "Votre compte est créé. Il est en attente d'activation par l'administrateur.";
    },
  }, champ('i-nom', 'Nom affiché', nom), champ('i-email', 'E-mail', email),
  champ('i-mdp', 'Mot de passe', mdp, '8 caractères minimum'), erreur,
  el('button', { type: 'submit' }, 'Créer un compte'));
  return el('section', { class: 'centre' }, el('h1', {}, 'Créer un compte'), form, confirmation,
    el('p', {}, el('a', { href: '#/connexion' }, 'Se connecter')));
}

function pageAttente() {
  return el('section', { class: 'centre' },
    el('h1', {}, "Compte en attente d'activation"),
    el('p', {}, "Votre compte est créé. Un administrateur doit l'activer avant que vous puissiez accéder aux tâches de l'équipe."),
    el('button', { type: 'button', onclick: deconnexion }, 'Se déconnecter'));
}

function pageErreur(message) {
  return el('section', {},
    el('h1', {}, 'Une erreur est survenue'),
    el('p', { class: 'erreur', role: 'alert' }, message),
    el('button', { type: 'button', onclick: () => rafraichir() }, 'Réessayer'));
}

// ------------------------------------------------------------------ tableau de bord (SPEC-005.20, .21)
async function pageTableau(params) {
  const jour = params.get('f') === 'jour';
  let q = sb.from('task_summary').select('id, title, status, assignee_id, due_date').neq('status', 'done').order('created_at');
  const [charges, taches, propo] = await Promise.all([
    sb.from('team_load').select('user_id, display_name, projected_hours, overloaded').order('display_name'),
    jour ? q.lte('due_date', aujourdhui()) : q,
    sb.from('help_proposals').select('id', { count: 'exact', head: true }).eq('to_user', moi.id).eq('status', 'pending'),
  ]);
  for (const r of [charges, taches, propo]) if (r.error) throw r.error;

  const parMembre = new Map();
  for (const t of taches.data) {
    if (!parMembre.has(t.assignee_id)) parMembre.set(t.assignee_id, []);
    parMembre.get(t.assignee_id).push(t);
  }
  const nbProp = propo.count || 0;
  const bascule = (libelle, actif, p) => el('button', {
    type: 'button', 'aria-pressed': actif ? 'true' : 'false',
    onclick: () => aller('tableau', p),
  }, libelle);

  return el('section', {},
    el('h1', {}, 'Tableau de bord'),
    el('p', {}, nbProp > 0
      ? el('a', { href: '#/propositions' }, `Vous avez ${nbProp} proposition(s) reçue(s) en attente`)
      : el('span', { class: 'discret' }, 'Aucune proposition reçue en attente.')),
    el('div', { role: 'group', 'aria-label': 'Filtre des tâches' },
      bascule('Toutes', !jour, ''), ' ', bascule("Aujourd'hui", jour, 'f=jour')),
    charges.data.length === 0
      ? el('p', { class: 'discret' }, 'Aucun membre actif.')
      : el('div', { class: 'grille-cartes' }, charges.data.map((c) => {
        const liste = parMembre.get(c.user_id) || [];
        return el('article', { class: 'carte' },
          el('h2', {}, el('a', { href: `#/collegue/${c.user_id}` }, c.display_name)),
          el('p', {}, 'Charge projetée : ', el('strong', {}, fmtH(c.projected_hours)),
            c.overloaded ? el('span', { class: 'badge' }, 'Surchargé') : null),
          liste.length
            ? el('ul', { class: 'liste' }, liste.map((t) => el('li', {},
              el('span', { class: 'tache-titre' }, t.title), ' — ', STATUT[t.status])))
            : el('p', { class: 'discret' }, jour ? "Aucune tâche échue aujourd'hui." : 'Aucune tâche en cours.'));
      })));
}

// ------------------------------------------------------------------ mes tâches (SPEC-005.30 à .33)
async function pageMesTaches() {
  const [taches, collegues] = await Promise.all([
    sb.from('task_summary').select('*').eq('assignee_id', moi.id).order('created_at'),
    sb.from('team_load').select('user_id, display_name').neq('user_id', moi.id).order('display_name'),
  ]);
  for (const r of [taches, collegues]) if (r.error) throw r.error;

  const choix = (idSelect) => el('select', { id: idSelect, name: 'collegue', required: true },
    collegues.data.map((c) => option(c.user_id, c.display_name)));

  const formulaireNouvelle = () => {
    const erreur = el('p', { class: 'erreur', role: 'alert' });
    const titre = el('input', { id: 'n-titre', name: 'titre', required: true, maxlength: 200 });
    const desc = el('textarea', { id: 'n-desc', name: 'description', maxlength: 4000 });
    const est = el('input', { id: 'n-est', name: 'estimation', inputmode: 'decimal', required: true });
    const ech = el('input', { id: 'n-ech', type: 'date', name: 'echeance' });
    return el('details', { class: 'depliable' },
      el('summary', {}, 'Nouvelle tâche'),
      el('form', {
        class: 'etroit', novalidate: true,
        onsubmit: async (ev) => {
          ev.preventDefault();
          erreur.textContent = '';
          if (!titre.value.trim()) { erreur.textContent = 'Le titre est obligatoire.'; return; }
          const h = nombreDecimal(est.value);
          if (!(h > 0) || h > 1000) {
            erreur.textContent = "L'estimation doit être un nombre d'heures supérieur à 0.";
            return;
          }
          const { error } = await sb.from('tasks').insert({
            title: titre.value.trim(),
            description: desc.value.trim() || null,
            estimate_hours: h,
            assignee_id: moi.id,
            due_date: ech.value || null,
          }).select('id');
          if (error) { erreur.textContent = messageErreur(error); return; }
          rafraichir();
        },
      },
      champ('n-titre', 'Titre', titre),
      champ('n-desc', 'Description (facultative)', desc),
      champ('n-est', 'Estimation en heures', est, 'Par exemple 2,5 ou 2.5'),
      champ('n-ech', 'Échéance (facultative)', ech),
      erreur,
      el('button', { type: 'submit' }, 'Enregistrer')));
  };

  const formulaireModifier = (t) => {
    const erreur = el('p', { class: 'erreur', role: 'alert' });
    const titre = el('input', { id: `m-titre-${t.id}`, name: 'titre', value: t.title, required: true, maxlength: 200 });
    const desc = el('textarea', { id: `m-desc-${t.id}`, name: 'description', maxlength: 4000 }, t.description || '');
    const est = el('input', { id: `m-est-${t.id}`, name: 'estimation', inputmode: 'decimal', value: String(t.estimate_hours).replace('.', ','), required: true });
    const statut = el('select', { id: `m-statut-${t.id}`, name: 'statut' },
      Object.entries(STATUT).map(([v, l]) => option(v, l, t.status)));
    return el('form', {
      class: 'etroit', novalidate: true,
      onsubmit: async (ev) => {
        ev.preventDefault();
        erreur.textContent = '';
        if (!titre.value.trim()) { erreur.textContent = 'Le titre est obligatoire.'; return; }
        const h = nombreDecimal(est.value);
        if (!(h > 0) || h > 1000) { erreur.textContent = "L'estimation doit être un nombre d'heures supérieur à 0."; return; }
        const { data, error } = await sb.from('tasks').update({
          title: titre.value.trim(),
          description: desc.value.trim() || null,
          estimate_hours: h,
          status: statut.value,
        }).eq('id', t.id).select('id');
        if (error) { erreur.textContent = messageErreur(error); return; }
        if (!data || data.length === 0) { erreur.textContent = MESSAGES.non_autorise; return; }
        rafraichir();
      },
    },
    champ(`m-titre-${t.id}`, 'Titre', titre),
    champ(`m-desc-${t.id}`, 'Description', desc),
    champ(`m-est-${t.id}`, 'Estimation en heures', est),
    champ(`m-statut-${t.id}`, 'Statut', statut),
    erreur,
    el('button', { type: 'submit' }, 'Enregistrer'));
  };

  const formulaireTemps = (t) => {
    const erreur = el('p', { class: 'erreur', role: 'alert' });
    const heures = el('input', { id: `t-h-${t.id}`, type: 'number', min: 0, max: 24, step: 'any', value: 0 });
    const minutes = el('input', { id: `t-m-${t.id}`, type: 'number', min: 0, max: 1440, step: 1, value: 0 });
    const date = el('input', { id: `t-d-${t.id}`, type: 'date', value: aujourdhui() });
    return el('form', {
      class: 'etroit', novalidate: true,
      onsubmit: async (ev) => {
        ev.preventDefault();
        erreur.textContent = '';
        const total = Math.round(Number(heures.value || 0) * 60 + Number(minutes.value || 0));
        if (!Number.isFinite(total) || total < 1 || total > 1440) {
          erreur.textContent = 'La durée doit être comprise entre 1 minute et 24 heures.';
          return;
        }
        const { error } = await sb.from('time_entries').insert({
          task_id: t.id, minutes: total, work_date: date.value || aujourdhui(),
        });
        if (error) { erreur.textContent = messageErreur(error); return; }
        rafraichir();
      },
    },
    champ(`t-h-${t.id}`, 'Heures', heures),
    champ(`t-m-${t.id}`, 'Minutes', minutes),
    champ(`t-d-${t.id}`, 'Date', date),
    erreur,
    el('button', { type: 'submit' }, 'Enregistrer'));
  };

  const formulaireTransfert = (t, rpc, libelle, bouton, texteAnnonce) => {
    const erreur = el('p', { class: 'erreur', role: 'alert' });
    const sel = choix(`${rpc}-${t.id}`);
    return el('details', { class: 'depliable' },
      el('summary', {}, libelle),
      collegues.data.length === 0
        ? el('p', { class: 'discret' }, 'Aucun collègue actif.')
        : el('form', {
          class: 'etroit', novalidate: true,
          onsubmit: async (ev) => {
            ev.preventDefault();
            erreur.textContent = '';
            const { error } = await sb.rpc(rpc, { p_task: t.id, p_to: sel.value });
            if (error) { erreur.textContent = messageErreur(error); return; }
            if (texteAnnonce) {
              const cible = collegues.data.find((x) => x.user_id === sel.value);
              annoncer(texteAnnonce((cible && cible.display_name) || 'Collègue', t.title));
            }
            rafraichir();
          },
        }, champ(`${rpc}-${t.id}`, 'Collègue', sel), erreur, el('button', { type: 'submit' }, bouton)));
  };

  const cartes = taches.data.map((t) => el('li', {},
    el('h2', {}, t.title),
    el('p', { class: 'tache-meta' },
      `Statut : ${STATUT[t.status]} · Estimation : ${fmtH(t.estimate_hours)} · Temps logué : ${fmtH(t.logged_hours)} · Reste : ${fmtH(t.remaining_hours)}`),
    el('details', { class: 'depliable' }, el('summary', {}, 'Modifier'), formulaireModifier(t)),
    el('details', { class: 'depliable' }, el('summary', {}, 'Loguer du temps'), formulaireTemps(t)),
    formulaireTransfert(t, 'reassign_task', 'Réaffecter', 'Valider'),
    formulaireTransfert(t, 'request_help', "Demander de l'aide", 'Valider',
      (nom, titre) => `Demande d'aide envoyée à ${nom} pour la tâche « ${titre} ».`)));

  return el('section', {},
    enTeteAnnonce('mes-taches'),
    el('h1', {}, 'Mes tâches'),
    formulaireNouvelle(),
    taches.data.length === 0
      ? el('p', { class: 'discret' }, 'Vous n\'avez aucune tâche.')
      : el('ul', { class: 'liste' }, cartes));
}

// ------------------------------------------------------------------ tâches d'un collègue (SPEC-005.40)
async function pageCollegue(id) {
  const [taches, membre] = await Promise.all([
    sb.from('task_summary').select('id, title, status, estimate_hours, logged_hours').eq('assignee_id', id).order('created_at'),
    sb.from('team_load').select('display_name').eq('user_id', id).maybeSingle(),
  ]);
  for (const r of [taches, membre]) if (r.error) throw r.error;
  const nom = (membre.data && membre.data.display_name) || 'Collègue';
  const zone = el('p', { class: 'erreur', role: 'alert' });
  const proposer = (t) => el('button', {
    type: 'button',
    onclick: async () => {
      zone.textContent = '';
      const { error } = await sb.rpc('offer_help', { p_task: t.id });
      if (error) { zone.textContent = messageErreur(error); return; }
      annoncer(`Proposition envoyée à ${nom} pour la tâche « ${t.title} ».`);
      rafraichir();
    },
  }, 'Proposer mon aide');
  return el('section', {},
    enTeteAnnonce(`collegue/${id}`),
    el('h1', {}, `Tâches de ${nom}`),
    el('p', { class: 'discret' }, 'Lecture seule.'),
    zone,
    taches.data.length === 0
      ? el('p', { class: 'discret' }, 'Aucune tâche.')
      : el('ul', { class: 'liste' }, taches.data.map((t) => el('li', {},
        el('h2', {}, t.title),
        el('p', { class: 'tache-meta' },
          `Statut : ${STATUT[t.status]} · Estimation : ${fmtH(t.estimate_hours)} · Temps logué : ${fmtH(t.logged_hours)}`),
        t.status !== 'done' && id !== moi.id ? proposer(t) : null))));
}

// ------------------------------------------------------------------ propositions (SPEC-005.50, .51)
async function pagePropositions() {
  const [props, taches, membres] = await Promise.all([
    sb.from('help_proposals').select('id, kind, from_user, to_user, task_id, status').order('created_at', { ascending: false }),
    sb.from('tasks').select('id, title'),
    sb.from('team_load').select('user_id, display_name'),
  ]);
  for (const r of [props, taches, membres]) if (r.error) throw r.error;
  const noms = new Map(membres.data.map((m) => [m.user_id, m.display_name]));
  const titres = new Map(taches.data.map((t) => [t.id, t.title]));
  const nomDe = (id) => noms.get(id) || 'Collègue';
  const zone = el('p', { class: 'erreur', role: 'alert' });

  const recues = props.data.filter((p) => p.to_user === moi.id);
  const envoyees = props.data.filter((p) => p.from_user === moi.id);

  const repondre = (p, accepte) => async () => {
    zone.textContent = '';
    const { error } = await sb.rpc('respond_proposal', { p_id: p.id, p_accept: accepte });
    if (error) { zone.textContent = messageErreur(error); return; }
    rafraichir();
  };

  return el('section', {},
    el('h1', {}, 'Propositions'),
    zone,
    el('h2', {}, 'Propositions reçues'),
    recues.length === 0
      ? el('p', { class: 'discret' }, 'Aucune proposition reçue.')
      : el('ul', { class: 'liste' }, recues.map((p) => el('li', {},
        el('p', {}, `${nomDe(p.from_user)} — ${p.kind === 'offer' ? 'Propose son aide' : 'Vous demande de l\'aide'}`),
        el('p', { class: 'tache-meta' }, `Tâche : ${titres.get(p.task_id) || '(tâche supprimée)'} · ${PROPOSITION[p.status]}`),
        p.status === 'pending'
          ? el('p', {},
            el('button', { type: 'button', onclick: repondre(p, true) }, 'Accepter'), ' ',
            el('button', { type: 'button', class: 'secondaire', onclick: repondre(p, false) }, 'Refuser'))
          : null))),
    el('h2', {}, 'Propositions envoyées'),
    envoyees.length === 0
      ? el('p', { class: 'discret' }, 'Aucune proposition envoyée.')
      : el('ul', { class: 'liste' }, envoyees.map((p) => el('li', {},
        el('p', {}, `${p.kind === 'offer' ? 'Vous proposez votre aide à' : 'Vous demandez de l\'aide à'} ${nomDe(p.to_user)}`),
        el('p', { class: 'tache-meta' }, `Tâche : ${titres.get(p.task_id) || '(tâche supprimée)'} · ${PROPOSITION[p.status]}`)))));
}

// ------------------------------------------------------------------ administration (SPEC-005.60, .61)
// SPEC-005.62 : insensible à la casse et aux accents ; chaque mot du terme doit figurer dans le nom ou l'e-mail.
const normaliser = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
function correspond(compte, terme) {
  const mots = normaliser(terme).split(/\s+/).filter(Boolean);
  if (mots.length === 0) return true;
  const texte = normaliser(`${compte.display_name} ${compte.email}`);
  return mots.every((m) => texte.includes(m));
}

async function pageAdmin() {
  const { data, error } = await sb.rpc('admin_list_accounts');
  if (error) throw error;
  const zone = el('p', { class: 'erreur', role: 'alert' });
  const attente = data.filter((c) => !c.is_active);
  const actifs = data.filter((c) => c.is_active);
  let confirmation = null; // id du compte dont la désactivation attend confirmation (SPEC-005.63)

  const basculer = (c, active) => async () => {
    zone.textContent = '';
    const { error: e } = await sb.rpc('admin_set_active', { p_user: c.id, p_active: active });
    if (e) { confirmation = null; zone.textContent = messageErreur(e); rendreListes(); return; }
    if (!active) annoncer(`Le compte de ${c.display_name} est désactivé.`);
    rafraichir();
  };

  const ouvrir = (id) => {
    confirmation = id;
    rendreListes();
    const b = document.getElementById(`adm-annuler-${id}`);
    if (b) b.focus();
  };
  const fermer = (id) => {
    confirmation = null;
    rendreListes();
    const b = document.getElementById(`adm-desact-${id}`);
    if (b) b.focus();
  };

  // colonnes : [titre, fonction(compte) -> contenu] ; action : fonction(compte) -> contenu ou null
  const tableau = (lignes, colonnes, action) => el('table', {},
    el('thead', {}, el('tr', {},
      [...colonnes.map(([titre]) => titre), ...(action ? [''] : [])].map((t) => el('th', { scope: 'col' }, t)))),
    el('tbody', {}, lignes.map((c) => el('tr', {},
      [...colonnes.map(([, rendu]) => rendu(c)), ...(action ? [action(c)] : [])]
        .map((contenu) => el('td', {}, contenu))))));

  // SPEC-005.63 : bouton « Désactiver » puis bloc de confirmation (focus sur « Annuler », Échap ferme)
  const boutonDesactiver = (c) => {
    if (c.role === 'admin' || c.id === moi.id) return null;
    const ouvert = confirmation === c.id;
    return el('div', {},
      el('button', {
        type: 'button', class: 'secondaire', id: `adm-desact-${c.id}`,
        'aria-expanded': ouvert ? 'true' : 'false',
        onclick: () => (ouvert ? fermer(c.id) : ouvrir(c.id)),
      }, 'Désactiver'),
      ouvert
        ? el('div', {
          role: 'group', class: 'confirmation', 'aria-labelledby': `adm-texte-${c.id}`,
          onkeydown: (ev) => { if (ev.key === 'Escape') fermer(c.id); },
        },
        el('p', { id: `adm-texte-${c.id}` },
          `Désactiver le compte de ${c.display_name} ? Cette personne ne verra plus les données de l'équipe.`),
        el('button', { type: 'button', class: 'secondaire', id: `adm-annuler-${c.id}`, onclick: () => fermer(c.id) }, 'Annuler'),
        ' ',
        el('button', { type: 'button', onclick: basculer(c, false) }, 'Confirmer la désactivation'))
        : null);
  };

  // SPEC-005.62 : sans terme, la liste complète ; avec un terme sans résultat, le message exact.
  const rendreListe = (cle, comptes, colonnes, action, vide, horsRecherche) => {
    const terme = recherche[cle].trim();
    const trouves = comptes.filter((c) => correspond(c, terme));
    if (terme && trouves.length === 0) return el('p', { role: 'status' }, horsRecherche(terme));
    if (trouves.length === 0) return el('p', { class: 'discret' }, vide);
    return tableau(trouves, colonnes, action);
  };

  const colNom = ['Nom', (c) => c.display_name];
  const colMail = ['E-mail', (c) => c.email];
  const corps = { attente: el('div'), actifs: el('div') };

  const rendreListes = () => {
    corps.attente.replaceChildren(rendreListe('attente', attente,
      [colNom, colMail, ['Inscription', (c) => fmtDate(c.created_at)]],
      (c) => el('button', { type: 'button', onclick: basculer(c, true) }, 'Activer'),
      'Aucun compte en attente.',
      (t) => `Aucun compte en attente ne correspond à « ${t} ».`));
    corps.actifs.replaceChildren(rendreListe('actifs', actifs,
      [colNom, colMail, ['Rôle', (c) => (c.role === 'admin' ? 'Administrateur' : 'Membre')]],
      boutonDesactiver,
      'Aucun compte actif.',
      (t) => `Aucun compte actif ne correspond à « ${t} ».`));
  };

  // Le champ n'est pas dans un formulaire : Entrée ne soumet rien. Filtrage à chaque saisie, focus conservé.
  const champRecherche = (cle, id, libelle) => {
    const saisie = el('input', { id, type: 'search', autocomplete: 'off' });
    saisie.value = recherche[cle];
    saisie.addEventListener('input', () => { recherche[cle] = saisie.value; rendreListes(); });
    return el('div', { class: 'champ recherche' }, el('label', { for: id }, libelle), saisie);
  };

  const page = el('section', {},
    enTeteAnnonce('admin'),
    el('h1', {}, 'Administration'),
    zone,
    el('h2', {}, 'Comptes en attente'),
    champRecherche('attente', 'adm-recherche-attente', 'Rechercher dans les comptes en attente'),
    corps.attente,
    el('h2', {}, 'Comptes actifs'),
    champRecherche('actifs', 'adm-recherche-actifs', 'Rechercher dans les comptes actifs'),
    corps.actifs);
  rendreListes();
  return page;
}

// ------------------------------------------------------------------ démarrage
// Retour de recette (rapport-client, SPEC-005) : les formulaires dépliables se superposent sous leur résumé (style.css),
// sans rien pousser. Un seul est déplié à la fois, pour que les superpositions ne s'empilent pas.
document.addEventListener('toggle', (ev) => {
  const d = ev.target;
  if (!(d instanceof HTMLDetailsElement) || !d.classList.contains('depliable') || !d.open) return;
  document.querySelectorAll('details.depliable[open]').forEach((autre) => { if (autre !== d) autre.open = false; });
}, true);
// SPEC-005.6 : la marge de défilement égale la hauteur réelle de la barre fixe (repli : style.css).
const $entete = document.querySelector('.entete');
if ($entete && 'ResizeObserver' in window) {
  new ResizeObserver(() => {
    document.documentElement.style.scrollPaddingTop = `${$entete.offsetHeight}px`;
  }).observe($entete);
}

window.addEventListener('hashchange', () => rafraichir(true));
rafraichir(false);
