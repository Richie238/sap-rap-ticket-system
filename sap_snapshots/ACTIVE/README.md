# Aktiver SAP-Quellstand

Aus `NOVADESK_DEV`, Paket `ZZ1_NOVADESK`, am 24. November 2026 über ADT MCP mit Version `ACTIVE` gelesen. `SHA256SUMS` erfasst die exportierten Quelldateien.

Der Export enthält CDS-Views, DCLs, Metadata Extensions, RAP-Behaviors, ABAP-Klassen, Tabellen, Nummernkreisobjekt, Service-Definition und Binding. Er enthält keine Tabelleninhalte, Intervallstände, Live-Service-URLs oder generierten mandantenabhängigen Publikations- und Berechtigungsdaten. Leere Klassentextdateien sind ausgelassen.

Die Suche im SAP-Repository lieferte für `ZR_TICKET_ITEM_03` keine CDS- oder Behavior-Definition. Diese Quellen liegen in den historischen Ständen. Die physische Tabelle `ZTCKET_ITEM_03_D` existiert weiterhin und ist als stillgelegte Draft-Tabelle mit exportiert. Der gemeinsame Behavior-Pool `ZBP_R_TICKET_ITEM_03` gehört zum aktiven Root `ZR_TICKET_ITEM_03000`.
