\p 5010
\l ws3.q
\l tools.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

pairInfo: .j.k .Q.hg ":https://api.binance.com/api/v1/exchangeInfo";
//BTCpairs: select from pairInfo[`symbols] where ((quoteAsset like "BTC") or baseAsset like "BTC") and status like "TRADING";
BTCpairs: select from pairInfo[`symbols] where  (baseAsset like "BTC") and status like "TRADING";
//BTCpairs: select from BTCpairs where (quoteTradingSymbol in assetList) or baseTradingSymbol in assetList;
pairs: 0N! lower BTCpairs[`symbol];
save `pairs;

upd:{
  /* entrypoint for received messages */
  j: 0N! .j.k x; 
  if[`data in key j;
    content: j[`data];
    //contentcount:count content;
    quant:"F"$content[`q];
    if[ 1b ~ content[`m]; quant:0.0-quant;];
    `trades insert (ex:`binance; sym:`$content[`s]; time:.z.p;price:"F"$content[`p];size:quant);
  ];  
 };

h:.ws.open["wss://stream.binance.com:9443/stream?streams=",raze {x,"@aggTrade/"} each pairs;`upd];
//h:.ws.open["wss://stream.binance.com:9443/stream?streams=btcusdt@aggTrade";`upd];

