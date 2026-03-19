import { useAccount, useConnect, useDisconnect } from 'wagmi';

export function ConnectButton() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected && address) {
    return (
      <button
        onClick={() => disconnect()}
        type="button"
        className="bg-surface hover:bg-surface/80 text-white border border-border-muted font-bold py-3 rounded-lg flex items-center justify-center gap-2 transition-all px-6"
      >
        {address.slice(0, 6)}...{address.slice(-4)}
      </button>
    );
  }

  return (
    <button
      onClick={() => {
        const injectedConnector = connectors.find((c) => c.type === 'injected');
        if (injectedConnector) {
          connect({ connector: injectedConnector });
        }
      }}
      disabled={isPending}
      type="button"
      className="w-full bg-primary hover:bg-primary/90 text-white font-bold py-3 rounded-lg flex items-center justify-center gap-2 transition-all px-6 disabled:opacity-50"
    >
      {isPending ? 'Connecting...' : 'Connect Wallet'}
    </button>
  );
}
