\p 5010
\l ws3.q
\l tools.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

pairs: ("btcusd";"btceur");

upd:{
  /* entrypoint for received messages */
  j: 0N! .j.k x; 
  if[`data in key j;
    data:j[`data];
    quant:`float$data[`amount];
    if[ 1 = data[`type]; quant:0.0-quant;];
    `trades insert (ex:`bitstamp; sym:`btcusd; time:.z.p;price:`float$data[`price];size:quant);
  ];  
 };

h:.ws.open["wss://ws.bitstamp.net";`upd];
h .j.j `event`data!(`bts:subscribe;(enlist `channel)!enlist `live_trades_btcusd );


