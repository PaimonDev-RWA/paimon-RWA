// scripts/generate-merkle.ts
// run this script with this command: `npx ts-node scripts/generate-merkle.ts`
import { MerkleTree } from 'merkletreejs';
import { ethers } from 'ethers';
import fs from 'fs';

const WHITELIST = [
  '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266', // Hardhat #0
  '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', // Hardhat #1
  '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'  // Hardhat #2
];

function encodeLeaf(address: string): Buffer {
  return Buffer.from(
    ethers.utils
      .keccak256(ethers.utils.solidityPack(['address'], [address]))
      .slice(2),
    'hex'
  );
}

function generateMerkleData() {
  const leaves = WHITELIST.map(encodeLeaf);
  const tree = new MerkleTree(leaves, ethers.utils.keccak256, {
    sortPairs: true // must be the same order with OpenZeppelin 
  });

  const root = tree.getHexRoot();
  const proofs: Record<string, string[]> = {};

  WHITELIST.forEach(address => {
    const leaf = encodeLeaf(address);
    const proof = tree.getHexProof(leaf);
    proofs[address] = proof;
  });

  // save data for test
  fs.writeFileSync(
    './test/merkle-data.json',
    JSON.stringify({ root, proofs }, null, 2)
  );
  console.log('✅ Merkle data generated');
}

generateMerkleData();