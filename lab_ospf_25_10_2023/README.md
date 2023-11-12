# Comandi Eseguiti

Avvio del laboratorio
`kathara lstart`

Visualizzazione tabella di instradamento
`ip route`

Ping di una macchina (da bb1 all'interfaccia eth0 di bb4)
`ping 10.0.2.1`

Esecuzione vtysh
`vtysh`

- Visualizzazione della tabella di instradamento in vtysh
`show ip route`

- Visualizzazione di come ospf vede le rotte (qui possiamo vedere anche i costi calcolati)
`show ip ospf route`

- Visualizzazione informazioni sull'interface
`show ip ospf interface`

- Visualizzazione riepilogo database
`show ip ospf database`

    - Visualizzazione router link states
    `show ip ospf database router`

    - Visualizzazione Network link states
    `show ip ospf database network`

## Operazioni di configurazione sui dispositivi

Spegnimento di una interfaccia (ex: per bb3)
`ip link set eth1 down`