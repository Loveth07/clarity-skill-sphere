import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that only contract owner can add authorized issuers",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'add-authorized-issuer',
        [types.principal(issuer.address)],
        deployer.address
      ),
    ]);
    block.receipts[0].result.expectOk();
    
    // Non-owner attempt should fail
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'add-authorized-issuer',
        [types.principal(issuer.address)],
        issuer.address
      ),
    ]);
    block.receipts[0].result.expectErr(types.uint(100)); // err-owner-only
  },
});

Clarinet.test({
  name: "Test certification issuance and validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    const recipient = accounts.get('wallet_2')!;
    
    // Add authorized issuer
    let block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'add-authorized-issuer',
        [types.principal(issuer.address)],
        deployer.address
      ),
    ]);
    
    // Issue certification
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'issue-certification',
        [
          types.principal(recipient.address),
          types.ascii("Blockchain Developer"),
          types.ascii("Complete blockchain development certification"),
          types.uint(100)
        ],
        issuer.address
      ),
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify certification
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'is-certification-valid',
        [types.uint(0)],
        recipient.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Test endorsement functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    const recipient = accounts.get('wallet_2')!;
    const endorser = accounts.get('wallet_3')!;
    
    // Setup and issue certification
    let block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'add-authorized-issuer',
        [types.principal(issuer.address)],
        deployer.address
      ),
      Tx.contractCall(
        'skill_sphere',
        'issue-certification',
        [
          types.principal(recipient.address),
          types.ascii("Blockchain Developer"),
          types.ascii("Complete blockchain development certification"),
          types.uint(100)
        ],
        issuer.address
      ),
    ]);
    
    // Add endorsement
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'add-endorsement',
        [
          types.uint(0),
          types.ascii("Excellent blockchain developer")
        ],
        endorser.address
      ),
    ]);
    block.receipts[0].result.expectOk();
  },
});