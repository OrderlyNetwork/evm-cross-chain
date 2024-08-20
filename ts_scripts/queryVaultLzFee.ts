import { QueryParameter, DuneClient } from "@duneanalytics/client-sdk";
const { DUNE_API_KEY } = process.env;

const tx_hash1 = "0xb1a67081bd847584dc7454da3713bbe3ecaccd34185401a12877e2083e47a893";
const tx_hash2 = "0xb1a67081bd847584dc7454da3713bbe3ecaccd34185401a12877e2083e47a893";

const tx_hash = '(0x4b419c3275033a048efffa8c4fb420520bceb21d7d7a492a74b091fcc4e68c6d,0x20fc0a1b6ab7ac4c6be7d904314af1a2bf9931e9d2490d777de2ecfe312d5bd5,0x6f25815c8c53bae53d9923b0b3b38f0abbc3b8d570d8f022e59636765ca3385c)'

// const tx_hash = `(${tx_hash1}, ${tx_hash2})`;
console.log(tx_hash);

const client = new DuneClient(DUNE_API_KEY ?? "");
const queryId = 3773207;
const query_parameters = [
    QueryParameter.text("tx_hash_list", tx_hash),
  ]

  client.runQuery({ queryId, query_parameters}).then((executionResult) => console.log(executionResult.result?.rows));
