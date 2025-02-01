import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure owner can register auditors",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const auditor = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-audit",
        "register-auditor",
        [types.principal(auditor.address)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Ensure non-owners cannot register auditors",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const nonOwner = accounts.get("wallet_1")!;
    const auditor = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-audit",
        "register-auditor",
        [types.principal(auditor.address)],
        nonOwner.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(err u100)');
  },
});

Clarinet.test({
  name: "Ensure certified auditors can submit reports",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const auditor = accounts.get("wallet_1")!;
    const contract = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-audit",
        "register-auditor",
        [types.principal(auditor.address)],
        deployer.address
      ),
      Tx.contractCall(
        "chain-audit",
        "register-contract",
        [types.principal(contract.address)],
        contract.address
      ),
      Tx.contractCall(
        "chain-audit",
        "submit-audit",
        [
          types.principal(contract.address),
          types.utf8("No critical findings"),
          types.uint(3)
        ],
        auditor.address
      )
    ]);
    
    assertEquals(block.receipts[2].result, '(ok true)');
  },
});
