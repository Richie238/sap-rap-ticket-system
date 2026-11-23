# NovaDesk – Fiori- und Laufzeittests

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
