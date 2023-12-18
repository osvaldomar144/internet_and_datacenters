# Comandi per BPG

Check frr configuration file
`less /etc/frr/frr.conf`

Check frr log file
`less /var/log/frr/frr.log`

Check the routing table of ASx
`vtysh`
`show ip route`

Check BGP status
`vtysh`
`show ip bgp neighbors`

`show ip bgp`

Route map example
```
router bgp 100
!
neighbor 222.2.2.2 remote-as 200
!
neighbor 222.2.2.2 route-map myRouteMap in
!
route-map myRouteMap permit 10
    match ip address myAccessList
    set metric 5
    set local-preferencev 25
!
route-map myRouteMap permit 20
    set metric 2
!
access-list myAccessList permit 193.204.0.0/16
```

Route map example - without set conditions
```
route-map myRouteMap permit 10
match as-path _10_

! consente solo annunci contenenti 10 nel as-path
```

##### Route map SET CONDITIONS
as-path:
```
set as-path prepend 10 10 10
```
local preference:
```
set local-preference 200
```
metric:
```
set metric 200
```
community:
```
set community 200:11111
```

# Note

> _Metriche_

[annunci in USCITA - traffico in INGRESSO]

La metrica è settata tipicamente sugli annunci in uscita dall'AS e serve a gestire i flussi inbound.

Questi valori di metrica sono comparabili soltanto fra annunci che vengono dallo stesso AS.

Quindi solo quando mi rivolgo per più strade allo stessp AS.

_Esempio: (contenuto nel file frr.conf)_

Configurazione del router di backup (AS20r1) per ottenere questo:
```
        annuncio ->(metric=0)  
        <- traffico                ___________
                                  |           |
                   ___(primary)___|_ AS20r2   |    
        AS100r1 __/               |           |  AS20
                  \___(backup)____|_ AS20r1   |
                                  |___________|
        annuncio ->(metric=10)
        X <- traffico
```

```
neighbor x.x.x.x route-map <name:metricOut> out

access-list <nameList:myAggregate> permit x.x.x.x/x

route-map <name:metricOut> permit 10
match ip address <nameList:myAggregate>
set metric 10
```

La metrica è fatta in modo tale che quando viene ricevuto questo valore "metric", chi riceve questi annunci scelga il valore più basso.

> _Local Preference_

[annunci in INGRESSO - traffico in USCITA]

Si diminuisce la local preference sugli annunci che mi arrivano sul ramo di backup (AS100r1), si costringe a scegliere l'annuncio con local-preference più alto.

Default value local-pref: 100.

_Esempio: (contenuto nel file frr.conf)_

Configurazione del router di backup (AS20r1) per ottenere questo:
```
        <- annuncio (loc-pref=100)  
        traffico ->                ___________
                                  |           |
                   ___(primary)___|_ AS20r2   |    
        AS100r1 __/               |           |  AS20
                  \___(backup)____|_ AS20r1   |
                                  |___________|
        <- annuncio (loc-pref=90) 
        traffico -> X
```

```
neighbor x.x.x.x route-map <name:localPrefIn> in

route-map <name:localPrefIn> permit 10
set local-preference 90
```

# Comandi per DNS

Ricevere info sulla "risoluzione" del dns
```
dig +trace <dns:pc2.startup.net>
```


