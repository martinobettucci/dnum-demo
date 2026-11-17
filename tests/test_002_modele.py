"""SPEC-002 — Modèle de données, RLS, charge projetée et entraide.

Tout passe par l'API ($APP_URL/auth/v1, $APP_URL/rest/v1) avec de vrais comptes de test.
L'admin (membre actif, voit toutes les tâches) sert de lecteur de contrôle de l'état réel.
"""
import datetime, uuid

import pytest

from conftest import (Api, compte_admin, connecter, nombre_total, refus, sans_effet, un)

TABLES = ["profiles", "tasks", "time_entries", "help_proposals"]
VUES = ["task_summary", "team_load"]


def approx(a, b, tol=0.001):
    return abs(float(a) - float(b)) <= tol


def aujourdhui_possibles():
    """Date du jour côté base : UTC (ou locale du runner si différente)."""
    return {datetime.datetime.now(datetime.timezone.utc).date().isoformat(),
            datetime.date.today().isoformat()}


def rpcs_metier(jeu, cible_id):
    t = jeu["task"]["id"]
    return [
        ("admin_list_accounts", {}),
        ("admin_set_active", {"p_user": cible_id, "p_active": True}),
        ("reassign_task", {"p_task": t, "p_to": cible_id}),
        ("offer_help", {"p_task": t}),
        ("request_help", {"p_task": t, "p_to": cible_id}),
        ("respond_proposal", {"p_id": jeu["proposal"] or str(uuid.uuid4()), "p_accept": True}),
    ]


def propositions_recues(api, task_id):
    return api.rows("help_proposals", to_user=f"eq.{api.id}", task_id=f"eq.{task_id}")


# =========================================================================== SPEC-002.1 / .2
@pytest.mark.spec("SPEC-002.1")
@pytest.mark.spec("SPEC-002.2")
@pytest.mark.parametrize("bearer_anon", [True, False], ids=["bearer-anon", "apikey-seule"])
@pytest.mark.parametrize("objet", TABLES + VUES)
def test_anon_lecture_zero_ligne_ou_refus(jeu, anon_key, objet, bearer_anon):
    r = Api(anon_key, bearer_anon=bearer_anon).get(objet)
    assert sans_effet(r) and r.status_code < 500, f"{objet} → {r.status_code} {r.text[:200]}"


