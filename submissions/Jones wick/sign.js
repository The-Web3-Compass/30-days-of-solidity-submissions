
(async () => {
  const messageHash = "<0xf29f89ea6275e93e6a474d62df08b7ec259e92a22543f7823661a11773567f95>";
  const accounts = await web3.eth.getAccounts();
  const organizer = accounts[0]; // first account in Remix
  const signature = await web3.eth.sign(messageHash, organizer);
  console.log("Signature:", signature);
})();

