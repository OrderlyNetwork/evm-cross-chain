import { QueryParameter, DuneClient } from "@duneanalytics/client-sdk";
const { DUNE_API_KEY } = process.env;

const tx_hash = "0xb1a67081bd847584dc7454da3713bbe3ecaccd34185401a12877e2083e47a893";

const client = new DuneClient(DUNE_API_KEY ?? "");
const queryId = 3773207;
const query_parameters = [
    QueryParameter.text("tx_hash", tx_hash),
  ]

  client.runQuery({ queryId, query_parameters}).then((executionResult) => console.log(executionResult.result?.rows));
