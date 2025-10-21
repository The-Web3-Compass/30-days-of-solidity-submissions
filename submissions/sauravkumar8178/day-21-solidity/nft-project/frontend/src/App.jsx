import { useState } from "react";
import { mintNFT } from "./nftService";

export default function App() {
  const [uri, setUri] = useState("");
  const [status, setStatus] = useState("");

  const handleMint = async () => {
    try {
      setStatus("Minting...");
      const txHash = await mintNFT(uri);
      setStatus(`✅ Minted successfully! Tx: ${txHash}`);
    } catch (err) {
      setStatus(`❌ Error: ${err.message}`);
    }
  };

  return (
    <div style={{ padding: "50px", textAlign: "center" }}>
      <h1>🎨 My Collectible NFTs</h1>
      <input
        type="text"
        placeholder="Enter tokenURI (ipfs://...)"
        value={uri}
        onChange={(e) => setUri(e.target.value)}
        style={{ padding: "10px", width: "60%", marginBottom: "10px" }}
      />
      <br />
      <button
        onClick={handleMint}
        style={{ padding: "10px 20px", fontSize: "16px", cursor: "pointer" }}
      >
        Mint NFT
      </button>
      <p>{status}</p>
    </div>
  );
}

