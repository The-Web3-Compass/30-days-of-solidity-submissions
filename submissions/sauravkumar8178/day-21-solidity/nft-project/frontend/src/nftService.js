import { ethers } from "ethers";
import abi from "./abi.json";

const CONTRACT_ADDRESS = "PASTE_DEPLOYED_ADDRESS_HERE"; // from forge script

export async function mintNFT(tokenURI) {
  if (!window.ethereum) throw new Error("MetaMask not found");

  await window.ethereum.request({ method: "eth_requestAccounts" });

  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);

  const userAddress = await signer.getAddress();
  const tx = await contract.mintTo(userAddress, tokenURI);
  await tx.wait();
  return tx.hash;
}
