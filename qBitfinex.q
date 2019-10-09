\p 5010
\l ws3.q
\l tools.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

pairInfo: .j.k .Q.hg ":https://api.bitfinex.com/v1/symbols";
BTCpairs: pairInfo where pairInfo like "btc???";
pairs: 0N! upper BTCpairs;
save `pairs;

chids:()!();

upd:{
  /* entrypoint for received messages */
  j:  .j.k x;
  $[99h ~ type j;
    [if[`chanId in key j; chids[j[`chanId]]:j[`pair]; chids;];];
    [   cc: count j;
        symbol:  `$chids[j[0]];
        $[cc < 3; 
            [ ccc:count j[1];data: flip j[1]; `trades insert (ex:ccc#`bitfinex; sym:ccc#symbol; ccc#time:.z.p;price:`float$data[3];size:`float$data[2]);];
            [
                if["te" like j[1];
                    data:j[2];
                    quant:`float$data[2];
                    `trades insert (ex:`bitfinex; sym:symbol; time:.z.p;price:`float$data[3];size:quant);
                ]
            ]
        ]   
    ]
  ];  
 };

h:.ws.open["wss://api-pub.bitfinex.com/ws/2";`upd];
{wait[2]; h .j.j `event`channel`symbol!(`subscribe;`trades;"t",x )} each pairs;