@pytest.mark.spec("SPEC-002.1")
@pytest.mark.spec("SPEC-002.2")
@pytest.mark.parametrize("bearer_anon", [True, False], ids=["bearer-anon", "apikey-seule"])
def test_anon_ecriture_tache_refusee_sans_effet(jeu, anon_key, admin, bearer_anon):
    titre = f"anon-{uuid.uuid4().hex}"
    r = Api(anon_key, bearer_anon=bearer_anon).post(
        "tasks", {"title": titre, "estimate_hours": 1, "assignee_id": jeu["a"].id,
                  "created_by": jeu["a"].id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert admin.rows("tasks", title=f"eq.{titre}") == []


@pytest.mark.spec("SPEC-002.1")
@pytest.mark.spec("SPEC-002.2")
def test_anon_ecriture_temps_profil_proposition_refusees_sans_effet(jeu, anon):
    a, t = jeu["a"], jeu["task"]
    avant = a.task(t["id"])["logged_hours"]
    assert refus(anon.post("time_entries", {"task_id": t["id"], "minutes": 60, "user_id": a.id}))
    assert sans_effet(anon.patch("tasks", {"id": f"eq.{t['id']}"}, {"title": "pirate"}))
    assert sans_effet(anon.patch("profiles", {"id": f"eq.{a.id}"}, {"role": "admin"}))
    assert refus(anon.post("help_proposals", {"task_id": t["id"], "kind": "offer",
                                              "from_user": jeu["b"].id, "to_user": a.id}))
    assert approx(a.task(t["id"])["logged_hours"], avant)
    assert a.task(t["id"])["title"] == t["title"]
    assert a.status()["role"] == "member"


@pytest.mark.spec("SPEC-002.1")
@pytest.mark.spec("SPEC-002.2")
@pytest.mark.parametrize("idx", range(6), ids=["admin_list_accounts", "admin_set_active",
                                               "reassign_task", "offer_help", "request_help",
                                               "respond_proposal"])
def test_anon_rpc_metier_refusees(jeu, anon, admin, inactif, idx):
    nom, args = rpcs_metier(jeu, inactif.id)[idx]
    r = anon.rpc(nom, **args)
    assert refus(r), f"{nom} → {r.status_code} {r.text[:200]}"
    # aucun effet : la cible reste inactive, la tâche reste chez A
    assert compte_admin(admin, user_id=inactif.id)[0]["is_active"] is False
    assert admin.task(jeu["task"]["id"])["assignee_id"] == jeu["a"].id


# =========================================================================== SPEC-002.3
@pytest.mark.spec("SPEC-002.1")
@pytest.mark.spec("SPEC-002.3")
@pytest.mark.parametrize("objet", TABLES + VUES)
def test_inactif_lecture_zero_ligne_ou_refus(jeu, inactif, objet):
    r = inactif.get(objet)
    assert sans_effet(r) and r.status_code < 500, f"{objet} → {r.status_code} {r.text[:200]}"


@pytest.mark.spec("SPEC-002.3")
def test_inactif_my_status_is_active_false(inactif):
    st = inactif.status()
    assert st["is_active"] is False
    assert st["role"] == "member"


@pytest.mark.spec("SPEC-002.3")
def test_inactif_creation_tache_refusee_sans_effet(inactif, admin):
    titre = f"inactif-{uuid.uuid4().hex}"
    r = inactif.post("tasks", {"title": titre, "estimate_hours": 1, "assignee_id": inactif.id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert admin.rows("tasks", title=f"eq.{titre}") == []


@pytest.mark.spec("SPEC-002.3")
def test_inactif_saisie_temps_et_modification_refusees(jeu, inactif):
    a, t = jeu["a"], jeu["task"]
    avant = a.task(t["id"])
    assert refus(inactif.post("time_entries", {"task_id": t["id"], "minutes": 60}))
    assert sans_effet(inactif.patch("tasks", {"id": f"eq.{t['id']}"}, {"title": "pirate"}))
    apres = a.task(t["id"])
    assert approx(apres["logged_hours"], avant["logged_hours"]) and apres["title"] == avant["title"]


@pytest.mark.spec("SPEC-002.3")
@pytest.mark.parametrize("idx", range(6), ids=["admin_list_accounts", "admin_set_active",
                                               "reassign_task", "offer_help", "request_help",
                                               "respond_proposal"])
def test_inactif_rpc_metier_refusees(jeu, fabrique, inactif, admin, idx):
    cible = fabrique(actif=False)
    nom, args = rpcs_metier(jeu, cible.id)[idx]
    if nom == "admin_set_active":
        args["p_user"] = inactif.id  # tentative d'auto-activation
    r = inactif.rpc(nom, **args)
    assert refus(r), f"{nom} → {r.status_code} {r.text[:200]}"
    assert inactif.status()["is_active"] is False
    assert admin.task(jeu["task"]["id"])["assignee_id"] == jeu["a"].id
    assert not [p for p in propositions_recues(jeu["a"], jeu["task"]["id"])
                if p["from_user"] == inactif.id]


@pytest.mark.spec("SPEC-002.3")
@pytest.mark.spec("SPEC-002.5")
def test_inactif_ne_peut_pas_s_activer_par_patch_profiles(inactif, admin):
    r = inactif.patch("profiles", {"id": f"eq.{inactif.id}"}, {"is_active": True, "role": "admin"})
    assert sans_effet(r), f"{r.status_code} {r.text[:200]}"
    row = compte_admin(admin, user_id=inactif.id)[0]
    assert row["is_active"] is False and row["role"] == "member"


# =========================================================================== SPEC-002.4
@pytest.mark.spec("SPEC-002.4")
def test_inscription_cree_profil_membre_inactif_visible_admin(inactif, admin):
    rows = compte_admin(admin, user_id=inactif.id)
    assert len(rows) == 1
    p = rows[0]
    assert p["role"] == "member"
    assert p["is_active"] is False
    assert p["display_name"] == inactif.display_name
    assert (p["email"] or "").lower() == inactif.email.lower()
    assert p.get("created_at")
    assert p.get("activated_at") is None


@pytest.mark.spec("SPEC-002.4")
@pytest.mark.spec("SPEC-002.13")
def test_inscrit_non_active_absent_de_team_load(inactif, admin):
    assert admin.load(inactif.id) is None


# =========================================================================== SPEC-002.5
@pytest.mark.spec("SPEC-002.5")
def test_admin_active_un_compte(inactif, admin):
    r = admin.rpc("admin_set_active", p_user=inactif.id, p_active=True)
    assert 200 <= r.status_code < 300, r.text[:200]
    row = compte_admin(admin, user_id=inactif.id)[0]
    assert row["is_active"] is True and row.get("activated_at")
    assert inactif.status()["is_active"] is True


@pytest.mark.spec("SPEC-002.5")
def test_membre_non_admin_ne_peut_pas_activer(membre, inactif, admin):
    r = membre.rpc("admin_set_active", p_user=inactif.id, p_active=True)
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert compte_admin(admin, user_id=inactif.id)[0]["is_active"] is False


@pytest.mark.spec("SPEC-002.5")
def test_membre_non_admin_ne_peut_pas_lister_les_comptes(membre):
    assert refus(membre.rpc("admin_list_accounts"))


@pytest.mark.spec("SPEC-002.5")
@pytest.mark.parametrize("cible", ["soi", "autre_inactif", "autre_actif"])
def test_membre_patch_profiles_sans_effet(membre, collegue, inactif, admin, cible):
    uid = {"soi": membre.id, "autre_inactif": inactif.id, "autre_actif": collegue.id}[cible]
    avant = compte_admin(admin, user_id=uid)[0]
    r = membre.patch("profiles", {"id": f"eq.{uid}"},
                     {"role": "admin", "is_active": not avant["is_active"], "display_name": "pirate"})
    assert sans_effet(r), f"{r.status_code} {r.text[:200]}"
    apres = compte_admin(admin, user_id=uid)[0]
    assert (apres["role"], apres["is_active"], apres["display_name"]) == \
           (avant["role"], avant["is_active"], avant["display_name"])


# =========================================================================== SPEC-002.6
@pytest.mark.spec("SPEC-002.6")
def test_apres_activation_nouveau_jeton_voit_team_load_et_tasks(fabrique, membre, anon_key):
    t = membre.create_task(title=f"visible-{uuid.uuid4().hex[:8]}")
    u = fabrique(actif=False)
    assert u.get("tasks").status_code >= 400 or u.get("tasks").json() == []
    fabrique.activer(u.id)
    neuf = connecter(anon_key, u.email, u.password)
    assert neuf.status()["is_active"] is True
    assert neuf.load(u.id) is not None, "le compte activé n'apparaît pas dans team_load"
    assert neuf.load(membre.id) is not None
    assert [x for x in neuf.rows("tasks", id=f"eq.{t['id']}")], "tâche d'un collègue invisible"


# =========================================================================== SPEC-002.7
@pytest.mark.spec("SPEC-002.7")
def test_creation_tache_valide_201_todo_affectee_a_soi(membre):
    r = membre.post("tasks", {"title": "Ma tâche", "description": "facultative",
                              "estimate_hours": 2.5, "assignee_id": membre.id})
    assert r.status_code == 201, r.text[:200]
    t = r.json()[0]
    assert t["status"] == "todo"
    assert t["created_by"] == membre.id and t["assignee_id"] == membre.id
    assert approx(t["estimate_hours"], 2.5)


@pytest.mark.spec("SPEC-002.7")
def test_creation_tache_sans_description_acceptee(membre):
    t = membre.create_task(title="Sans description", estimate=1)
    assert t.get("description") in (None, "")


@pytest.mark.spec("SPEC-002.7")
@pytest.mark.parametrize("corps", [
    {"title": "", "estimate_hours": 1},
    {"title": "   ", "estimate_hours": 1},
    {"estimate_hours": 1},
    {"title": "Sans estimation"},
    {"title": "Estimation nulle", "estimate_hours": 0},
    {"title": "Estimation négative", "estimate_hours": -1},
], ids=["titre-vide", "titre-espaces", "titre-absent", "estimation-absente",
        "estimation-0", "estimation-negative"])
def test_creation_tache_invalide_400_sans_creation(membre, corps):
    avant = len(membre.rows("tasks", created_by=f"eq.{membre.id}"))
    r = membre.post("tasks", {**corps, "assignee_id": membre.id})
    assert r.status_code == 400, f"{r.status_code} {r.text[:200]}"
    assert len(membre.rows("tasks", created_by=f"eq.{membre.id}")) == avant


@pytest.mark.spec("SPEC-002.7")
def test_creation_tache_affectee_a_autrui_refusee(membre, collegue, admin):
    titre = f"autrui-{uuid.uuid4().hex}"
    r = membre.post("tasks", {"title": titre, "estimate_hours": 1, "assignee_id": collegue.id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert admin.rows("tasks", title=f"eq.{titre}") == []


@pytest.mark.spec("SPEC-002.7")
def test_creation_tache_created_by_usurpe_refusee(membre, collegue, admin):
    titre = f"usurpe-{uuid.uuid4().hex}"
    r = membre.post("tasks", {"title": titre, "estimate_hours": 1, "assignee_id": membre.id,
                              "created_by": collegue.id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert admin.rows("tasks", title=f"eq.{titre}") == []


# =========================================================================== SPEC-002.8
MODIF = {"title": "Titre modifié", "description": "Desc modifiée", "estimate_hours": 6.5,
         "status": "in_progress"}


def verifier_modif(api, task_id):
    t = api.task(task_id)
    assert t["title"] == MODIF["title"] and t["description"] == MODIF["description"]
    assert approx(t["estimate_hours"], MODIF["estimate_hours"]) and t["status"] == "in_progress"


@pytest.mark.spec("SPEC-002.8")
def test_affecte_modifie_titre_description_estimation_statut(membre):
    t = membre.create_task()
    r = membre.patch("tasks", {"id": f"eq.{t['id']}"}, MODIF)
    assert r.status_code == 200 and len(r.json()) == 1, r.text[:200]
    verifier_modif(membre, t["id"])


@pytest.mark.spec("SPEC-002.8")
@pytest.mark.parametrize("statut", ["todo", "in_progress", "done"])
def test_affecte_change_le_statut(membre, statut):
    t = membre.create_task()
    membre.set_status(t["id"], statut)
    assert membre.task(t["id"])["status"] == statut


@pytest.mark.spec("SPEC-002.8")
def test_statut_hors_liste_refuse(membre):
    t = membre.create_task()
    assert refus(membre.patch("tasks", {"id": f"eq.{t['id']}"}, {"status": "blocked"}))
    assert membre.task(t["id"])["status"] == "todo"


@pytest.mark.spec("SPEC-002.8")
def test_createur_non_affecte_peut_modifier(membre, collegue):
    t = membre.create_task()
    r = membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id)
    assert 200 <= r.status_code < 300, f"reassign_task → {r.status_code} {r.text[:200]}"
    r = membre.patch("tasks", {"id": f"eq.{t['id']}"}, MODIF)
    assert r.status_code == 200 and len(r.json()) == 1, r.text[:200]
    verifier_modif(membre, t["id"])


@pytest.mark.spec("SPEC-002.8")
def test_tiers_ne_peut_pas_modifier_la_tache(membre, tiers):
    """CA-002-16"""
    t = membre.create_task(title="Intouchable", estimate=2)
    r = tiers.patch("tasks", {"id": f"eq.{t['id']}"}, MODIF)
    assert sans_effet(r), f"{r.status_code} {r.text[:200]}"
    apres = membre.task(t["id"])
    assert apres["title"] == "Intouchable" and approx(apres["estimate_hours"], 2)
    assert apres["status"] == "todo"


@pytest.mark.spec("SPEC-002.8")
@pytest.mark.parametrize("colonne", ["assignee_id", "created_by"])
@pytest.mark.parametrize("acteur", ["affecte", "tiers"])
def test_patch_direct_assignee_ou_created_by_refuse(membre, collegue, admin, colonne, acteur):
    t = membre.create_task()
    api = membre if acteur == "affecte" else collegue
    r = api.patch("tasks", {"id": f"eq.{t['id']}"}, {colonne: collegue.id})
    assert sans_effet(r), f"{r.status_code} {r.text[:200]}"
    apres = admin.task(t["id"])
    assert apres["assignee_id"] == membre.id and apres["created_by"] == membre.id


@pytest.mark.spec("SPEC-002.8")
def test_admin_ne_peut_pas_patcher_assignee_id(membre, collegue, admin):
    t = membre.create_task()
    assert sans_effet(admin.patch("tasks", {"id": f"eq.{t['id']}"}, {"assignee_id": collegue.id}))
    assert admin.task(t["id"])["assignee_id"] == membre.id


# =========================================================================== SPEC-002.9
@pytest.mark.spec("SPEC-002.9")
def test_membre_lit_les_taches_d_un_collegue_via_task_summary(membre, collegue):
    t1 = collegue.create_task(title="Coll 1", estimate=3)
    collegue.create_task(title="Coll 2", estimate=1)
    collegue.log(t1["id"], 90)
    rows = membre.rows("task_summary", assignee_id=f"eq.{collegue.id}")
    assert {r["title"] for r in rows} == {"Coll 1", "Coll 2"}
    r1 = next(r for r in rows if r["id"] == t1["id"])
    assert r1["status"] == "todo" and approx(r1["estimate_hours"], 3)
    assert approx(r1["logged_hours"], 1.5) and approx(r1["remaining_hours"], 1.5)
    assert r1["assignee_name"] == collegue.display_name


@pytest.mark.spec("SPEC-002.9")
def test_logged_hours_compte_toutes_les_saisies_quel_qu_en_soit_l_auteur(membre, collegue):
    t = membre.create_task(estimate=5)
    membre.log(t["id"], 60)
    assert 200 <= membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id).status_code < 300
    collegue.log(t["id"], 30)
    assert approx(collegue.task(t["id"])["logged_hours"], 1.5)


# =========================================================================== SPEC-002.10
@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_par_affecte_augmente_logged_hours(membre):
    t = membre.create_task(estimate=4)
    e = membre.log(t["id"], 90)
    assert e["user_id"] == membre.id
    assert approx(membre.task(t["id"])["logged_hours"], 1.5)
    membre.log(t["id"], 15)
    assert approx(membre.task(t["id"])["logged_hours"], 1.75)


@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_date_par_defaut_aujourd_hui(membre):
    t = membre.create_task()
    e = membre.log(t["id"], 10)
    assert e["work_date"] in aujourdhui_possibles()


@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_date_explicite(membre):
    t = membre.create_task()
    hier = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
    assert membre.log(t["id"], 10, work_date=hier)["work_date"] == hier


@pytest.mark.spec("SPEC-002.10")
@pytest.mark.parametrize("minutes", [1, 1440])
def test_saisie_temps_bornes_acceptees(membre, minutes):
    t = membre.create_task(estimate=30)
    membre.log(t["id"], minutes)
    assert approx(membre.task(t["id"])["logged_hours"], minutes / 60)


@pytest.mark.spec("SPEC-002.10")
@pytest.mark.parametrize("minutes", [0, -30, 1441])
def test_saisie_temps_duree_invalide_400(membre, minutes):
    t = membre.create_task()
    r = membre.post("time_entries", {"task_id": t["id"], "minutes": minutes})
    assert r.status_code == 400, f"{r.status_code} {r.text[:200]}"
    assert approx(membre.task(t["id"])["logged_hours"], 0)


@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_par_non_affecte_refusee(membre, tiers):
    """CA-002-20"""
    t = membre.create_task()
    r = tiers.post("time_entries", {"task_id": t["id"], "minutes": 60})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert approx(membre.task(t["id"])["logged_hours"], 0)


@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_par_createur_apres_reaffectation_refusee(membre, collegue):
    """CA-002-20 : la tâche n'est plus affectée au créateur."""
    t = membre.create_task()
    assert 200 <= membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id).status_code < 300
    assert refus(membre.post("time_entries", {"task_id": t["id"], "minutes": 60}))
    assert approx(collegue.task(t["id"])["logged_hours"], 0)


@pytest.mark.spec("SPEC-002.10")
def test_saisie_temps_au_nom_d_autrui_refusee(membre, collegue):
    t = membre.create_task()
    r = membre.post("time_entries", {"task_id": t["id"], "minutes": 60, "user_id": collegue.id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert approx(membre.task(t["id"])["logged_hours"], 0)


# =========================================================================== SPEC-002.11
@pytest.mark.spec("SPEC-002.11")
def test_jeu_de_reference_charge_projetee_3h(membre):
    """CA-002-22 : A 4 h / 1 h loguée (todo), B 2 h / 3 h loguées (in_progress), C 5 h done ⇒ 3 h."""
    a = membre.create_task(title="A", estimate=4)
    membre.log(a["id"], 60)
    b = membre.create_task(title="B", estimate=2)
    membre.log(b["id"], 180)
    membre.set_status(b["id"], "in_progress")
    c = membre.create_task(title="C", estimate=5)
    membre.set_status(c["id"], "done")
    charge = membre.load(membre.id)
    assert charge is not None
    assert approx(charge["projected_hours"], 3.0), charge
    assert charge["overloaded"] is False
    assert charge["open_tasks"] == 2
    assert charge["display_name"] == membre.display_name


@pytest.mark.spec("SPEC-002.11")
def test_charge_nulle_sans_tache(membre):
    charge = membre.load(membre.id)
    assert charge is not None and approx(charge["projected_hours"], 0)
    assert charge["open_tasks"] == 0 and charge["overloaded"] is False


# =========================================================================== SPEC-002.12
@pytest.mark.spec("SPEC-002.12")
def test_seuil_surcharge_7h_strict(membre):
    """CA-002-23 : 7,00 ⇒ false ; 7,25 ⇒ true ; retour à ≤ 7 après « done » ⇒ false."""
    membre.create_task(estimate=4)
    membre.create_task(estimate=3)
    ch = membre.load(membre.id)
    assert approx(ch["projected_hours"], 7.0) and ch["overloaded"] is False, ch
    petite = membre.create_task(estimate=0.25)
    ch = membre.load(membre.id)
    assert approx(ch["projected_hours"], 7.25) and ch["overloaded"] is True, ch
    membre.set_status(petite["id"], "done")
    ch = membre.load(membre.id)
    assert approx(ch["projected_hours"], 7.0) and ch["overloaded"] is False, ch


@pytest.mark.spec("SPEC-002.12")
@pytest.mark.parametrize("minutes_loguees,attendu", [(50, 1.25), (55, 1.0)],
                         ids=["reste-1h10-donne-1.25", "reste-1h05-donne-1.00"])
def test_arrondi_au_quart_d_heure(membre, minutes_loguees, attendu):
    t = membre.create_task(estimate=2)
    membre.log(t["id"], minutes_loguees)
    assert approx(membre.load(membre.id)["projected_hours"], attendu)


@pytest.mark.spec("SPEC-002.12")
def test_temps_depasse_ne_rend_pas_la_charge_negative(membre):
    t = membre.create_task(estimate=1)
    membre.log(t["id"], 300)
    membre.create_task(estimate=2)
    assert approx(membre.load(membre.id)["projected_hours"], 2.0)
    assert approx(membre.task(t["id"])["remaining_hours"], 0)


# =========================================================================== SPEC-002.13
@pytest.mark.spec("SPEC-002.13")
def test_team_load_contient_les_actifs_seulement(membre, collegue, inactif):
    ids = {r["user_id"] for r in membre.rows("team_load")}
    assert {membre.id, collegue.id} <= ids
    assert inactif.id not in ids


# =========================================================================== SPEC-002.14
@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_par_affecte_vers_actif_et_charges_recalculees(membre, collegue):
    t = membre.create_task(estimate=3)
    avant_m = float(membre.load(membre.id)["projected_hours"])
    avant_c = float(membre.load(collegue.id)["projected_hours"])
    r = membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id)
    assert 200 <= r.status_code < 300, r.text[:200]
    assert membre.task(t["id"])["assignee_id"] == collegue.id
    assert approx(membre.load(membre.id)["projected_hours"], avant_m - 3)
    assert approx(membre.load(collegue.id)["projected_hours"], avant_c + 3)


@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_vers_compte_inactif_refusee(membre, inactif):
    """CA-002-26"""
    t = membre.create_task()
    assert refus(membre.rpc("reassign_task", p_task=t["id"], p_to=inactif.id))
    assert membre.task(t["id"])["assignee_id"] == membre.id


@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_vers_compte_inexistant_refusee(membre):
    t = membre.create_task()
    assert refus(membre.rpc("reassign_task", p_task=t["id"], p_to=str(uuid.uuid4())))
    assert membre.task(t["id"])["assignee_id"] == membre.id


@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_par_tiers_refusee(membre, collegue, tiers):
    """CA-002-26"""
    t = membre.create_task()
    assert refus(tiers.rpc("reassign_task", p_task=t["id"], p_to=collegue.id))
    assert refus(tiers.rpc("reassign_task", p_task=t["id"], p_to=tiers.id))
    assert membre.task(t["id"])["assignee_id"] == membre.id


@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_par_createur_non_affecte_refusee(membre, collegue, tiers):
    """CA-002-26 : le créateur n'est plus l'affecté."""
    t = membre.create_task()
    assert 200 <= membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id).status_code < 300
    assert refus(membre.rpc("reassign_task", p_task=t["id"], p_to=tiers.id))
    assert membre.task(t["id"])["assignee_id"] == collegue.id


@pytest.mark.spec("SPEC-002.14")
def test_reaffectation_tache_terminee_ou_vers_soi_refusee(membre, collegue):
    t = membre.create_task()
    assert refus(membre.rpc("reassign_task", p_task=t["id"], p_to=membre.id))
    membre.set_status(t["id"], "done")
    assert refus(membre.rpc("reassign_task", p_task=t["id"], p_to=collegue.id))
    assert membre.task(t["id"])["assignee_id"] == membre.id


# =========================================================================== SPEC-002.15
@pytest.mark.spec("SPEC-002.15")
def test_offer_help_cree_proposition_visible_emetteur_et_destinataire(membre, collegue, tiers):
    t = membre.create_task()
    r = collegue.rpc("offer_help", p_task=t["id"])
    assert 200 <= r.status_code < 300, r.text[:200]
    pid = un(r.json())
    for api in (collegue, membre):
        rows = api.rows("help_proposals", id=f"eq.{pid}")
        assert len(rows) == 1, f"proposition invisible pour {api.display_name}"
        p = rows[0]
        assert (p["kind"], p["from_user"], p["to_user"], p["status"], p["task_id"]) == \
               ("offer", collegue.id, membre.id, "pending", t["id"])
    assert tiers.rows("help_proposals", id=f"eq.{pid}") == []


@pytest.mark.spec("SPEC-002.15")
def test_offer_help_sur_tache_terminee_refuse(membre, collegue):
    t = membre.create_task()
    membre.set_status(t["id"], "done")
    assert refus(collegue.rpc("offer_help", p_task=t["id"]))
    assert propositions_recues(membre, t["id"]) == []


@pytest.mark.spec("SPEC-002.15")
def test_offer_help_par_l_affecte_lui_meme_refuse(membre):
    t = membre.create_task()
    assert refus(membre.rpc("offer_help", p_task=t["id"]))
    assert membre.rows("help_proposals", task_id=f"eq.{t['id']}") == []


@pytest.mark.spec("SPEC-002.15")
def test_offer_help_doublon_pending_refuse(membre, collegue):
    t = membre.create_task()
    assert 200 <= collegue.rpc("offer_help", p_task=t["id"]).status_code < 300
    assert refus(collegue.rpc("offer_help", p_task=t["id"]))
    assert len(propositions_recues(membre, t["id"])) == 1


@pytest.mark.spec("SPEC-002.15")
def test_insertion_directe_help_proposals_refusee(membre, collegue):
    t = membre.create_task()
    r = collegue.post("help_proposals", {"task_id": t["id"], "kind": "offer",
                                         "from_user": collegue.id, "to_user": membre.id})
    assert refus(r), f"{r.status_code} {r.text[:200]}"
    assert propositions_recues(membre, t["id"]) == []


# =========================================================================== SPEC-002.16
@pytest.mark.spec("SPEC-002.16")
def test_request_help_vers_actif_recue_par_le_destinataire(membre, collegue):
    t = membre.create_task()
    r = membre.rpc("request_help", p_task=t["id"], p_to=collegue.id)
    assert 200 <= r.status_code < 300, r.text[:200]
    rows = propositions_recues(collegue, t["id"])
    assert len(rows) == 1
    p = rows[0]
    assert (p["kind"], p["from_user"], p["status"]) == ("request", membre.id, "pending")


@pytest.mark.spec("SPEC-002.16")
def test_request_help_vers_inactif_refuse(membre, inactif):
    t = membre.create_task()
    assert refus(membre.rpc("request_help", p_task=t["id"], p_to=inactif.id))
    assert membre.rows("help_proposals", task_id=f"eq.{t['id']}") == []


@pytest.mark.spec("SPEC-002.16")
def test_request_help_par_non_affecte_ou_vers_soi_refuse(membre, collegue, tiers):
    t = membre.create_task()
    assert refus(tiers.rpc("request_help", p_task=t["id"], p_to=collegue.id))
    assert refus(membre.rpc("request_help", p_task=t["id"], p_to=membre.id))
    assert propositions_recues(collegue, t["id"]) == []


@pytest.mark.spec("SPEC-002.16")
def test_request_help_tache_terminee_ou_doublon_refuse(membre, collegue):
    t = membre.create_task()
    assert 200 <= membre.rpc("request_help", p_task=t["id"], p_to=collegue.id).status_code < 300
    assert refus(membre.rpc("request_help", p_task=t["id"], p_to=collegue.id))
    t2 = membre.create_task()
    membre.set_status(t2["id"], "done")
    assert refus(membre.rpc("request_help", p_task=t2["id"], p_to=collegue.id))


# =========================================================================== SPEC-002.17
def proposition(api, pid):
    rows = api.rows("help_proposals", id=f"eq.{pid}")
    assert len(rows) == 1
    return rows[0]


@pytest.mark.spec("SPEC-002.17")
def test_accepter_offer_affecte_la_tache_au_proposant(membre, collegue):
    """CA-002-29 « Proposer mon aide » : le preneur est le proposant (from_user)."""
    t = membre.create_task(estimate=2)
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    r = membre.rpc("respond_proposal", p_id=pid, p_accept=True)
    assert 200 <= r.status_code < 300, r.text[:200]
    assert membre.task(t["id"])["assignee_id"] == collegue.id
    p = proposition(collegue, pid)
    assert p["status"] == "accepted" and p["decided_at"]
    assert approx(membre.load(collegue.id)["projected_hours"], 2)
    assert approx(membre.load(membre.id)["projected_hours"], 0)


@pytest.mark.spec("SPEC-002.17")
def test_accepter_request_affecte_la_tache_au_destinataire(membre, collegue):
    """CA-002-29 « Demander de l'aide » : le preneur est le destinataire (to_user)."""
    t = membre.create_task()
    r = membre.rpc("request_help", p_task=t["id"], p_to=collegue.id)
    pid = un(r.json())
    r = collegue.rpc("respond_proposal", p_id=pid, p_accept=True)
    assert 200 <= r.status_code < 300, r.text[:200]
    assert membre.task(t["id"])["assignee_id"] == collegue.id
    assert proposition(membre, pid)["status"] == "accepted"


@pytest.mark.spec("SPEC-002.17")
@pytest.mark.parametrize("sens", ["offer", "request"])
def test_refuser_laisse_l_affectation_inchangee(membre, collegue, sens):
    """CA-002-30"""
    t = membre.create_task()
    if sens == "offer":
        pid, dest, emet = un(collegue.rpc("offer_help", p_task=t["id"]).json()), membre, collegue
    else:
        pid = un(membre.rpc("request_help", p_task=t["id"], p_to=collegue.id).json())
        dest, emet = collegue, membre
    r = dest.rpc("respond_proposal", p_id=pid, p_accept=False)
    assert 200 <= r.status_code < 300, r.text[:200]
    assert membre.task(t["id"])["assignee_id"] == membre.id
    p = proposition(emet, pid)
    assert p["status"] == "refused" and p["decided_at"]


# =========================================================================== SPEC-002.18
@pytest.mark.spec("SPEC-002.18")
def test_seul_le_destinataire_peut_repondre(membre, collegue, tiers):
    """CA-002-31"""
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    for intrus in (collegue, tiers):  # émetteur, puis tiers
        for accept in (True, False):
            assert refus(intrus.rpc("respond_proposal", p_id=pid, p_accept=accept))
    assert proposition(membre, pid)["status"] == "pending"
    assert membre.task(t["id"])["assignee_id"] == membre.id


@pytest.mark.spec("SPEC-002.18")
def test_admin_non_destinataire_ne_peut_pas_repondre(membre, collegue, admin):
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    assert refus(admin.rpc("respond_proposal", p_id=pid, p_accept=True))
    assert proposition(membre, pid)["status"] == "pending"


@pytest.mark.spec("SPEC-002.18")
@pytest.mark.parametrize("premiere", [True, False], ids=["deja-acceptee", "deja-refusee"])
def test_proposition_deja_traitee_ne_peut_plus_etre_acceptee(membre, collegue, premiere):
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    assert 200 <= membre.rpc("respond_proposal", p_id=pid, p_accept=premiere).status_code < 300
    assert refus(membre.rpc("respond_proposal", p_id=pid, p_accept=True))
    assert refus(membre.rpc("respond_proposal", p_id=pid, p_accept=False))
    attendu = "accepted" if premiere else "refused"
    assert proposition(membre, pid)["status"] == attendu


@pytest.mark.spec("SPEC-002.18")
def test_proposition_expiree_apres_reaffectation(membre, collegue, tiers):
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    assert 200 <= membre.rpc("reassign_task", p_task=t["id"], p_to=tiers.id).status_code < 300
    assert proposition(collegue, pid)["status"] == "expired"
    assert refus(membre.rpc("respond_proposal", p_id=pid, p_accept=True))
    assert tiers.task(t["id"])["assignee_id"] == tiers.id


@pytest.mark.spec("SPEC-002.18")
def test_proposition_expiree_apres_passage_a_done(membre, collegue):
    t = membre.create_task()
    pid = un(membre.rpc("request_help", p_task=t["id"], p_to=collegue.id).json())
    membre.set_status(t["id"], "done")
    assert proposition(membre, pid)["status"] == "expired"
    assert refus(collegue.rpc("respond_proposal", p_id=pid, p_accept=True))
    assert membre.task(t["id"])["assignee_id"] == membre.id


@pytest.mark.spec("SPEC-002.18")
def test_acceptation_expire_les_autres_propositions_pending(membre, collegue, tiers):
    t = membre.create_task()
    p1 = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    p2 = un(tiers.rpc("offer_help", p_task=t["id"]).json())
    assert 200 <= membre.rpc("respond_proposal", p_id=p1, p_accept=True).status_code < 300
    assert proposition(collegue, p1)["status"] == "accepted"
    assert proposition(tiers, p2)["status"] == "expired"
    assert refus(membre.rpc("respond_proposal", p_id=p2, p_accept=True))
    assert membre.task(t["id"])["assignee_id"] == collegue.id


@pytest.mark.spec("SPEC-002.18")
def test_patch_direct_help_proposals_refuse(membre, collegue):
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    assert sans_effet(membre.patch("help_proposals", {"id": f"eq.{pid}"}, {"status": "accepted"}))
    assert proposition(membre, pid)["status"] == "pending"
    assert membre.task(t["id"])["assignee_id"] == membre.id


# =========================================================================== SPEC-002.19
@pytest.mark.spec("SPEC-002.19")
def test_compteur_propositions_recues_en_attente(membre, collegue, tiers):
    """CA-002-32"""
    t1, t2, t3 = (membre.create_task() for _ in range(3))
    collegue.rpc("offer_help", p_task=t1["id"])
    tiers.rpc("offer_help", p_task=t2["id"])
    p3 = un(collegue.rpc("offer_help", p_task=t3["id"]).json())
    membre.rpc("respond_proposal", p_id=p3, p_accept=False)
    r = membre.get("help_proposals", params={"to_user": f"eq.{membre.id}", "status": "eq.pending"},
                   headers={"Prefer": "count=exact"})
    assert r.status_code in (200, 206), r.text[:200]
    assert nombre_total(r) == 2


# =========================================================================== SPEC-002.20 (Could)
@pytest.mark.could
@pytest.mark.spec("SPEC-002.20")
def test_desactivation_retire_l_acces(fabrique, admin, anon_key, membre):
    """CA-002-34 (Could)"""
    u = fabrique(actif=True)
    u.create_task()
    assert admin.load(u.id) is not None
    r = admin.rpc("admin_set_active", p_user=u.id, p_active=False)
    assert 200 <= r.status_code < 300, r.text[:200]
    assert admin.load(u.id) is None
    neuf = connecter(anon_key, u.email, u.password)
    assert neuf.status()["is_active"] is False
    for objet in TABLES + VUES:
        assert sans_effet(neuf.get(objet)), objet
    assert refus(neuf.post("tasks", {"title": "x", "estimate_hours": 1, "assignee_id": u.id}))


@pytest.mark.could
@pytest.mark.spec("SPEC-002.20")
def test_admin_ne_peut_pas_se_desactiver_lui_meme(admin):
    assert refus(admin.rpc("admin_set_active", p_user=admin.id, p_active=False))
    assert admin.status()["is_active"] is True


@pytest.mark.could
@pytest.mark.spec("SPEC-002.20")
def test_membre_ne_peut_pas_desactiver_un_compte(membre, collegue, admin):
    assert refus(membre.rpc("admin_set_active", p_user=collegue.id, p_active=False))
    assert compte_admin(admin, user_id=collegue.id)[0]["is_active"] is True


# =========================================================================== SPEC-002.21 (Could)
@pytest.mark.could
@pytest.mark.spec("SPEC-002.21")
def test_filtre_aujourd_hui_sur_due_date(membre):
    """CA-002-35 (Could)"""
    j = datetime.datetime.now(datetime.timezone.utc).date()
    d = lambda n: (j + datetime.timedelta(days=n)).isoformat()
    retard = membre.create_task(title="retard", due_date=d(-1))
    jour = membre.create_task(title="jour", due_date=d(0))
    membre.create_task(title="futur", due_date=d(2))
    membre.create_task(title="sans échéance")
    fini = membre.create_task(title="fini", due_date=d(-1))
    membre.set_status(fini["id"], "done")
    rows = membre.rows("task_summary", assignee_id=f"eq.{membre.id}",
                       due_date=f"lte.{j.isoformat()}", status="neq.done")
    assert {r["id"] for r in rows} == {retard["id"], jour["id"]}


@pytest.mark.could
@pytest.mark.spec("SPEC-002.21")
def test_due_date_facultative_et_modifiable(membre):
    t = membre.create_task()
    assert t.get("due_date") is None
    r = membre.patch("tasks", {"id": f"eq.{t['id']}"}, {"due_date": "2030-01-15"})
    assert r.status_code == 200 and r.json()[0]["due_date"] == "2030-01-15"


# =========================================================================== SPEC-002.22
@pytest.mark.spec("SPEC-002.22")
def test_suppression_de_tache_refusee(membre, admin):
    t = membre.create_task()
    for api in (membre, admin):
        assert sans_effet(api.delete("tasks", {"id": f"eq.{t['id']}"}))
    assert admin.rows("tasks", id=f"eq.{t['id']}")


@pytest.mark.spec("SPEC-002.22")
def test_suppression_et_modification_de_temps_refusees(membre):
    t = membre.create_task(estimate=5)
    e = membre.log(t["id"], 60)
    assert sans_effet(membre.delete("time_entries", {"id": f"eq.{e['id']}"}))
    assert sans_effet(membre.patch("time_entries", {"id": f"eq.{e['id']}"}, {"minutes": 600}))
    assert approx(membre.task(t["id"])["logged_hours"], 1)
    assert membre.rows("time_entries", id=f"eq.{e['id']}")


@pytest.mark.spec("SPEC-002.22")
def test_suppression_de_proposition_et_de_profil_refusees(membre, collegue, admin):
    t = membre.create_task()
    pid = un(collegue.rpc("offer_help", p_task=t["id"]).json())
    assert sans_effet(collegue.delete("help_proposals", {"id": f"eq.{pid}"}))
    assert sans_effet(membre.delete("help_proposals", {"id": f"eq.{pid}"}))
    assert proposition(membre, pid)["status"] == "pending"
    assert sans_effet(membre.delete("profiles", {"id": f"eq.{membre.id}"}))
    assert sans_effet(admin.delete("profiles", {"id": f"eq.{collegue.id}"}))
    assert compte_admin(admin, user_id=membre.id) and compte_admin(admin, user_id=collegue.id)
