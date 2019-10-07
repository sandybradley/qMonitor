\p 5010
\l ws2.q
\l tools.q

trades:([]ex:`$(); sym:`$(); time:`timestamp$(); price:`float$();side:`$();size:`float$());

currentExchange:`Bittrex;
currentPair:"btc-usd";
assetList:("USDT";"USDC";"USD");

//shrimpy
exchangeInfo: .j.k .Q.hg `$":https://dev-api.shrimpy.io/v1/list_exchanges";
save `exchangeInfo;
exchanges:0N! `hitbtc`okex`huobiglobal`huobi`kucoin`bitmart _ `$exchangeInfo`exchange;
save `exchanges;
pairs: exchanges!();
pair:{
  wait[5];
  pairInfo: .j.k .Q.hg ":https://dev-api.shrimpy.io/v1/exchanges/",(string x),"/trading_pairs";
  BTCpairs: select from pairInfo where (quoteTradingSymbol like "BTC") or baseTradingSymbol like "BTC";
  if[x ~ `kraken; BTCpairs: select from pairInfo where (quoteTradingSymbol like "XBT") or baseTradingSymbol like "XBT";];
  BTCpairs: select from BTCpairs where (quoteTradingSymbol in assetList) or baseTradingSymbol in assetList;
  pairs[x]:: 0N! lower BTCpairs[`baseTradingSymbol],' "-",'BTCpairs[`quoteTradingSymbol];
 }
pair each exchanges;
save `pairs;
upd:{0N!x};
h:.ws.open["wss://ws-feed.shrimpy.io/";`upd];
upd:{
  /* entrypoint for received messages */
  j: .j.k x;
  if[`type in key j;
    if[j[`type] ~ "ping";                                                     //check for handler of this message type
      h .j.j `type`data!("pong";`long$j[`data]);
    ];
  ];
  if[`channel in key j;
    if[j[`channel] ~ "trade";                                                     //check for handler of this message type
      content: j[`content];
      contentcount:count content;
      `trades insert (ex:contentcount#`$j[`exchange]; sym:contentcount#`$j[`pair]; time:"P"${23#x} eachcontent[`time];price:"F"$content[`price];side:`$content[`takerSide];size:"F"$content[`quantity]);
    ];
  ];
 };

subpairs:{ wait[2]; h .j.j `type`exchange`pair`channel!(`subscribe;currentExchange;`$x;`trade);}

sub:{   currentExchange:: x;  subpairs each pairs[x];}

sub each exchanges;

.z.ts:{[] save `trades};

\t 600000
