# SAP RAP Ticket System

Ein eigenständig entwickeltes Ticket-Management-System auf Basis des SAP RESTful Application Programming Model (RAP), gebaut auf der SAP Business Technology Platform (BTP) ABAP Environment.

## Über dieses Projekt

Dieses Projekt entstand im Rahmen meiner vertieften Auseinandersetzung mit modernen SAP-Entwicklungskonzepten. Ausgehend vom offiziellen SAP RAP100-Tutorial habe ich das erlernte Prinzip auf ein komplett eigenes, praxisnahes Fachobjekt übertragen – ein Ticket-Management-System, wie es in IT-Support- oder Change-Request-Prozessen eingesetzt wird.

## Umgesetzte RAP-Kernkonzepte

- **Persistenz & Draft-Handling** – vollständige Draft-Fähigkeit mit Activate, Discard, Edit, Resume
- **Early Numbering** – automatische, eindeutige ID-Vergabe beim Anlegen neuer Tickets
- **Determination** – automatisches Setzen des Status auf "Offen" beim Anlegen
- **Validations** – Prüfung auf Pflichtfelder (Bearbeiter) und fachliche Plausibilität (Fälligkeitsdatum nicht in der Vergangenheit)
- **Value Help Entities** – drei vollständig selbst gebaute Wertehilfen mit F4-Suche und Textanzeige (Status, Priorität, Kategorie)
- **Sprechender Objekttitel** – dynamischer Titel basierend auf dem Betreff-Feld statt der technischen ID
- **Volltextsuche** – über mehrere Schlüsselfelder hinweg durchsuchbar

## Architektur

Das Projekt folgt der klassischen RAP-Schichtenarchitektur:
