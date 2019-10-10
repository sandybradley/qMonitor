\p 5010
\l ws2.q
\l tools.q
\l reQ/req.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();size:`float$());

// Binance
\d .binance

  pairInfo: .j.k .Q.hg ":https://api.binance.com/api/v1/exchangeInfo";
  BTCpairs: select from pairInfo[`symbols] where  (baseAsset like "BTC") and status like "TRADING";
  pairs: 0N! lower BTCpairs[`symbol];
  save `.binance.pairs;

  upd:{
    /* entrypoint for received messages */
    j: .j.k x; 
    if[`data in key j;
      content: j[`data];
      quant:"F"$content[`q];
      if[ 1b ~ content[`m]; quant:0.0-quant;];
      `trades insert (ex:`binance; sym:`$content[`s]; time:.z.p;price:"F"$content[`p];size:quant);
    ];  
  };

  h:.ws.open["wss://stream.binance.com:9443/stream?streams=",raze {x,"@aggTrade/"} each pairs;`.binance.upd];

\d .
// end Binance

wait[2]; 

// Bitfinex
\d .bitfinex
  pairInfo: .j.k .Q.hg ":https://api.bitfinex.com/v1/symbols";
  BTCpairs: pairInfo where pairInfo like "btc???";
  pairs: 0N! upper BTCpairs;
  save `.bitfinex.pairs;

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

  h:.ws.open["wss://api-pub.bitfinex.com/ws/2";`.bitfinex.upd];
  {wait[2]; h .j.j `event`channel`symbol!(`subscribe;`trades;"t",x )} each pairs;
\d .
// end Bitfinex

wait[2]; 

// Bitstamp
\d .bitstamp 
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

  h:.ws.open["wss://ws.bitstamp.net";`.bitstamp.upd];
  h .j.j `event`data!(`bts:subscribe;(enlist `channel)!enlist `live_trades_btcusd );
  h .j.j `event`data!(`bts:subscribe;(enlist `channel)!enlist `live_trades_btceur );
\d .
// end Bitstamp

wait[2]; 

// Kraken
\d .kraken 
  pairInfo: value {.reqnew.g  "https://api.kraken.com/0/public/AssetPairs"}[`result];
  pairdata: value pairInfo[1];
  Allpairs:();
  Allpairs: {pairdata[x][`wsname]} each til count pairdata;
  BTCpairs: Allpairs where Allpairs like "XBT/*";
  pairs: 0N!  BTCpairs;
  save `.kraken.pairs;

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

  h:.ws.open["wss://ws.kraken.com";`.kraken.upd];
  wait[2]; 
  h .j.j `event`subscription`pair!(`subscribe;(enlist `name)!enlist `trade;pairs );
\d .
// end Kraken

wait[2]; 

// Coinbase pro
\d .coinbasepro 
  pairInfo: .reqnew.g "https://api.pro.coinbase.com/products";
  BTCpairs: select from pairInfo where  (base_currency like "BTC") and status like "online";
  pairs: 0N!  BTCpairs[`id];
  save `.coinbasepro.pairs;

  upd:{
    /* entrypoint for received messages */
    j: .j.k x; 
    if[`price in key j;
      quant:"F"$j[`last_size];
      if[ "sell" like j[`side]; quant:0.0-quant;];
      `trades insert (ex:`coinbasepro; sym:`$j[`product_id]; time:.z.p;price:"F"$j[`price];size:quant);
    ];  
  };

  h:.ws.open["wss://ws-feed.pro.coinbase.com";`.coinbasepro.upd];
  h .j.j `type`channels!(`subscribe;enlist ( `name`product_ids!(`ticker;(pairs)) ) );

\d .
// end Coinbase pro

.z.ts:{[] save `trades}

\t 600000
