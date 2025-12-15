(async () => {
  const messageHash = "0x321f9675548f66a4a92bfb625c2a7ae4e8cd41c7da52e47c6e7ae35a7e40299e";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();