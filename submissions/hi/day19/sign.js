(async () => {
  const messageHash = "0xfefb8a2e9f7d41b1839a9b6271c905b1109685df7a5d5c81988976749d51d8ec";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();
