\p 5010
\l ws3.q
\l tools.q
\l reQ/req.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

// Binance
  .binance.pairInfo: .j.k .Q.hg ":https://api.binance.com/api/v1/exchangeInfo";
  .binance.BTCpairs: select from .binance.pairInfo[`symbols] where  (baseAsset like "BTC") and status like "TRADING";
  .binance.pairs:  lower .binance.BTCpairs[`symbol];
  save `.binance.pairs;

  .binance.upd:{
    /* entrypoint for received messages */
    j: .j.k x; 
    if[`data in key j;
      content: j[`data];
      quant:"F"$content[`q];
      if[ 1b ~ content[`m]; quant:0.0-quant;];
      `trades insert (ex:`binance; sym:`$content[`s]; time:.z.p;price:"F"$content[`p];size:quant);
    ];  
  };

  .binance.h:.ws.open["wss://stream.binance.com:9443/stream?streams=",raze {x,"@aggTrade/"} each .binance.pairs;`.binance.upd];

// end Binance

wait[2]; 

// Bitfinex
  .bitfinex.pairInfo: .j.k .Q.hg ":https://api.bitfinex.com/v1/symbols";
  .bitfinex.BTCpairs: .bitfinex.pairInfo where .bitfinex.pairInfo like "btc???";
  .bitfinex.pairs:  upper .bitfinex.BTCpairs;
  save `.bitfinex.pairs;

  .bitfinex.chids:()!();

  .bitfinex.upd:{
    /* entrypoint for received messages */
    j:  .j.k x;
    $[99h ~ type j;
      [if[`chanId in key j; .bitfinex.chids[j[`chanId]]:j[`pair]; ];];
      [   cc: count j;
          symbol:  `$.bitfinex.chids[j[0]];
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

  .bitfinex.h:.ws.open["wss://api-pub.bitfinex.com/ws/2";`.bitfinex.upd];
  {wait[2]; .bitfinex.h .j.j `event`channel`symbol!(`subscribe;`trades;"t",x )} each .bitfinex.pairs;
// end Bitfinex

wait[2]; 

// Bitstamp 
  .bitstamp.upd:{
    /* entrypoint for received messages */
    j:  .j.k x; 
    if[`data in key j;
      data:j[`data];
      quant:`float$data[`amount];
      if[ 1 = data[`type]; quant:0.0-quant;];
      `trades insert (ex:`bitstamp; sym:`btcusd; time:.z.p;price:`float$data[`price];size:quant);
    ];  
  };

  .bitstamp.h:.ws.open["wss://ws.bitstamp.net";`.bitstamp.upd];
  .bitstamp.h .j.j `event`data!(`bts:subscribe;(enlist `channel)!enlist `live_trades_btcusd );
  .bitstamp.h .j.j `event`data!(`bts:subscribe;(enlist `channel)!enlist `live_trades_btceur );
// end Bitstamp

wait[2]; 

// Kraken 
  .kraken.pairInfo: value {.reqnew.g  "https://api.kraken.com/0/public/AssetPairs"}[`result];
  .kraken.pairdata: value .kraken.pairInfo[1];
  .kraken.Allpairs: {.kraken.pairdata[x][`wsname]} each til count .kraken.pairdata;
  .kraken.BTCpairs: .kraken.Allpairs where .kraken.Allpairs like "XBT/*";
  .kraken.pairs:   .kraken.BTCpairs;
  save `.kraken.pairs;

  .kraken.chids:()!();

  .kraken.upd:{
    /* entrypoint for received messages */
    j:  .j.k x;
    $[99h ~ type j;
      [if[`channelID in key j; .kraken.chids[j[`channelID]]:j[`pair]; ];];
      [ if["trade" like j[2];
          symbol:  `$j[3];
          ccc: count j[1];
          $[ccc > 1;
            [data: flip j[1];
            prices:  "F"$data[0]; 
            quants:  "F"$data[1];
            sells:first each data[3];
            quants: 0.0-quants where sells ~ "s";
            `trades insert (ex:ccc#`kraken; sym:ccc#symbol; ccc#time:.z.p;price:prices;size:quants);];
            [data: first j[1];
            prices: "F"$data[0]; 
            quants: "F"$data[1];
            sells:first data[3];
            if[sells ~ "s"; quants:0.0-quants;];
          
            `trades insert (ex:`kraken; sym:symbol; time:.z.p;price:prices;size:quants);]
          ];
          ]   
      ]
    ];  
  };

  .kraken.h:.ws.open["wss://ws.kraken.com";`.kraken.upd];
  wait[2]; 
  .kraken.h .j.j `event`subscription`pair!(`subscribe;(enlist `name)!enlist `trade;.kraken.pairs );
// end Kraken

wait[2]; 

// Coinbase pro 
  .coinbasepro.pairInfo: .reqnew.g "https://api.pro.coinbase.com/products";
  .coinbasepro.BTCpairs: select from .coinbasepro.pairInfo where  (base_currency like "BTC") and status like "online";
  .coinbasepro.pairs:   .coinbasepro.BTCpairs[`id];
  save `.coinbasepro.pairs;

  .coinbasepro.upd:{
    /* entrypoint for received messages */
    j: .j.k x; 
    if[`price in key j;
      quant:"F"$j[`last_size];
      if[ "sell" like j[`side]; quant:0.0-quant;];
      `trades insert (ex:`coinbasepro; sym:`$j[`product_id]; time:.z.p;price:"F"$j[`price];size:quant);
    ];  
  };

  .coinbasepro.h:.ws.open["wss://ws-feed.pro.coinbase.com";`.coinbasepro.upd];
  .coinbasepro.h .j.j `type`channels!(`subscribe;enlist ( `name`product_ids!(`ticker;(.coinbasepro.pairs)) ) );
// end Coinbase pro

.z.ts:{[] save `trades}

\t 600000
