import { createConfig, http } from 'wagmi';
import { injected } from 'wagmi/connectors';
import { defineChain } from 'viem';

export const polkadotHubTestnet = defineChain({
  id: 420420421,
  name: 'Polkadot Hub Testnet',
  nativeCurrency: {
    decimals: 18,
    name: 'PAS',
    symbol: 'PAS',
  },
  rpcUrls: {
    default: {
      http: ['https://eth-rpc-testnet.polkadot.io/'],
    },
    public: {
      http: ['https://eth-rpc-testnet.polkadot.io/'],
    },
  },
  blockExplorers: {
    default: { name: 'Explorer', url: 'https://explorer.polkadot.io' },
  },
  testnet: true,
});

export const config = createConfig({
  chains: [polkadotHubTestnet],
  connectors: [
    injected(), // MetaMask, Talisman, SubWallet — any injected EVM wallet
  ],
  transports: {
    [polkadotHubTestnet.id]: http(),
  },
});
