\p 5010
\l ws3.q
\l tools.q
\l reQ/req.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

pairInfo: value {.reqnew.g  "https://api.kraken.com/0/public/AssetPairs"}[`result];
pairdata: value pairInfo[1];
Allpairs:();
Allpairs: {pairdata[x][`wsname]} each til count pairdata;
BTCpairs: Allpairs where Allpairs like "XBT/*";
pairs: 0N!  BTCpairs;
save `pairs;

chids:()!();

upd:{
  /* entrypoint for received messages */
  j: 0N! .j.k x;
  $[99h ~ type j;
    [if[`channelID in key j; chids[j[`channelID]]:j[`pair]; ];];
    [ if["trade" like j[2];
        symbol: 0N! `$j[3];
        ccc:0N! count j[1];
        $[ccc > 1;
          [data: flip j[1];
          prices: 0N! "F"$data[0]; 
          quants: 0N! "F"$data[1];
          sells:first each data[3];
          quants:0N! 0.0-quants where sells ~ "s";
          `trades insert (ex:ccc#`kraken; sym:ccc#symbol; ccc#time:.z.p;price:prices;size:quants);];
          [data:0N! first j[1];
          prices:0N! "F"$data[0]; 
          quants:0N! "F"$data[1];
          sells:first data[3];
          if[sells ~ "s"; quants:0.0-quants;];
         
          `trades insert (ex:`kraken; sym:symbol; time:.z.p;price:prices;size:quants);]
        ];
        ]   
    ]
  ];  
 };

h:.ws.open["wss://ws.kraken.com";`upd];
wait[2]; 
h .j.j `event`subscription`pair!(`subscribe;(enlist `name)!enlist `trade;pairs );


