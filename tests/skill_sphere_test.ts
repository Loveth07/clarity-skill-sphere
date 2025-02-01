import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test issuer staking mechanism",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    
    // Attempt to stake
    let block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'stake-and-activate-issuer',
        [types.uint(1000000)],
        issuer.address
      ),
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify issuer status
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'get-authorized-issuer-info',
        [types.principal(issuer.address)],
        issuer.address
      ),
    ]);
    
    const issuerInfo = block.receipts[0].result.expectSome();
    assertEquals(issuerInfo.active, true);
    assertEquals(issuerInfo.stakedAmount, types.uint(1000000));
  },
});

Clarinet.test({
  name: "Test certification transfer functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const issuer = accounts.get('wallet_1')!;
    const recipient = accounts.get('wallet_2')!;
    const newRecipient = accounts.get('wallet_3')!;
    
    // Setup issuer
    let block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'stake-and-activate-issuer',
        [types.uint(1000000)],
        issuer.address
      ),
    ]);
    
    // Issue transferable certification
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'issue-certification',
        [
          types.principal(recipient.address),
          types.ascii("Blockchain Developer"),
          types.ascii("Complete blockchain development certification"),
          types.uint(100),
          types.bool(true)
        ],
        issuer.address
      ),
    ]);
    block.receipts[0].result.expectOk();
    
    // Transfer certification
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'transfer-certification',
        [
          types.uint(0),
          types.principal(newRecipient.address)
        ],
        recipient.address
      ),
    ]);
    block.receipts[0].result.expectOk();
    
    // Verify new recipient
    block = chain.mineBlock([
      Tx.contractCall(
        'skill_sphere',
        'get-certification',
        [types.uint(0)],
        newRecipient.address
      ),
    ]);
    const cert = block.receipts[0].result.expectOk().expectSome();
    assertEquals(cert.recipient, newRecipient.address);
  },
});
