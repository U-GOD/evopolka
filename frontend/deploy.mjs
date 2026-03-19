import { createWalletClient, http, createPublicClient } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import fs from 'fs';

async function main() {
  const account = privateKeyToAccount('0xc79f36268d43c6d4cfa5938e74d7dae47bbe56486151010b491853de988c529c');
  const walletClient = createWalletClient({ account, transport: http('https://eth-rpc-testnet.polkadot.io/') });
  const publicClient = createPublicClient({ transport: http('https://eth-rpc-testnet.polkadot.io/') });

  const artifact = JSON.parse(fs.readFileSync('../contract/out/EvoPolkaArena.sol/EvoPolkaArena.json', 'utf8'));

  console.log('Deploying...');
  const hash = await walletClient.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode.object,
    type: 'legacy',
    gasPrice: 2000000000000n, // 2000 Gwei manually set override
  });
  console.log('Tx Hash:', hash);
  
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log('DEPLOYED_ADDRESS:', receipt.contractAddress);
}

main().catch(console.error);
