import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
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

export const config = getDefaultConfig({
  appName: 'EvoPolka',
  projectId: 'a52b8618eb0eb2bfbf454a8eef5bb676', // Mock WalletConnect project ID
  chains: [polkadotHubTestnet],
  transports: {
    [polkadotHubTestnet.id]: http(),
  },
});
