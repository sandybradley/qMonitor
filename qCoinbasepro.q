\p 5010
\l ws3.q
\l tools.q
\l reQ/req.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

pairInfo: .reqnew.g "https://api.pro.coinbase.com/products";
//BTCpairs: select from pairInfo[`symbols] where ((quoteAsset like "BTC") or baseAsset like "BTC") and status like "TRADING";
BTCpairs: select from pairInfo where  (base_currency like "BTC") and status like "online";
//BTCpairs: select from BTCpairs where (quoteTradingSymbol in assetList) or baseTradingSymbol in assetList;
pairs: 0N!  BTCpairs[`id];
save `pairs;

upd:{
  /* entrypoint for received messages */
  j: .j.k x; 
  if[`price in key j;
    quant:"F"$j[`last_size];
    if[ "sell" like j[`side]; quant:0.0-quant;];
    `trades insert (ex:`coinbasepro; sym:`$j[`product_id]; time:.z.p;price:"F"$j[`price];size:quant);
  ];  
 };

h:.ws.open["wss://ws-feed.pro.coinbase.com";`upd];
h .j.j `type`channels!(`subscribe;enlist ( `name`product_ids!(`ticker;(pairs)) ) );



.z.ts:{[] save `trades};

 \t 600000
