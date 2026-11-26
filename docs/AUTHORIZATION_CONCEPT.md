# NovaDesk Rollen und Berechtigungen

**Status: unvollständig.** Die vier fachlichen Rollen sind noch nicht wirksam.

In `NOVADESK_DEV` sind `ZNVD_TEAM` und `ZNVD_TEAM_MEMBER` aktiv. Die mandantenabhängigen Tabellen speichern Teamkennung, Aktivkennzeichen und Mitgliedschaft pro technischem Benutzer. Die Mitgliedschaft enthält Felder für Benutzer und Zeitpunkt der letzten Änderung. Eine Anwendung zur Pflege und die Auswertung der Tabellen stehen aus.

Die aktive Ticket-DCL verwendet weiterhin `where TRUE`. Das Root-Behavior verwendet globale RAP-Autorisierung. Die folgende fachliche Matrix wird dadurch noch nicht durchgesetzt.

## Freigegebene Zielmatrix

| Operation | Requester | Agent | Manager | Admin |
| --- | --- | --- | --- | --- |
| Tickets, Anhänge, öffentlicher Verlauf und Kommentare lesen | Eigene Tickets | Zugewiesene Tickets im berechtigten Team | Tickets berechtigter Teams | Zusätzliche fachliche Rolle erforderlich |
| Ticket anlegen | Für sich selbst | Gesondertes Anlagerecht | Gesondertes Anlagerecht | Gesondertes Anlagerecht |
| Ticket ändern | Betreff und Beschreibung eigener offener Tickets | Operative Felder zugewiesener, nicht geschlossener Tickets | Operative Felder nicht geschlossener Teamtickets | Zusätzliche fachliche Rolle erforderlich |
| Zuweisen | — | — | Im eigenen Berechtigungsbereich an aktive Teammitglieder mit Agent-Recht | Zusätzliche fachliche Rolle erforderlich |
| Workflow | — | Starten, lösen und wieder öffnen | Starten, lösen, wieder öffnen und schließen | Zusätzliche fachliche Rolle erforderlich |
| Anhänge ändern | Eigene Uploads an eigenen, nicht geschlossenen Tickets | An zugewiesenen, nicht geschlossenen Tickets | An nicht geschlossenen Teamtickets | Zusätzliche fachliche Rolle erforderlich |
| Kommentar hinzufügen | Eigene Tickets | Zugewiesene Tickets im berechtigten Team | Tickets berechtigter Teams | Zusätzliche fachliche Rolle erforderlich |
| Interne Notizen lesen oder hinzufügen | — | Berechtigtes zugewiesenes Ticket und separates Notizrecht | Berechtigtes Teamticket und separates Notizrecht | Zusätzliche fachliche Rolle und Notizrecht erforderlich |
| Ticket löschen | — | — | — | Separates Löschrecht im zugewiesenen Bereich und Audit |
| Rollen und Teammitgliedschaften pflegen | — | — | — | Separate Verwaltungsberechtigung |

Workflow und Änderungen unterliegen zusätzlich dem Ticketzustand. Gespeicherte Beiträge bleiben unveränderbar. Schreiben interner Notizen setzt das Leserecht voraus.

## Datenmodell und Migration

Ticket und Draft enthalten `RequesterUser`, `AssignedAgentUser`, `SupportTeamID` und `MigrationStatus`. Das Root-Behavior deklariert alle vier Felder als schreibgeschützt. Die Persistenzzuordnung ist aktiv. Die technische Identität und der Status werden noch nicht automatisch gesetzt. Die vorhandenen Felder `RequesterID` und `AssignedTo` bleiben als Bestandswerte erhalten. Die technische Anfordereridentität muss bei der Anlage aus der Anmeldung gesetzt werden. Eine Zuweisung erfordert eine aktuelle, aktive Teammitgliedschaft und das fachliche Agent-Recht des Zielbenutzers.

Ein verifiziertes Ticket ohne Agent bleibt für seinen Requester und berechtigte Manager des zugeordneten Teams sichtbar. Der Bearbeitungsstart setzt einen Agenten voraus. Bei Neuanlage ohne Team darf der verifizierte Requester sein Ticket lesen. Die Weiterleitung erfolgt über ein ausdrücklich berechtigtes Routing-Verfahren.

