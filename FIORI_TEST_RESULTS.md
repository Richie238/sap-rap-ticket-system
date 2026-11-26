# NovaDesk – Fiori- und Laufzeittests

Die Ergebnisse sind nach dem jeweiligen SAP-Stand dokumentiert. Die Abschnitte zur UX Phase 1, zur ursprünglichen Close-Aktion und zur Nummernvergabe sind historische Testprotokolle. Die dort beschriebene direkte Statusbearbeitung wurde durch die Workflow-Aktionen ersetzt.

## Abschlussabnahme Ticketverlauf am 24. November 2026

Getestet in `NOVADESK_DEV`, Mandant 100, mit Testticket `00010006`. Verwendet wurden die Fiori-Elements-Vorschau des veröffentlichten OData-V4-Bindings `ZUI_TICKET_ITEM_03_O4`, ein direkter OData-Aufruf, das ADT SQL Notebook und ABAP Unit über ADT MCP.

Für die Abnahme gilt der aus SAP gelesene [aktive Quellstand](sap_snapshots/ACTIVE/). Der [Architekturabschnitt](README.md#ticketverlauf) beschreibt die Persistenz im Additional Saver und die Lesefreigabe über die Ticket-DCL.

| Test | Ergebnis | Beobachtung |
| --- | --- | --- |
| Anhang hinzufügen | **Bestanden** | PDF im neuen Ticketentwurf hochgeladen. Vor dem Speichern war der Verlauf leer. Nach regulärer Aktivierung erschien genau einmal „Anhang hinzugefügt“ mit `verlauf.pdf` als Neuwert. |
| Dateiname ändern | **Bestanden** | Nach Speichern erschien genau einmal „Anhang geändert“ mit `verlauf.pdf` als Altwert und `umbenannt.pdf` als Neuwert. |
| Datei bei gleichem Namen ersetzen | **Bestanden** | PDF mit abweichendem SHA-256 und unverändertem Namen `umbenannt.pdf` hochgeladen. Genau ein Eintrag „Anhang ersetzt“ mit demselben Namen in beiden Wertspalten. |
| Anhang löschen | **Bestanden** | Nach Speichern war die Anhangsliste leer. Genau ein Eintrag „Anhang gelöscht“ mit `umbenannt.pdf` als Altwert erschien oben. |
| Draft-Regression mit regulärem Activate | **Bestanden** | Neuanlage und Bearbeitung wurden aktiviert. Nach Neuladen der Fiori-Seite war die ungespeicherte Umbenennung noch im Entwurf sichtbar. Verwerfen stellte den aktiven Dateinamen wieder her. Verwerfen und anschließendes Speichern ohne Änderungen ließen die Zahl der Verlaufseinträge bei vier. Der bestehende ABAP-Test bestätigte zusätzlich, dass ein ungültiger Dateientwurf bei Activate abgelehnt wird. |
| Physischer Erhalt und Zugriff nach Ticketlöschung | **Bestanden** | Vor dem Löschen lieferte das direkte History-Entity-Set fünf Zeilen. Danach lieferte derselbe Filter `value: []`. Der Abruf über eine zuvor ausgegebene Ereignis-UUID lieferte in den Fehlerdetails „Resource not found“. Der direkte SQL-Zugriff auf `ZNVD_TKT_HIST` fand weiterhin sechs Zeilen, je eine pro Attachment-Ereignis sowie `TICKET_CREATED` und `TICKET_DELETED`. |
| Expliziter RAP-Rollback vor dem Speichern | **Bestanden** | In einem temporären isolierten ABAP-Test war eine aktive Attachment-Umbenennung im RAP-Puffer sichtbar. Nach `ROLLBACK ENTITIES` blieben der gespeicherte Dateiname und die Anzahl der Verlaufseinträge gleich. |
| Bestehende ABAP-Regressionstests | **Bestanden** | Alle fünf Tests im Behavior Pool bestanden. |

**Fehlgeschlagen:** Kein funktionaler Abnahmefall. Die Schlüsselabfrage auf ein nach Ticketlöschung ausgeblendetes Ereignis erhält vom Gateway eine generische Provider-Fehlermeldung mit dem Detail „Resource not found“ und ohne Verlaufsdaten.

### Backlog – nicht getestet

| Test | Technische Voraussetzung und Abnahmekriterium |
| --- | --- |
| Berechtigungsprüfung mit zweiter Identität | ADT MCP hatte nur die bestehende NovaDesk-Anmeldung. Die aktive Ticket-DCL enthält `where TRUE` und kann deshalb innerhalb derselben Servicerolle keine unterschiedliche Sichtbarkeit je Ticket erzeugen. Sobald eine zweite Testidentität mit passender Vergleichsrolle und für den instanzbezogenen Test eine Ticket-DCL mit unterschiedlichen Sichtbarkeiten zur Verfügung stehen, Ticketliste, `_History`, direktes History-Entity-Set und Zugriff per Ereignis-UUID vergleichen. |
| Erzwungener Fehler im späten RAP-Save | Für den bereits aktiven Saver steht kein vorhandener, isolierter Fehlerauslöser für das History-`INSERT` zur Verfügung. Den Test in einer isolierten Umgebung mit kontrolliertem Fehler beim Schreiben der Historie ausführen. Danach prüfen, dass Ticket- oder Attachment-Änderung und sämtliche zugehörigen Verlaufszeilen gemeinsam zurückgerollt wurden. |
| Mehrere Workflow-Aktionen in derselben LUW | Die bisherigen Fiori-Tests speicherten jede Aktion separat. In einem gezielten RAP-Test mehrere zulässige Übergänge desselben Tickets vor einem gemeinsamen `COMMIT ENTITIES` ausführen. Fachliche Reihenfolge, Alt- und Neuwerte sowie die Zuordnung der Ereignisse zum gemeinsamen Speichervorgang prüfen. |

Der temporäre Rollback-Test wurde nach der Ausführung entfernt und das ursprüngliche Test-Include wieder aktiviert. Fachlicher Code und Fiori-Metadaten wurden für diese Abnahme nicht geändert.

## Fiori-Abnahme für UX Phase 1 am 23. November 2026

Getestet in Chrome in der SAP Fiori Elements App Preview für `ZC_TICKET_ITEM_03` am veröffentlichten OData-V4-UI-Binding `ZUI_TICKET_ITEM_03_O4`, `NOVADESK_DEV`, Mandant 100. Getesteter Annotationsstand auf GitHub ist `26c1c0f89233a9e799729320b8fb35013d8238fd`.

### Laufzeitsprache

| Vorschauparameter | Beobachtung auf Liste und Objektseite |
| --- | --- |
| `sap-ui-language=EN` im bestehenden Preview-Link | Die Standardaktionen erschienen als „Edit“ und „Delete“. Die Fälligkeit von Ticket `3030` erschien als „Nov 24, 2026“. |
| `sap-ui-language=DE` im separaten Preview-Tab | Dieselben Aktionen erschienen als „Bearbeiten“ und „Löschen“. Die Fälligkeit erschien als „24.11.2026“, die Auditzeitstempel im Format `TT.MM.JJJJ, HH:mm:ss`. |

Der URL-Parameter steuert die beobachtete Umschaltung. Die Kategorietexte wie „Change Request“ sind gespeicherte Referenzwerte. Der Titel der Preview-Shell blieb „Preview for Fiori Elements App“. Für den Sprachvergleich genügte der separate DE-Tab. RAP- und Metadata-Extension-Quellen wurden für diese Abnahme unverändert verwendet.

### Ticketliste, Suche und Filter

Die Liste zeigte Ticketnummer, Betreff, Status, Priorität, Bearbeiter, Kategorie und Fälligkeit in dieser Reihenfolge. Beschreibung und Auditfelder waren in den Objektseitenabschnitten sichtbar. Zusätzlich zu den sechs Fachfiltern zeigte Fiori den Draft-Filter „Bearbeitungsstatus“.

| Fachfilter | Einzeln getesteter Wert | Ergebnis |
| --- | --- | --- |
| Ticketnummer | `3030` | Genau Ticket `3030` |
| Status | `B` – In Bearbeitung | Genau Ticket `3030` |
| Priorität | `2` – Mittel | Genau Ticket `3030` |
| Bearbeiter | `IT` | Genau Ticket `3030` |
| Kategorie | `C` – Change Request | Genau Ticket `3030` |
| Fälligkeit | `24.11.2026` | Genau Ticket `3030` |

Die Freitextsuche fand jeweils genau einen Treffer. „SAP Team“ fand Ticket `3030` über den Anforderer. „NovaDesk UX QA“ und „Fiori Lifecycle Test“ fanden das Testticket `91261123` über Betreff und Beschreibung.

### Wertehilfen

Alle drei Wertehilfen öffneten sich in der Filterleiste und im Anlegeformular. Bei Status und Priorität erschien deutscher Klartext, bei Kategorie erschienen die gespeicherten Referenztexte.

| Wertehilfe | Angezeigte Einträge | Nutzung im Formular |
| --- | --- | --- |
| Status | B In Bearbeitung, G Geschlossen, L Gelöst, O Offen | „In Bearbeitung“ und „Gelöst“ ausgewählt und gespeichert |
| Priorität | 1 Niedrig, 2 Mittel, 3 Hoch, 4 Dringend | „Mittel“ ausgewählt und gespeichert |
| Kategorie | A Access Request, C Change Request, H Hardware, I Incident, S Software | „Hardware“ ausgewählt und gespeichert |

### Ticket-Lifecycle

Schreibende Schritte betrafen das eigens angelegte Testticket `91261123` mit Betreff „NovaDesk UX QA“.

| Schritt | Beobachtung |
| --- | --- |
| Anlegen | Der Dialog verlangte eine Ticketnummer. Danach öffnete sich der Entwurf mit initialem Status „Offen“. |
| Speichervalidierung | Ohne Bearbeiter und Fälligkeit blockierte Fiori die Anlage mit den Meldungen „Geben Sie einen Bearbeiter an.“ und „Geben Sie ein Fälligkeitsdatum ab heute an.“. Der Dialog gruppierte die Meldungen unter „Allgemeines“. |
| Aktivieren und lesen | Mit Bearbeiter IT, Fälligkeit 30.11.2026, Priorität Mittel und Kategorie Hardware meldete Fiori „Objekt angelegt“. Die aktive Objektseite zeigte die Werte. |
| Bearbeiten und sichern | „Bearbeiten“ öffnete einen Draft. Die Auswahl „In Bearbeitung“ wurde mit „Objekt gesichert“ bestätigt und auf der aktiven Seite angezeigt. |
| Verwerfen | „Gelöst“ im Entwurf gewählt und den Entwurf verworfen. Fiori meldete „Entwurf verworfen“, die aktive Seite zeigte weiterhin „In Bearbeitung“. |
| Wiederaufnahme | „Gelöst“ erneut im Entwurf gewählt. Nach Neuladen der Seite blieb der Wert im Entwurf erhalten und ließ sich anschließend sichern. |
| Schließen und zurücknavigieren | „Ticket schließen“ setzte Kopf und Ticketdaten unmittelbar auf „Geschlossen“. Nach der Rücknavigation zeigte auch die Liste „Geschlossen“. |
| Löschen und nachprüfen | Das Testticket über die Liste gelöscht. Fiori meldete „Objekt gelöscht“. Die zuvor erfolgreiche Betreffsuche zeigte anschließend „Keine Ergebnisse gefunden“. |

### Offene Punkte

- Die Kategorieanzeige verwendet weiterhin die vorhandenen Referenztexte. Eine Lokalisierung dieser Werte benötigt eine fachliche Entscheidung über die Bezeichnungen und Sprachen.
- „Ticket schließen“ blieb im Entwurf und nach dem Schließen sichtbar. Die gewünschte Verfügbarkeit je Status, Draft und Rolle ist ein separater fachlicher Prüfpunkt. Ausgeführt wurde die Aktion am aktiven Ticket im Status „Gelöst“.
- Die Speichermeldungen wurden beobachtet. Direkte Zuordnung oder Fokus am jeweiligen Eingabefeld, ein Datum in der Vergangenheit, schmale Ansichten, Tastaturnavigation und Rollentests wurden in diesem Lauf nicht separat verifiziert.
- Der Lauf belegt die Fiori-Funktion. OData-Metadaten und Netzwerkanfragen wurden in diesem Lauf nicht separat protokolliert.

## Instanzsteuerung für „Ticket schließen“ am 23. November 2026

SAP ADT meldete für Root-BDEF und Behavior-Pool eine erfolgreiche Syntaxprüfung und Aktivierung. Beide aktiven Quellen wurden zurückgelesen. Die Prüfung verwendet die RAP-EML-Leseoperation mit `%is_draft` für die Entwurfsversion desselben Schlüssels. Nur die EML-Rückmeldung „nicht gefunden“ für den Entwurf gibt eine zulässige aktive Instanz frei. Beide Handler verwenden dieselbe Prüfung. [SAP EML für Draft-BOs](https://help.sap.com/docs/abap-cloud/abap-rap/changing-and-reading-instances-of-draft-bo)

| Fiori-Preview im Mandanten 100 | Beobachtung |
| --- | --- |
| Eigenes Testticket `91261124` aktiv und ohne Entwurf | Aus Offen, In Bearbeitung und Gelöst jeweils über die Aktion geschlossen. Nach jeder Ausführung zeigte die Objektseite sofort „Geschlossen“ und deaktivierte die Aktion. |
| Anlege- und Bearbeitungsentwurf | Aktion jeweils sichtbar, aber deaktiviert. |
| Gespeicherte Version bei eigenem offenem Bearbeitungsentwurf | Nach Aktualisierung war die Aktion deaktiviert. Ein vor der Entwurfsanlage geladener zweiter Tab konnte sie noch auslösen. SAP wies den Aufruf mit einer Sperrmeldung ab, der Status blieb „Offen“. Nach Verwerfen war die Aktion wieder verfügbar. |
| Aktiver Altbestand mit leerem Status | Aktion deaktiviert. Das Ticket wurde nur gelesen. |
| RAP-Standardoperationen | Das eigene Testticket ließ sich bearbeiten, über einen Entwurf speichern und am Ende löschen. Die aktualisierte Liste zeigte nur die beiden vorhandenen Bestandstickets. |

Nicht separat nachgewiesen sind eine fremde Entwurfssitzung, ein abgelaufener Draft-Lock, ein nichtleerer unbekannter Statuscode und der Aufruf des Action-Handlers unter Umgehung der vorgelagerten RAP-Feature-Prüfung. Der beobachtete Negativaufruf lieferte eine RAP-Sperrmeldung und belegt daher nicht separat die eigene `failed`-/`reported`-Meldung des Handlers.

## Automatische Ticketnummern am 23. November 2026

Geprüft in SAP ADT und in der deutschen Fiori-Vorschau von `NOVADESK_DEV`, Mandant 100. Der aktive Schlüssel sowie die Schlüssel beider Draft-Tabellen sind `NUMC(8)`. Vor dem Wechsel enthielt die aktive Tabelle `00000020` und `00003030`. Beide Draft-Tabellen waren leer. Die ADT-Verwendungsanalyse fand zwei Root-Behaviors mit derselben aktiven Tabelle. Die veröffentlichte Projektion verwendet `ZR_TICKET_ITEM_03000`. Der ältere Root `ZR_TICKET_ITEM_03` hat einen schreibgeschützten Schlüssel und im aktiven gemeinsamen Pool keinen eigenen Nummerierungs-Handler.

| Prüfung | Beobachtung |
| --- | --- |
| Nummernkreis | Die ABAP-Konsole hat das interne Intervall `ZNOVATKT/01` mit Grenzen `10000–99999` und deaktiviertem Wiederanlauf aus SAP zurückgelesen. Das aktive Nummernkreisobjekt wurde exportiert. |
| SAP-Syntax, Aktivierung, Rücklesen | Root-BDEF, Behavior-Pool und Setup-Klasse wurden erfolgreich geprüft, aktiviert und aus SAP zurückgelesen. |
| Draft-Anlage | „Anlegen“ öffnete das Formular ohne Nummerneingabe. Kopf und Ticketdaten zeigten sofort die schreibgeschützte Nummer `10000`. |
| Zweiter gleichzeitig offener Draft | In einem zweiten Fiori-Tab derselben SAP-Anmeldung wurde bei offenem ersten Entwurf ein weiterer Entwurf mit Nummer `10010` angelegt. |
| Draft aktivieren und bestehendes Ticket bearbeiten | Fiori meldete „Objekt angelegt“, die aktive Nummer blieb `10000`. Auch im Bearbeitungsentwurf war die Nummer schreibgeschützt. „Sichern“ behielt die Nummer bei. |
| Bestandsanzeige und Testdaten | Die Fiori-Liste zeigte weiterhin `20` und `3030`. Testticket `10000` und Testentwurf `10010` bleiben im Mandanten 100 erhalten. |

Die atomare Reservierung erfolgt über `CL_NUMBERRANGE_RUNTIME=>NUMBER_GET`. Die Nummerierung prüft die reservierte Nummer zusätzlich per RAP EML gegen aktive Daten und Drafts des veröffentlichten BOs. Das Register nutzt Hauptspeicherpufferung, daher sind Lücken möglich. Die fünfstelligen neuen Werte werden im bestehenden Schlüssel mit führenden Nullen auf acht Stellen gespeichert. Fiori unterdrückt die führenden Nullen des Schlüsselfelds bei der Anzeige, daher werden Bestandsnummern wie `20` nicht als `00020` dargestellt. Ein Test mit zwei getrennten SAP-Benutzern und eine Intervallerschöpfung wurden nicht ausgeführt. [SAP Early Numbering](https://help.sap.com/docs/abap-cloud/abap-rap/developing-early-unmanaged-numbering) · [SAP Nummernkreis-Laufzeit](https://help.sap.com/docs/sap-btp-abap-environment/abap-environment/getting-numbers-from-interval)

Das Intervall ist mandantenabhängig. Vor Aktivierung in einem anderen Zielmandanten muss das Intervall separat eingerichtet und gegen die aktiven Daten, beide Draft-Tabellen sowie andere Schreiber auf dieselbe Persistenz geprüft werden. `ZCL_NOVADESK_NR_SETUP` richtet das Intervall in Mandant 100 ein und setzt den Stand eines vorhandenen Intervalls nicht zurück.

## Historischer Prüfstand vom 22. November 2026

Stand 22. November 2026. Alle folgenden Tests im Zielsystem sind **NICHT GETESTET**. Der lokale ADT-MCP-Endpunkt war nicht erreichbar. Für diese Tests wurde kein SAP- oder Browserwerkzeug ausgeführt, und es liegen weder HTTP-Antworten noch eine Service- oder Preview-URL vor. Historische Screenshots zeigen den früheren Stand.

| Prüfebene / Objekt | Werkzeug für den ausstehenden Test | Nächste Aktion und erwarteter Nachweis |
| --- | --- | --- |
| RAP-Backend `ZR_TICKET_ITEM_03`, `ZBP_R_TICKET_ITEM_03`, `ZC_TICKET_ITEM_03` | ADT | Aktive Versionen und Aktivierungsmeldungen gemäß Aktivierungsprotokoll erfassen. Bestehende ABAP Unit Tests nach Sichtung ihrer Seiteneffekte ausführen. |
| OData V4 UI `ZUI_TICKET_ITEM_03_O4` und zugehöriges Binding | ADT und authentifizierter Browser | Aktives Binding öffnen und **Publish** wählen. Die im Editor angezeigte Service-URL verwenden. Service-Dokument, `$metadata` und den dort ausgewiesenen Ticket-Entity-Set mit lesendem GET prüfen. Status, Draft-Aktionen, UI-Annotationen, Value-List-Referenzen und konkrete Fehlermeldungen erfassen. |
| Fiori Elements `ZC_TICKET_ITEM_03` | ADT und externer Browser | In VS Code Serviceversion → **Preview** → Ticket-Entity wählen. In Eclipse Ticket-Entity im Binding-Editor markieren und **Preview** klicken. Preview-Adresse aus dem tatsächlich geöffneten Browser ohne Tokens oder Sitzungsschlüssel erfassen. Liste, Suche und Detailseite öffnen. |
| Eigenständige App / Launchpad | SAP Fiori Tools und Ziel-Launchpad | Falls separat beauftragt, eigenständiges UI5-Projekt aus Serviceversion und Entity erzeugen, deployen, Rollen und Navigation einrichten und vom Launchpad aus starten. |

## Ausstehende Funktionsfälle

Nur eigens für den Test angelegte Tickets in einem isolierten Testmandanten verwenden. Tests, die Daten löschen, bleiben unter dem aktuellen Auftrag offen. Für den Delete-Nachweis eine transaktionsisolierte Testumgebung mit Test-Doubles oder eine gesonderte Freigabe für ein eigens angelegtes Testticket verwenden.

| Fall | Erwarteter Nachweis |
| --- | --- |
| Create / Read | Neues Ticket mit Bearbeiter und gültigem Datum speichern. Nummer und Status `O` erfassen. Ticket nach Aktualisieren der Liste und in der Detailansicht wiederfinden. |
| Update | Betreff und Beschreibung des Testtickets bearbeiten, speichern und erneut lesen. ETag und Änderungszeitstempel anhand der Antworten prüfen. |
| Delete | Über RAP/OData in isolierten Test-Doubles den Testdatensatz entfernen und nachweisen, dass der Schlüssel nicht mehr gelesen werden kann. |
| Draft | Edit und Resume prüfen. Discard im isolierten Testfall prüfen. Activate muss einen gültigen Entwurf genau einmal speichern. |
| Early Numbering | Mehrere Creates pro Request, zwei gleichzeitig offene Entwürfe und parallele Browser-Sitzungen prüfen. Alle Schlüssel müssen verschieden und achtstellig sein. |
| Validations | Bearbeiter und Fälligkeitsdatum jeweils einzeln weglassen. Speichern muss mit feldbezogener Meldung scheitern. Zusätzlich ein vergangenes Datum nach Klärung der Fachregel prüfen. |
| Value Helps | Priorität, Status und Kategorie öffnen, Referenzwerte und Texte auswählen und nach erneutem Laden prüfen. Ungültigen Wert im isolierten Testfall prüfen. |
| Autorisierung | Mit berechtigter und unberechtigter Rolle Sichtbarkeit und Mutation gemäß vereinbarter DCL-/RAP-Policy prüfen. |

Pro Ausführung Datum, Zielmandant, Objekt, Aktion, Werkzeug, beobachtetes Ergebnis, Fehlertext und nächste Aktion ergänzen. [SAP Service Binding](https://help.sap.com/docs/abap-cloud/abap-rap/service-binding) · [SAP OData-V4-Editor für VS Code](https://help.sap.com/docs/abap-cloud/abap-development-tools-for-visual-studio-code/working-with-odata-v4-service-a449458b1816492eb972ae5728ca2a28)


## Workflow und Attachments am 24. November 2026

Geprüft in der Fiori-Elements-Vorschau des OData-V4-UI-Bindings `ZUI_TICKET_ITEM_03_O4` in Mandant 100. Die folgenden Ergebnisse stammen aus der damaligen Abnahme.

### Workflow

| Fall | Beobachtung |
| --- | --- |
| `startWork`, `markResolved`, `closeTicket` | Der Fiori-Durchlauf am separaten Attachment-Testticket erreichte über Offen, In Bearbeitung und Gelöst den Endstatus Geschlossen. |
| `reopenTicket` | Die Action war bei Gelöst sichtbar. Ein eindeutig bestätigter Übergang zurück nach In Bearbeitung ist in den vorliegenden Nachweisen nicht belegt. |
| Draft und Endstatus | In den beobachteten Bearbeitungsentwürfen waren die Workflow-Aktionen in Fiori deaktiviert. Auf dem geschlossenen aktiven Testticket waren alle Workflow-Aktionen deaktiviert. |

Ein gezielter Backend-Nachweis für alle vier Actions gegen eine aktive Instanz mit vorhandenem Draft fehlt. Insbesondere sind fremde Entwürfe und die separate Handler-Ablehnung unabhängig von der RAP-Feature-Prüfung offen.

### Attachments

| Fall | Beobachtung |
| --- | --- |
| OData V4 | Das Modell der Fiori-Vorschau meldete `FileContent` als `Edm.Stream`. |
| PDF-Rundlauf | Eigene PDF-Datei hochgeladen, Ticket aktiviert und erneut geöffnet. Der Download war mit 597 Bytes bytegleich zum Original. |
| PNG und JPEG | PNG ersetzte das PDF und ließ sich speichern. JPEG wurde als zweiter Anhang erstellt und gespeichert. Die MIME-Typen waren `image/png` und `image/jpeg`. |
| Standard-Löschung | PNG in einem Bearbeitungsentwurf gelöscht und gespeichert. Die aktive Liste enthielt danach nur noch JPEG. |
| Draft-Vollständigkeit | Anlegen einer leeren Attachment-Zeile war im Entwurf möglich. Ein leerer Dateiname blockierte die Aktivierung. |
| MIME und Signatur | Der manuelle MIME-Wert `PDF` reproduzierte die Typfehlermeldung. PDF-Inhalt mit `image/jpeg` wurde wegen der abweichenden Signatur zurückgewiesen. Der konkrete MIME-Wert des ursprünglichen gemeldeten Entwurfs war nicht mehr verfügbar. |
| Größenlimit | 10 MiB plus ein Byte wurden bei Aktivierung abgewiesen. Genau 10 MiB wurden nicht separat geprüft. |
| Geschlossenes Ticket | In Fiori blieben Anlegen, Bearbeiten und Löschen gesperrt. Das JPEG ließ sich weiterhin bytegleich herunterladen. Der unveränderte Ticketentwurf wurde erfolgreich gespeichert. |
| Bereinigung | Testticket 10002 wurde über Fiori gelöscht und verschwand aus der Liste. Die eigenen lokalen Testdateien wurden entfernt. |

Die leere Standard-Anhangsseite wurde durch eine Stream-Facette korrigiert. Die ergänzten Attachment-DCLs beseitigten `ACM_UNEXPECTED_VALUE` beim Lesen aktiver Anhänge. Der gespeicherte Dateiname erscheint in der Fiori-Tabelle und im Downloadlink. Ein statisch schreibgeschützter MIME-Typ wurde verworfen, weil er beim Dateiwechsel die Übernahme des neuen Typs durch den Standard-Upload blockierte.

Offen bleiben direkte OData-Schreibversuche gegen geschlossene Tickets, ein separater Test für fremde Bearbeitungsentwürfe und der Laufzeitnachweis der dokumentierten automatischen SAP-Virenprüfung für diesen Stream. Die MIME-Spalte bleibt im Bearbeitungsmodus offener Tickets editierbar. Die serverseitige Validierung ist aktiv.

## Rollen und Berechtigungen

| Prüfung | Ergebnis |
| --- | --- |
| ADT Syntaxprüfung und Aktivierung | `ZNVD_TEAM` und `ZNVD_TEAM_MEMBER` gemeinsam geprüft und aktiviert. Beide aktiven Quellen aus `NOVADESK_DEV` zurückgelesen. |
| Ticket- und Draft-Erweiterung | Ticketpersistenz, Draft-Tabelle, Root-CDS und Root-Behavior gemeinsam aktiviert. Alle vier aktiven Quellen zurückgelesen. Die anschließende Syntaxprüfung einschließlich Ticketprojektion und Projection Behavior war erfolgreich. |
| Lesender Migrationsreport | Syntaxprüfung und Aktivierung bestanden. ABAP Unit insgesamt bestanden. Die Tests prüfen eine leere Zuordnungsliste, eine unbekannte Ticketnummer sowie eindeutige, mehrdeutige, fehlende und ungültige Zuordnungen. Die Klassifikationsprüfung verwendet SQL-Testdoubles. |
| Beitrags-DCL und Service | Aktive Quellen geprüft. Kommentare und interne Notizen verwenden in den aktiven Lese- und Draft-Sichten `where FALSE`. Die aktive Service-Definition `ZUI_TICKET_ITEM_03_O4` exponiert nur Tickets, Anhänge und Verlauf. Dies ist ein Quellenbefund. |
| Zugriff auf Tickets | Die aktive Root-DCL verwendet weiterhin `where TRUE`. Die fachlichen Regeln der Rollenmatrix sind noch nicht wirksam. |
| IAM und Testidentitäten | Die generierte IAM-App wurde im SAP-Repository gefunden. Das Recht zur Benutzer- und Rollenpflege im Trial sowie getrennte, eingeschränkt berechtigte Anmeldungen konnten nicht bestätigt werden. |
| Positive und negative Laufzeittests | Offen. Zu prüfen sind insbesondere Requester-Eigentum, Agentenzuweisung, Teamgrenzen des Managers, getrennte Verwaltungs- und Löschrechte des Admins, direkte Kindzugriffe, Streams, Draft-Eigentum, Rechteentzug vor Aktivierung und Zugriff auf interne Notizen. |

Die Beitragsendpunkte bleiben bis zur erfolgreichen Sicherheitsabnahme unveröffentlicht.

Der DCL-Filter für verifizierte Tickets wurde als Arbeitsversion syntaktisch geprüft. Eine Aktivierung und Laufzeitprüfungen der Bestandssperre sind offen. In Eclipse wurden die Assistenten für SUSO und SIA1 geöffnet und das NovaDesk-Paket wurde in der Paketsuche gefunden. Die nachfolgende Eclipse-Anlage von `ZNVD_TKT` und `ZNVD_TICKET_BC` wurde per ADT-MCP-Repository-Suche bestätigt. Fachliche Aktivitäts- und Teamberechtigungen, Rollenzuweisungen und getrennte Sicherheitsidentitäten sind noch nicht bestätigt.

### Draft-Sichten für die Bestandssperre

| Prüfung | Ergebnis |
| --- | --- |
| Aktivierung | `ZR_NVD_TICKET_DQ` und `ZR_NVD_ATTACHMENT_DQ` samt DCL aktiviert. Aktive Quellen zurückgelesen. |
| ABAP Unit mit aktueller Identität | Der direkte CDS-Lesetest ergab null Zeilen in beiden Draft-Sichten. Der gesamte Lauf war erfolgreich. |
| Fiori, EML, Navigation und Attachment-Streams | Die Draft-Sichten sind noch nicht im aktiven RAP-Behavior angebunden. Die End-to-End-Sperre, Schreibprüfungen, Draft-Aktivierung und getrennte Rollenidentitäten bleiben ungetestet. |

### IAM-Teamrestriktion

- Eclipse bestätigte den aktiven Status des Team-Berechtigungsfelds `ZNVD_TEAM`, die sichtbare Einbindung in `ZNVD_TKT` und den aktiven Business Catalog `ZNVD_TICKET_BC`. Das Datenelement `ZNVD_TEAM_ID` wurde per ADT MCP geprüft, aktiviert und aktiv zurückgelesen.
- Die Syntaxprüfung der DCL-Arbeitsversion mit Teamfeld, Aktivität `03` und Verifizierungsstatus war erfolgreich. Die Arbeitsversion wurde nach der Prüfung zurückgesetzt. Die aktive Ticket-DCL bleibt auf `where TRUE`.
- Laufzeittests mit getrennten Benutzerrollen für eigene, fremde und unverifizierte Tickets sowie Drafts, Navigation, Anhänge und interne Notizen stehen aus.

### Kombinierte Ticket-Leseregel

- Die erste Syntaxprüfung der kombinierten DCL wies das fehlende Teamfeld in `ZNVD_AGT` nach. Nach der Feldkorrektur akzeptierte SAP die kombinierte Regel für verifizierte Tickets und die getrennten Lesepfade für Requester, Agent und Manager.
- Die aktive Ticket-DCL blieb nach dem Arbeitsversuch auf `where TRUE`. Die DCL-Prüfung war ein Syntaxcheck. Die OData-, Navigations-, Attachment-, Draft-Aktivierungs- und Rollen-Laufzeittests stehen aus.
- Die SAP-Launchpad-Prüfung bestätigte den App Finder. Eingeschränkte Rollen und unabhängige Anmeldungen wurden nicht bestätigt.

### Laufzeittest der eigenständigen CDS-Lesesicht

`ZCL_NVD_READ_SCOPE_TEST` lief mit vier erfolgreichen ABAP-Unit-Testmethoden. Mit synthetischen SAP-Berechtigungswerten erhielt der Requester die verifizierten eigenen Tickets, der Agent nur das verifizierte zugewiesene Ticket mit aktiver Mitgliedschaft, der Manager die verifizierten Tickets im freigegebenen aktiven Team und der Benutzer ohne Leserecht keine Treffer. Die Testdaten blieben in den CDS-Testdoubles. Kein OData-, Stream-, Draft-Aktivierungs- oder RAP-Schreibtest wurde daraus abgeleitet.

### Rollenabhängige Schreibregeln

Sechs ABAP-Unit-Tests für `ZCL_NVD_TICKET_WRITE_POLICY` bestanden. Sie prüfen Requester-Felder und Anhangseigentum, Agent-Workflow und entzogene Teammitgliedschaft, Manager-Workflow und Zuweisung, getrennte Admin-Löschrechte, die Ablehnung unverifizierter Tickets sowie Schreibsperren bei Status G. Die Berechtigungsdaten sind simuliert. Die RAP-Global- und Instanzanbindung bestand die Syntaxprüfung einer Arbeitsversion. Positive und negative RAP-, Draft-Aktivierungs- und OData-Laufzeittests bleiben offen.

### RAP-Integrationsentwurf und aktive CDS-Beziehungen

- SAP hat die drei privaten CDS-Beziehungen gemeinsam geprüft und aktiviert. Die aktiven Quellen wurden zurückgelesen. Ticketprojektion und Service-Definition exponieren die Lesesicht nicht.
- Nach Aktivierung der CDS-Beziehungen bestanden die bestehenden ABAP-Unit-Suiten des RAP-Behavior-Pools und der geschützten CDS-Lesesicht.
- Der erweiterte RAP-/DCL-Arbeitsentwurf hat den SAP-Syntaxcheck bestanden. Er wurde nicht aktiviert. Die aktiven Quellen wurden nach dem Zurücksetzen der Arbeitsversion verifiziert.
- Die aktive IAM-App `ZNVD_TICKET_EXT` wurde in Eclipse bestätigt. IAM-Katalogzuordnung, produktive Instanzautorisierung, Draft-Aktivierung und Rollen-Ende-zu-Ende-Tests stehen aus.

### Zuweisungsaktion und Child-Save-Checks

- Der abstrakte Zuweisungsparameter wurde aktiviert und aktiv zurückgelesen. Die vollständige SAP-Syntaxprüfung des erweiterten Entwurfs bestand nach Aufteilung der Anhangsvalidierung und Entfernung der im Cloud-Release unzulässigen Prüfung `FOR USER`.
- Die separate IAM-Feldprüfung meldete `ZNVD_TEAM` als fehlend in `ZNVD_FLOW`, `ZNVD_ATT` und `ZNVD_ADM`. Alle getesteten SAP-Arbeitsversionen wurden auf den aktiven Stand zurückgesetzt.
- Der Entwurf wurde nicht aktiviert. Neue Laufzeittests für Zuweisung, Child-Änderungen, Draft-Aktivierung, Service-Cutover und Rückfall stehen aus.

### Freigabeblocker der IAM-Umstellung

Die Zielbenutzerprüfung ist als Architekturentscheidung offen. Für den aktiven Service stehen die sieben unabhängigen Rollenidentitäten und positive sowie negative Laufzeittests zu Zuweisung, Workflow, Anhängen, Draft-Aktivierung, Löschkaskaden und direkten Zugriffen weiterhin aus. In diesem Schritt wurden keine Testbenutzer, Rollen oder Bestandszuordnungen angelegt.

### Zweistufige Zuweisung

Drei neue ABAP-Unit-Fälle für die aktive Vorschlags-DCL bestanden. Der Zielagent sah nur seinen offenen Vorschlag bei aktiver Teammitgliedschaft. Der Manager sah die Vorschläge seines berechtigten Teams. Ohne Berechtigung blieb die Sicht leer. Andere Ziele, nicht verifizierte Tickets, inaktive Mitgliedschaften und abgeschlossene Vorschläge für den Agenten wurden als Negativfälle geprüft. Die Vorschlagsaktionen, das Schreiben des Audits und der gemeinsame Speichervorgang mit der effektiven Zuweisung sind noch nicht implementiert und wurden nicht zur Laufzeit geprüft.

### Fünf Zuweisungsaktionen im RAP-Integrationsentwurf

- `ZA_NVD_ASSIGN_COMMAND` wurde aktiviert und aktiv zurückgelesen. Der gemeinsame SAP-Syntaxcheck des RAP-Entwurfs mit fünf Aktionen, Global Authorization, Ticket-Lock und Additional Saver bestand. Das SAP-Release verlangt für `SET LOCKS` den aktiven Ticket-Schlüssel ohne `%is_draft`. Nach dem Check wurden alle produktiven Quellen mit dem bisherigen aktiven Stand abgeglichen.
- Die bestehenden ABAP-Unit-Suiten für Ticket-Behavior, Write Policy und geschützte Lesesichten bestanden.
- Die neuen Aktionen wurden nicht aktiviert. Positive und negative EML-Integrationsfälle für den vollständigen Ablauf, parallele Annahmen und ein gemeinsamer Rollback der Zuweisung und Audits sind weiterhin offen. Keine Service-Freigabe und keine Provisionierung von Testidentitäten.

### IAM-Konfiguration und Laufzeitvoraussetzungen

- ADT MCP bestätigte `ZNVD_TEAM` in den aktiven Objekten `ZNVD_FLOW`, `ZNVD_ATT` und `ZNVD_ADM`.
- Die externe IAM-App war per AFF lesbar und enthielt noch keine Services. Der ADT-Logon brach vor der Serviceänderung ab. Katalogzuordnung und sieben getrennte Anmeldungen bleiben unverifiziert.
- Keine RAP-Umstellung und keine neuen Laufzeittests für die fünf Zuweisungsaktionen. Konkurrenz, Rechteentzug und SAP-LUW-Rollback stehen aus.
