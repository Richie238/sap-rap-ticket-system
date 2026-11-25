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

ADT MCP hat die generierte IAM-App `ZUI_TICKET_ITEM_03_O4_0001_G4BA_IBS` sowie SAP-Repository-Objekte für Business-User- und Business-Role-Services gefunden. Im NovaDesk-Paket lieferte die Suche nach `SUSO`, `SIA1` und `SIA2` keine Treffer. Die Repository-Befunde belegen Entwicklungsartefakte. Pflegerechte im Trial-Mandanten und die Einrichtung separat anmeldbarer Business Users mit eingeschränkten Rollen konnten nicht bestätigt werden. Der direkte ADT-MCP-Server meldet für `SUSO` und `SIA1` keinen Anlageadapter. Die vollständige IAM-, DCL- und RAP-Regelung ist deshalb noch nicht eingerichtet. Getrennte Testidentitäten standen für die Sicherheitsabnahme nicht zur Verfügung. [SAP Trial-Onboarding](https://developers.sap.com/tutorials/abap-environment-trial-onboarding) · [SAP Business-User-Administration](https://help.sap.com/docs/ABAP_ENVIRONMENT/abap-environment/ad888b0ab0a74665a22e0a58ef9e9100.html)

[Nachweise und offene Laufzeittests](../FIORI_TEST_RESULTS.md#rollen-und-berechtigungen)

## Eclipse ADT und unabhängige Bestandssperre

Die lokale Eclipse-Installation registriert **Authorization Object** (SUSO) und **Business Catalog** (SIA1). Beide Assistenten wurden im ADT-Projekt geöffnet. Die Paketsuche im SUSO-Assistenten fand `ZZ1_NOVADESK`. SUSO verlangt eine Berechtigungsobjektklasse. Eine erfolgreiche Anlage oder eine serverseitige Berechtigungsablehnung ist bisher nicht nachgewiesen. Das Fehlen der MCP-Anlageadapter ist bestätigt. Aus den geöffneten Eclipse-Dialogen lässt sich weder eine Trial-Sperre noch eine fehlende Benutzerberechtigung ableiten. Business-Role-Zuweisungen und Testanmeldungen bleiben ungeprüft. [SAP Developer Center zu Authorization Objects und Business Catalogs](https://developers.sap.com/tutorials/abap-environment-authorization)

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