Der aktive Prüfbericht `ZCL_NVD_MIGRATION_CHECK` führt ausschließlich Lesezugriffe aus. Der ADT-Konsolenstart liefert bei leerer Eingabeliste aggregierte Bestands- und Draft-Zahlen. Die Methode `CHECK_ASSIGNMENTS` nimmt eine bestätigte Zuordnungsliste entgegen und zählt eindeutige, mehrdeutige, fehlende und ungültige Zuordnungen sowie unbekannte Tickets. Eine einzelne Zuordnung braucht einen angegebenen Requester und ein aktives Team. Ein angegebener Agent braucht eine aktive Mitgliedschaft. Die Methode prüft dabei keine IAM-Rollenzuweisungen. ABAP Unit hat die leere Eingabe, eine unbekannte Ticketnummer sowie eindeutige, mehrdeutige, fehlende und ungültige Zuordnungen bestanden. Die Klassifikationsfälle laufen mit SQL-Testdoubles. Sie schreiben keine Bestandszuordnungen.

Nur bestätigte Zuordnungen dürfen in einer späteren Migration übernommen werden. Anzeigeinformationen und `CreatedBy` dienen als Hinweise. Ungeklärte Alttickets müssen beim Autorisierungs-Cutover gesperrt werden. Offene Altdrafts sind vor dem Cutover kontrolliert abzuschließen oder zu verwerfen. Es wurden keine Zuordnungen geschrieben, keine Bestandsdaten migriert und keine Drafts verworfen.

## Durchsetzung und Freigabe

IAM stellt Aktivitäts- und Teamberechtigungen bereit. CDS DCL prüft Ticket und direkt adressierbare Leseentitäten einschließlich Subentitäten und Draft Query Views. RAP prüft global die Operationsrechte, instanzbezogen die Datenbeziehung und beim Speichern erneut die wirksamen Rechte und den Ticketstatus. Tests müssen auch Rechteentzug bei offenen Entwürfen sowie direkte Schlüsselabfragen, Navigation und Streams abdecken.

Die aktiven Lese- und Draft-Sichten für Kommentare und interne Notizen verwenden `where FALSE`. Die aktive Service-Definition `ZUI_TICKET_ITEM_03_O4` exponiert ausschließlich Tickets, Anhänge und Verlauf. Die Beitragsschnittstellen bleiben bis zur erfolgreichen Sicherheitsabnahme gesperrt.

## IAM im Trial

ADT MCP hat die generierte IAM-App `ZUI_TICKET_ITEM_03_O4_0001_G4BA_IBS` sowie SAP-Repository-Objekte für Business-User- und Business-Role-Services gefunden. Im NovaDesk-Paket sind Authorization Objects und der Ticketkatalog vorhanden. Die letzte Suche hat keine Katalog-App-Zuordnung vom Typ `SIA7` bestätigt. Die Repository-Befunde belegen Entwicklungsartefakte. Pflegerechte im Trial-Mandanten und die Einrichtung separat anmeldbarer Business Users mit eingeschränkten Rollen konnten nicht bestätigt werden. Der direkte ADT-MCP-Server meldet für `SUSO` und `SIA1` keinen Anlageadapter. Die vollständige IAM-, DCL- und RAP-Regelung ist deshalb noch nicht eingerichtet. Getrennte Testidentitäten standen für die Sicherheitsabnahme nicht zur Verfügung. [SAP Trial-Onboarding](https://developers.sap.com/tutorials/abap-environment-trial-onboarding) · [SAP Business-User-Administration](https://help.sap.com/docs/ABAP_ENVIRONMENT/abap-environment/ad888b0ab0a74665a22e0a58ef9e9100.html)

[Nachweise und offene Laufzeittests](../FIORI_TEST_RESULTS.md#rollen-und-berechtigungen)

## Eclipse ADT und unabhängige Bestandssperre

Die lokale Eclipse-Installation registriert **Authorization Object** (SUSO) und **Business Catalog** (SIA1). Beide Assistenten wurden im ADT-Projekt geöffnet. Die Paketsuche im SUSO-Assistenten fand `ZZ1_NOVADESK`. SUSO verlangt eine Berechtigungsobjektklasse. Die manuelle Anlage im Eclipse-Assistenten ist inzwischen nachgewiesen. Das Fehlen der MCP-Anlageadapter ist bestätigt. Aus den geöffneten Eclipse-Dialogen lässt sich weder eine Trial-Sperre noch eine fehlende Benutzerberechtigung ableiten. Business-Role-Zuweisungen und Testanmeldungen bleiben ungeprüft. [SAP Developer Center zu Authorization Objects und Business Catalogs](https://developers.sap.com/tutorials/abap-environment-authorization)

ADT hat für den Ticket-Root das DCL-Prädikat `MigrationStatus = 'V'` in der Arbeitsversion syntaktisch akzeptiert. Nach der Prüfung wurde die ursprüngliche Arbeitsquelle wiederhergestellt und die aktive Quelle zurückgelesen. Dieser Filter kann unverifizierte aktive Datensätze unabhängig von IAM ausschließen. Der wirksame Lesepfad über Ticketprojektion, Anhang und Verlauf ist nach der Aktivierung im jeweiligen Service und bei direkten Kindzugriffen zu testen. Eine alleinige Aktivierung würde auch einen Lesepfad für alle verifizierten Tickets schaffen und kann offene Drafts und Schreibzugriffe nicht absichern. Vor dem Cutover müssen fachliche IAM-Bedingungen hinzukommen.

Für einen unabhängigen Schutz der übrigen Pfade braucht die Draft Query View eine eigene Regel. Bestandsentwürfe müssen gegen den aktuellen aktiven Ticketstand geprüft werden. Neuanlage-Entwürfe brauchen eine eigene Regel mit serverseitig gesetztem Eigentümer. RAP muss unverifizierte aktive Instanzen bei Update, Delete, Edit, Workflow und Child-Operationen abweisen. Bei `Activate` muss der Speichervorgang die Berechtigungen erneut prüfen. Der Draft-Aktion selbst kann keine Autorisierungsprüfung zugewiesen werden. [SAP Draft Query View](https://help.sap.com/docs/abap-cloud/abap-keywords-standard-abap/ABENBDL_DRAFT_QUERY_VIEW.html) · [SAP Draft Actions](https://help.sap.com/docs/abap-cloud/abap-rap/draft-actions)

## Stand der IAM-Objektanlage und Draft-Sichten

Eclipse ADT zeigte im SUSO-Assistenten für das NovaDesk-Paket die fest vorgegebene SAP-Objektklasse `CPAE`. SAP dokumentiert `CPAE` als einzige Objektklasse für Authorization Objects in SAP BTP ABAP Environment. Eine eigene NovaDesk-Objektklasse ist daher nicht erforderlich. Der SUSO-Assistent behandelte per Accessibility gesetzten Text zunächst als leere Eingabe. Echte Tastatureingaben und das Verlassen des Felds lösten die Validierung aus. Der Name `ZNVD_TKT` wurde akzeptiert und die Anlage mit Objektklasse `CPAE` war erfolgreich. Anschließend wurde `ZNVD_TICKET_BC` angelegt. ADT MCP findet beide Objekte im Paket `ZZ1_NOVADESK`. Der aktive Quellenabruf ist für diese Objektarten im direkten MCP-Zugriff nicht verfügbar. Es wurden keine Benutzerrollen zugewiesen. [SAP Learning zur Objektklasse CPAE](https://learning.sap.com/courses/building-data-models-with-the-abap-dictionary-and-abap-core-data-services/preventing-unauthorized-access-to-data_e73ee8f7-8547-44d6-95a8-2675a62ee0cf)

Die Draft Query Views `ZR_NVD_TICKET_DQ` und `ZR_NVD_ATTACHMENT_DQ` samt eigener `where FALSE`-DCL sind aktiv. Der direkte CDS-Lesetest mit der aktuellen Identität lieferte in beiden Sichten null Zeilen. Die Sichten sind noch nicht im aktiven Behavior angebunden. Der Test belegt weder die Wirkung auf Fiori-Draft-Navigation noch die Wirkung bei offenen Fremdentwürfen.

Eine vorübergehende globale Ticketsperre wurde von der automatischen Freigabeprüfung wegen des Service-Ausfallrisikos abgelehnt. Der inaktive RAP-Entwurf wurde anschließend auf den bisherigen Quellstand zurückgesetzt. Die produktiven Regeln und der Ticketservice sind weiterhin auf dem bisherigen Stand. Insbesondere ist `where TRUE` für den Ticket-Root aktiv. Die fachliche Rollenmatrix und die vollständige Sperre unverifizierter Tickets stehen aus.

### Technisches Team-Berechtigungsfeld

Das Datenelement `ZNVD_TEAM_ID` ist aktiv und verwendet `CHAR(10)`, passend zur Supportteamkennung. Eclipse ADT meldete das Berechtigungsfeld `ZNVD_TEAM` als aktiv. Im aktiven `ZNVD_TKT` der Objektklasse `CPAE` sind `ZNVD_TEAM` und das Aktivitätsfeld `ACTVT` sichtbar. Die hinterlegten Aktivitäten sind `01`, `02`, `03` und `06`. Der Business Catalog `ZNVD_TICKET_BC` ist aktiv und vom Typ **Assignable**.

SAP akzeptierte in einer temporären DCL-Arbeitsversion die Bedingung `MigrationStatus = 'V' and ( SupportTeamID ) = aspect pfcg_auth( ZNVD_TKT, ZNVD_TEAM, ACTVT = '03' )`. Die aktive und die Arbeitsquelle wurden anschließend auf dem bisherigen Stand verifiziert. Dieser Nachweis prüft die technische Referenzierung des Teamfelds. Er enthält keine Rollenunterscheidung und keine Zugriffstests mit Teamrestriktionen.

Die fachlichen Objekte, IAM-App-Verknüpfungen und Restriktionstypen für die Rollenmatrix sowie Business-Role-Zuweisungen und getrennte Testbenutzer stehen aus. Die geschützten Draft Query Views sind noch nicht im aktiven Behavior eingebunden. Kommentar- und Notizschnittstellen bleiben unveröffentlicht.

### Getrennte Berechtigungsobjekte und kombinierte DCL-Prüfung

Eclipse ADT legte sieben weitere Authorization Objects im NovaDesk-Paket an. ADT MCP bestätigte alle Repository-Einträge.

| Objekt | Vorgesehener fachlicher Zweck |
| --- | --- |
| `ZNVD_OWN` | Zugriff auf eigene Tickets |
| `ZNVD_AGT` | Zugriff auf zugewiesene Tickets im berechtigten Team |
| `ZNVD_FLOW` | Workflow-Aktionen |
| `ZNVD_ATT` | Änderungsrechte für Anhänge |
| `ZNVD_CMT` | Kommentierrechte |
| `ZNVD_NOTE` | Gesonderte Rechte für interne Notizen |
| `ZNVD_ADM` | Verwaltungsrechte |

Das Teamfeld wurde in `ZNVD_AGT` gespeichert. Der SAP-Syntaxcheck akzeptierte danach einen DCL-Ausdruck, der den Verifizierungsstatus mit drei Lesepfaden kombiniert. Der Requester-Pfad verlangt technische Eigentümerschaft und `ZNVD_OWN`. Der Agent-Pfad verlangt persönliche Zuweisung, gefülltes Team und `ZNVD_AGT` für dieses Team. Der Manager-Pfad verlangt ein gefülltes Team und `ZNVD_TKT` für dieses Team. Die Prüfung verwendet `ACTVT = '03'`. Der Ausdruck war eine Arbeitsversion. Er wurde nach der Prüfung zurückgesetzt. Die zusätzliche Mitgliedschaftsprüfung, die produktive DCL-Aktivierung und die RAP-Operationsregeln stehen aus.

Im Paket sind weiterhin die generierte Ticket-IAM-App und `ZNVD_TICKET_BC` nachweisbar. Die fachlichen Aktivitäten und Restriktionen der weiteren Objekte, die vollständige IAM-App- und Katalogkonfiguration sowie wirksame Rollenzuweisungen sind offen. Das Trial-Launchpad erreichte den App Finder. Der Zugriff auf Benutzer- und Rollenpflege sowie die Einrichtung separat anmeldbarer Testbenutzer ließen sich darüber nicht bestätigen. Rollenabhängige Laufzeitaussagen bleiben offen.

## Aktive Leseregel und kontrollierte Umstellung

Die eigenständige, im Produktivservice nicht exponierte CDS-Sicht `ZI_NVD_TICKET_READ_SCOPE` mit DCL ist in `NOVADESK_DEV` aktiv. Sie verlangt Verifizierungsstatus `V` und lässt abhängig von den SAP-Aktivitätsrechten eigene Tickets, zugewiesene Tickets mit aktiver Mitgliedschaft in einem aktiven Team oder Tickets eines aktiven, für den Manager berechtigten Teams zu. Die reine Verwaltungsrolle begründet keinen Lesepfad. Die IAM-Prüfobjekte sind `ZNVD_OWN`, `ZNVD_AGT` und `ZNVD_TKT` mit Aktivität `03`.

ABAP Unit mit CDS-Testdoubles und aktivierter DCL-Simulation bestätigt die erlaubten Ticket-IDs für Requester, Agent und Manager sowie ein leeres Ergebnis ohne Leseberechtigung. Im Testbestand sind ein unverifiziertes Ticket, ein Ticket in einem inaktiven Team und eine inaktive Teammitgliedschaft enthalten. Diese Tests greifen auf die neue CDS-Sicht zu. Die OData-Projektion des bestehenden Service verwendet weiterhin ihre bisherige Root-DCL. Das aktive RAP-Behavior bindet die beiden Draft Query Views noch nicht ein.

**Umstellungsreihenfolge und Freigabekriterien**

1. IAM-App, Autorisierungsvorgaben, Restriktionstypen und Katalog fertigstellen. Prüfen, welche SAP-Aktivitäts- und Teamwerte tatsächlich ankommen. Repository-Objekte allein erteilen keine Rechte. Die geprüfte Katalogansicht zeigte den Status *Unpublished*. Die begonnenen Klicks zur Zuordnung der generierten Ticket-IAM-App haben keinen nachweisbaren aktiven Zuordnungseintrag erzeugt.
2. Den lesenden Migrationsprüflauf gegen die bestätigte Zuordnungsliste durchführen und offene Entwürfe erfassen. Ticket- und Draft-Verfügbarkeiten vor der Umstellung abstimmen. Ungeklärte Tickets werden beim Cutover gesperrt. Die Aktivierung einer Statusregel verkleinert den bestehenden sichtbaren Bestand sofort. Eine vorherige globale Servicesperre ist kein Bestandteil des Cutovers.
3. Serverseitige Initialisierung von Eigentümer und Verifizierungsstatus für Neuanlagen und die Instanz-, Feld- und Save-Autorisierung fertigstellen. Requester-Änderungen auf Betreff und Beschreibung begrenzen. Schreibrechte für Workflow, Zuweisung, Anhänge, Löschung und interne Notizen separat prüfen. Für vorhandene Bearbeitungsentwürfe müssen die aktuellen aktiven Zuordnungsdaten und Rechte vor dem Speichern maßgeblich sein.
4. Root, Projektion, abhängige Entitäten, Draft Query Views und RAP-Prüfungen zusammen umstellen. Die Draft-DCL darf eigene neue Entwürfe mit serverseitiger Identität zulassen und muss Bearbeitungsentwürfe am aktiven Ticket prüfen. Ein Rückrollfall braucht eine abgestimmte Sicherung des Zugriffs auf Ticketinhalte.
5. Technische Tests mit simulierten Rechten vor der Umstellung vervollständigen. Die abschließende Sicherheitsfreigabe verlangt getrennte Identitäten ohne Entwickler-Vollzugriff und Nachweise für direkte OData-Schlüssel, Navigation, Streams, Änderungszugriffe und Draft-Aktivierung. Die Beitragsentitäten bleiben bis dahin unveröffentlicht.

**Implementierungsblocker:** Die fachlichen IAM-Restriktionen und die schreibende RAP-Autorisierung sind noch nicht vollständig konfiguriert. Der Umstellungsstand ist dadurch noch nicht betriebssicher. **Testumgebung:** Die Simulation prüft die DCL ohne getrennte Testbenutzer. Für den echten Servicezugriff und die Sicherheitsfreigabe fehlen weiterhin unabhängige Rollenidentitäten.

## RAP-Schreibregeln

`ZCL_NVD_TICKET_WRITE_POLICY` ist aktiv. Die Klasse liest für vorhandene Tickets den aktiven Satz mit aktueller Team- und Mitgliedschaftsinformation. Fehlende Tickets, fehlender technischer Benutzer und unverifizierte Bestandsdaten ergeben keine Schreibrechte. Produktiv angebunden an SAP-IAM sind in der Klasse die Anlagerechte über `ZNVD_OWN` sowie die eigenen, zugewiesenen und teambezogenen Änderungsrechte über `ZNVD_OWN`, `ZNVD_AGT` und `ZNVD_TKT`. Die Klasse wird vom aktiven Ticket-Behavior noch nicht aufgerufen.

Die Auswertung unterscheidet Requester-Felder, operative Felder, Zuweisung, Workflow-Übergänge, Anhänge und getrennte Löschrechte. Die produktive Ermittlung liefert die noch nicht fachlich hinterlegten Einzelrechte für Workflow, Zuweisung, Anhänge und Löschen als verweigert. Sechs ABAP-Unit-Tests prüfen diese Entscheidungen mit synthetischen Rechten. Diese Tests simulieren keine tatsächliche IAM-Zuweisung und keinen RAP-Speichervorgang.

Der [RAP-Arbeitsentwurf](rap-authorization-hooks.patch) enthält die Global Authorization für Create und die Instanzprüfung für vorhandene Tickets bei Update und Delete. SAP akzeptierte ihn in der Syntaxprüfung. Die SAP-Arbeitsversion wurde danach auf den aktiven Stand zurückgesetzt. Der Entwurf ist eine technische Zwischenstufe. Für die Umstellung fehlen die Initialisierung neuer Eigentümer, die Feld- und Aktionsprüfungen am tatsächlichen RAP-Eintrittspunkt, das erneute Prüfen von Draft- und Child-Änderungen vor dem Speichern und die Einbindung der Draft Query Views. Die bereits aktiven Draft-Sichten verweigern derzeit jeden Lesezugriff.

Die Wertehilfe für die Katalog-App-Zuordnung bot die generierte `ZUI_TICKET_ITEM_03_O4_0001_G4BA_IBS` weder unter dem exakten Namen noch unter dem NovaDesk-Servicepräfix an. Die neu angelegte externe IAM-App `ZNVD_TICKET_EXT` ist im Backend auffindbar und besteht den MCP-Objektcheck. Der MCP-Server unterstützt für diesen Objekttyp weder Aktivierung noch das Anlegen einer Katalog-App-Zuordnung (`SIA7`). Die aktive Katalogzuordnung und die fachlichen Restriktionen sind weiterhin nicht nachgewiesen. Der Katalog wurde nicht veröffentlicht. [SAP-Dokumentation zur IAM-App für einen Business Service](https://help.sap.com/docs/sap-btp-abap-environment/abap-environment/developer-defining-iam-app-for-business-service)

## RAP-Integration und Rückfallplan

Aktiv sind die internen CDS-Assoziationen vom Ticket-Root zur geprüften Lesesicht, vom Ticket-Draft zum aktiven Ticket-Lesebereich und vom Anhangsdraft zum Ticket-Draft. Die Ticketprojektion exponiert die neue Root-Assoziation nicht. Der Service und die aktiven DCL- und Behavior-Regeln wurden dadurch nicht umgeschaltet.

Der erweiterte [RAP-Arbeitsentwurf](rap-authorization-hooks.patch) enthält die globale Anlageberechtigung, Instanzprüfungen für Update und Delete, Feld-Prechecks, eine erneute Save-Prüfung über den aktiven Ticketstand, die Aufrufe der Write Policy im Workflow und bei Anhängen, die kontrollierte Initialisierung neuer eigener Drafts sowie die DCL-Vererbung und Draft-Query-Bindungen. Die gemeinsame SAP-Syntaxprüfung bestand nach Aktivierung der privaten CDS-Assoziationen. Die Arbeitsquellen wurden anschließend auf den aktiven Stand zurückgesetzt. Der Patch ist noch kein Freigabestand. Insbesondere fehlen eine wirksame fachliche Zuweisungsaktion, die vollständige IAM-Versorgung der Workflow-, Anhangs- und Löschrechte sowie eine erneute Berechtigungsprüfung für sämtliche Child-Änderungen beim Speichern. Der bestehende Service sperrt unverifizierte Bestandsdaten weiterhin nicht vollständig.

Eclipse ADT zeigte die vorbereitete externe IAM-App `ZNVD_TICKET_EXT` als aktiv. Eine fachliche Servicezuordnung, Katalog-App-Zuordnung und Rollenzuweisung sind weiterhin offen. Der Katalog wurde nicht veröffentlicht. Kommentare und interne Notizen bleiben aus der Service-Definition ausgeschlossen.

### Durchführung und Rückfall

1. Die aktive DCL, den Behavior-Pool, die Behavior Definition, die Service-Definition und die IAM-Zuordnungen vorab sichern. Den lesenden Migrationsprüflauf mit bestätigter Zuordnungsliste ausführen. Offene Entwürfe und die Verfügbarkeit von Testtickets für den Wechsel abstimmen.
2. Vor dem Wechsel die IAM-Restriktionen und die fehlenden RAP-Prüfungen fertigstellen. Aktivierungen, Rechteentzug, Fremddrafts, direkte Anhangs- und Stream-Zugriffe sowie unverifizierte Datensätze im Zielstand prüfen. Bei fehlerhafter Anlage eines eigenen Drafts, unerwartetem Zugriff oder unerklärter Sichtbarkeit die Umstellung anhalten.
3. Die DCLs und das Behaviorset als zusammenhängende Änderung im abgestimmten Wartungsfenster aktivieren. Erfolgskriterien sind ein funktionierender Requester-Erstellpfad, korrekte getrennte Rollen, gesperrter Altbestand und intakte erlaubte Navigation. Freigaben für die Beitragsentitäten sind separat.
4. Bei einer Regression den betroffenen Servicezugriff im Wartungsfenster geschlossen halten, die gesicherten Quellversionen koordiniert wiederherstellen und neu eingeführte IAM-Zuordnungen zurücknehmen. Vor der Wiederöffnung erneut direkte Schlüssellesezugriffe, Anhänge und Draft-Aktivierung prüfen. Eine Rückkehr zur offenen Vorgänger-DCL bei weiterhin zugänglichem Service wäre kein sicherer Rückfall.

### Zuweisung und Anhangsprüfung im Integrationsentwurf

`ZA_NVD_TICKET_ASSIGN` ist als abstrakter Parameter aktiv. Der geprüfte Arbeitsentwurf ergänzt `assignTicket` für aktive Tickets ohne offenen Bearbeitungsentwurf. Er prüft Manager-Änderungsrechte, das aktuelle Team und eine aktive Mitgliedschaft des Zielbenutzers. Der Versuch, zusätzlich die wirksame Agent-IAM-Berechtigung des Zielbenutzers über `AUTHORITY-CHECK ... FOR USER` zu prüfen, wurde vom ABAP-Cloud-Syntaxcheck abgelehnt. Mangels bestätigter unterstützter Prüfung bleibt die Aktion im Entwurf geschlossen. Die Teammitgliedschaft allein ersetzt den Agent-IAM-Nachweis nicht.

Der Entwurf ergänzt getrennte Anhangsprüfungen für Create und Update beim Speichern und in Draft Prepare sowie für Delete beim Speichern. Der erste Check zeigte, dass SAP eine Child-Validierung mit Delete-Trigger in Prepare ablehnt. Nach der Aufteilung bestand der gemeinsame SAP-Syntaxcheck für Policy, Behavior Pool, Root- und Projection Behavior und DCLs. Die Wirkung beim Löschen eines Bearbeitungsentwurfs mit Anhang, bei Draft-Aktivierung und bei Ticket-Löschkaskaden ist im Zielstand noch nachzuweisen.

Die Erweiterung referenziert `ZNVD_FLOW` für Workflow, `ZNVD_ATT` für Anhangsänderungen und `ZNVD_ADM` für Ticket-Delete. Ein separater semantischer SAP-Check zeigte, dass `ZNVD_TEAM` in allen drei Authorization Objects fehlt. Es wurden keine pauschalen Rechte als Ersatz eingerichtet. Die wirksame Service- und Katalogzuordnung von `ZNVD_TICKET_EXT` ist weiterhin offen. Diese Befunde blockieren die Umstellung. Der aktive Ticketservice und die Beitragsschnittstellen wurden nicht umgestellt.

### Entscheidung zur Zielbenutzerprüfung

Für die fehlende wirksame Agent-IAM-Prüfung ist die [Architekturentscheidung](ADR_AGENT_AUTHORIZATION.md) dokumentiert. Die Empfehlung ist ein Manager-Vorschlag mit anschließender Annahme durch den Zielagenten unter seiner eigenen IAM-Identität. Dieser Ablauf benötigt fachliche Freigabe. Der bestehende Integrationsentwurf verweigert Zuweisungen weiterhin.

Die Pflege von `ZNVD_TEAM` in `ZNVD_FLOW`, `ZNVD_ATT` und `ZNVD_ADM` konnte in dieser Sitzung nicht abgeschlossen werden. Die Eclipse-Suche ließ sich für das Zielobjekt nicht stabil im Vordergrund öffnen. Die externe IAM-App hat im geprüften Services-Reiter keine Servicezuordnung angezeigt. Die Katalogzuordnung und getrennte Testidentitäten bleiben unbestätigt. Es wurde keine Service-Umstellung durchgeführt.
